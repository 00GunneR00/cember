using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Services;

public class ModerationService(CemberDbContext db, IObjectStorageService storage, PhotoRemover photoRemover) : IModerationService
{
    /// <summary>This many different people reporting a photo hides it from everyone until an admin decides.</summary>
    private const int AutoHideReportCount = 3;
    private const int PresignedUrlHours = 1;

    public async Task ReportPhotoAsync(Guid photoId, CurrentActor actor, ReportPhotoRequest request, CancellationToken ct = default)
    {
        var photo = await LoadAccessiblePhotoAsync(photoId, actor, ct);
        if (IsUploader(photo, actor))
        {
            throw new ValidationAppException("Kendi fotoğrafını şikayet edemezsin; istersen silebilirsin.");
        }

        var alreadyReported = await db.PhotoReports.AnyAsync(r => r.PhotoId == photoId &&
            (actor.IsHost ? r.ReporterUserId == actor.Id : r.ReporterGuestSessionId == actor.Id), ct);
        if (alreadyReported) return;

        var note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim();
        db.PhotoReports.Add(new PhotoReport
        {
            Id = Guid.NewGuid(),
            PhotoId = photoId,
            ReporterUserId = actor.IsHost ? actor.Id : null,
            ReporterGuestSessionId = actor.IsGuest ? actor.Id : null,
            Reason = request.Reason,
            Note = note is { Length: > 500 } ? note[..500] : note,
            CreatedAt = DateTimeOffset.UtcNow,
        });
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            return; // a concurrent duplicate report — the unique index already has this one
        }

        var openReports = await db.PhotoReports.CountAsync(r => r.PhotoId == photoId && r.ResolvedAt == null, ct);
        if (openReports >= AutoHideReportCount && photo.ModerationHiddenAt is null)
        {
            photo.ModerationHiddenAt = DateTimeOffset.UtcNow;
            photo.IsPublished = false;
            await db.SaveChangesAsync(ct);
            await photoRemover.InvalidateRecapsAsync([photo.CircleId], ct);
        }
    }

    public async Task<BlockedUserDto> BlockUploaderAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default)
    {
        var photo = await LoadAccessiblePhotoAsync(photoId, actor, ct);
        if (IsUploader(photo, actor))
        {
            throw new ValidationAppException("Kendini engelleyemezsin.");
        }

        var blocks = db.BlocksBy(actor);
        var existing = await blocks.FirstOrDefaultAsync(b =>
            (photo.UploadedByUserId != null && b.BlockedUserId == photo.UploadedByUserId) ||
            (photo.UploadedByGuestSessionId != null && b.BlockedGuestSessionId == photo.UploadedByGuestSessionId), ct);
        if (existing is not null)
        {
            return ToDto(existing);
        }

        var block = new UserBlock
        {
            Id = Guid.NewGuid(),
            BlockerUserId = actor.IsHost ? actor.Id : null,
            BlockerGuestSessionId = actor.IsGuest ? actor.Id : null,
            BlockedUserId = photo.UploadedByUserId,
            BlockedGuestSessionId = photo.UploadedByGuestSessionId,
            BlockedDisplayName = photo.UploaderDisplayName,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.UserBlocks.Add(block);
        await db.SaveChangesAsync(ct);
        return ToDto(block);
    }

    public async Task<IReadOnlyList<BlockedUserDto>> ListBlocksAsync(CurrentActor actor, CancellationToken ct = default)
    {
        var blocks = await db.BlocksBy(actor)
            .Include(b => b.BlockerGuestSession!).ThenInclude(g => g.Circle)
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync(ct);
        return blocks.Select(ToDto).ToList();
    }

    public async Task UnblockAsync(Guid blockId, CurrentActor actor, CancellationToken ct = default)
    {
        var block = await db.BlocksBy(actor).FirstOrDefaultAsync(b => b.Id == blockId, ct)
            ?? throw new NotFoundAppException("Engel bulunamadı.");
        db.UserBlocks.Remove(block);
        await db.SaveChangesAsync(ct);
    }

    public async Task<IReadOnlyList<ReportedPhotoDto>> ListOpenReportsAsync(CancellationToken ct = default)
    {
        var reports = await db.PhotoReports
            .Where(r => r.ResolvedAt == null)
            .Include(r => r.Photo!).ThenInclude(p => p.Circle)
            .Include(r => r.Photo!).ThenInclude(p => p.UploadedByUser)
            .Include(r => r.Photo!).ThenInclude(p => p.UploadedByGuestSession)
            .ToListAsync(ct);

        return reports
            .GroupBy(r => r.PhotoId)
            .Select(g =>
            {
                var photo = g.First().Photo!;
                return new ReportedPhotoDto(
                    PhotoId: photo.Id,
                    CircleId: photo.CircleId,
                    CircleName: photo.Circle?.Name ?? "",
                    UploaderDisplayName: photo.UploaderDisplayName,
                    ThumbnailUrl: storage.GetPresignedUrl(photo.ThumbnailKey, TimeSpan.FromHours(PresignedUrlHours)),
                    ReportCount: g.Count(),
                    Reasons: g.Select(r => r.Reason).Distinct().ToList(),
                    Notes: g.Select(r => r.Note).OfType<string>().ToList(),
                    IsHidden: photo.ModerationHiddenAt is not null,
                    FirstReportedAt: g.Min(r => r.CreatedAt));
            })
            .OrderByDescending(r => r.ReportCount)
            .ThenBy(r => r.FirstReportedAt)
            .ToList();
    }

    public async Task ResolveReportsAsync(Guid photoId, bool removePhoto, CancellationToken ct = default)
    {
        var photo = await db.Photos.FirstOrDefaultAsync(p => p.Id == photoId, ct)
            ?? throw new NotFoundAppException("Fotoğraf bulunamadı.");

        if (removePhoto)
        {
            await photoRemover.RemoveAsync([photo], ct); // its reports cascade away with it
            return;
        }

        var now = DateTimeOffset.UtcNow;
        await db.PhotoReports
            .Where(r => r.PhotoId == photoId && r.ResolvedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(r => r.ResolvedAt, now), ct);

        if (photo.ModerationHiddenAt is not null)
        {
            photo.ModerationHiddenAt = null;
            photo.IsPublished = true;
            await db.SaveChangesAsync(ct);
        }
    }

    /// <summary>Loads a photo the actor may currently see — it must be in their circle and not still in the darkroom.</summary>
    private async Task<Photo> LoadAccessiblePhotoAsync(Guid photoId, CurrentActor actor, CancellationToken ct)
    {
        var photo = await db.Photos
            .Include(p => p.Circle)
            .Include(p => p.UploadedByUser)
            .Include(p => p.UploadedByGuestSession)
            .FirstOrDefaultAsync(p => p.Id == photoId, ct)
            ?? throw new NotFoundAppException("Fotoğraf bulunamadı.");
        CircleService.EnsureActorCanAccess(photo.Circle!, actor);
        if (photo.Circle!.IsDeveloping(DateTimeOffset.UtcNow))
        {
            throw new ForbiddenAppException("Fotoğraflar hâlâ banyoda.");
        }
        return photo;
    }

    private static bool IsUploader(Photo photo, CurrentActor actor) =>
        actor.IsHost ? photo.UploadedByUserId == actor.Id : photo.UploadedByGuestSessionId == actor.Id;

    private static BlockedUserDto ToDto(UserBlock block) =>
        new(block.Id, block.BlockedDisplayName, block.CreatedAt, block.BlockerGuestSession?.Circle?.Name);
}

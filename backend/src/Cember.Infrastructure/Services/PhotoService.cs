using System.IO.Compression;
using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Cember.Infrastructure.Services;

public class PhotoService(
    CemberDbContext db,
    IObjectStorageService storage,
    IImageProcessingService imaging,
    INotificationService notifications,
    PhotoRemover photoRemover,
    IConfiguration configuration) : IPhotoService
{
    private const int PresignedUrlHours = 1;

    public async Task<UploadPhotoResultDto> UploadAsync(Guid circleId, CurrentActor actor, IReadOnlyList<UploadedFile> files, PhotoSource source, bool commercialUseConsent = false, CancellationToken ct = default)
    {
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        CircleService.EnsureActorCanAccess(circle, actor);
        EnsureSourceAllowed(circle, source);

        var created = new List<PhotoDto>();
        var errors = new List<string>();

        foreach (var file in files)
        {
            try
            {
                if (!ImageContentTypes.Allowed.Contains(file.ContentType))
                {
                    errors.Add($"{file.FileName}: desteklenmeyen dosya türü ({file.ContentType}).");
                    continue;
                }

                var processed = await imaging.ProcessAsync(file.Content, ct);
                var photoId = Guid.NewGuid();
                var ext = ImageContentTypes.ExtensionFor(file.ContentType);

                var originalKey = $"circles/{circleId}/original/{photoId}{ext}";
                var thumbnailKey = $"circles/{circleId}/thumb/{photoId}.jpg";

                await storage.PutObjectAsync(originalKey, new MemoryStream(processed.Original), file.ContentType, ct);
                await storage.PutObjectAsync(thumbnailKey, new MemoryStream(processed.Thumbnail), processed.ThumbnailContentType, ct);

                var photo = new Photo
                {
                    Id = photoId,
                    CircleId = circleId,
                    UploadedByUserId = actor.IsHost ? actor.Id : null,
                    UploadedByGuestSessionId = actor.IsGuest ? actor.Id : null,
                    OriginalKey = originalKey,
                    ThumbnailKey = thumbnailKey,
                    Width = processed.Width,
                    Height = processed.Height,
                    FileSizeBytes = processed.Original.LongLength,
                    ContentType = file.ContentType,
                    IsPublished = actor.IsHost || circle.AutoPublish,
                    CreatedAt = DateTimeOffset.UtcNow,
                    Source = source,
                    CommercialUseConsent = commercialUseConsent,
                };

                db.Photos.Add(photo);
                await db.SaveChangesAsync(ct);

                created.Add(new PhotoDto(
                    Id: photo.Id,
                    UploaderDisplayName: actor.DisplayName,
                    ThumbnailUrl: storage.GetPresignedUrl(thumbnailKey, TimeSpan.FromHours(PresignedUrlHours)),
                    ReactionCount: 0,
                    ViewerHasReacted: false,
                    CommentCount: 0,
                    CreatedAt: photo.CreatedAt,
                    Source: photo.Source,
                    ViewerCanDelete: true
                ));
            }
            catch (Exception ex)
            {
                errors.Add($"{file.FileName}: {ex.Message}");
            }
        }

        if (created.Count > 0 && actor.Id != circle.OwnerUserId)
        {
            await notifications.NotifyAsync(
                circle.OwnerUserId,
                NotificationType.PhotoAdded,
                circleId,
                actor.DisplayName,
                photoId: created[0].Id,
                preview: created.Count == 1 ? null : $"{created.Count} fotoğraf",
                ct: ct);
        }

        return new UploadPhotoResultDto(created, errors);
    }

    public async Task<PhotoPageDto> GetPhotosAsync(Guid circleId, CurrentActor actor, string? cursor, int pageSize, PhotoSource? source = null, CancellationToken ct = default)
    {
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        CircleService.EnsureActorCanAccess(circle, actor);

        if (circle.IsDeveloping(DateTimeOffset.UtcNow))
        {
            // Banyo: nobody — not even the owner — sees a photo before the reveal.
            return new PhotoPageDto([], null);
        }

        var isOwner = actor.IsHost && circle.OwnerUserId == actor.Id;

        var query = db.Photos.Where(p => p.CircleId == circleId).VisibleTo(db, actor);
        // The owner also sees photos still awaiting their approval — but never ones hidden by moderation.
        query = isOwner
            ? query.Where(p => p.IsPublished || p.ModerationHiddenAt == null)
            : query.Where(p => p.IsPublished);
        if (source is { } sourceFilter)
        {
            query = query.Where(p => p.Source == sourceFilter);
        }
        if (cursor is not null && DateTimeOffset.TryParse(cursor, out var before))
        {
            query = query.Where(p => p.CreatedAt < before);
        }

        var rows = await query
            .OrderByDescending(p => p.CreatedAt)
            .Take(pageSize + 1)
            .Select(p => new
            {
                p.Id,
                p.CreatedAt,
                p.ThumbnailKey,
                UploaderName = p.UploadedByUser != null ? p.UploadedByUser.DisplayName : (p.UploadedByGuestSession != null ? p.UploadedByGuestSession.DisplayName : "Bilinmeyen"),
                ReactionCount = p.Reactions.Count,
                CommentCount = p.Comments.Count,
                ViewerReacted = p.Reactions.Any(r =>
                    (actor.IsHost && r.UserId == actor.Id) ||
                    (actor.IsGuest && r.GuestSessionId == actor.Id)),
                ViewerIsUploader = (actor.IsHost && p.UploadedByUserId == actor.Id) || (actor.IsGuest && p.UploadedByGuestSessionId == actor.Id),
                p.Source,
            })
            .ToListAsync(ct);

        var hasMore = rows.Count > pageSize;
        var page = rows.Take(pageSize).ToList();

        var dtos = page.Select(p => new PhotoDto(
            Id: p.Id,
            UploaderDisplayName: p.UploaderName,
            ThumbnailUrl: storage.GetPresignedUrl(p.ThumbnailKey, TimeSpan.FromHours(PresignedUrlHours)),
            ReactionCount: p.ReactionCount,
            ViewerHasReacted: p.ViewerReacted,
            CommentCount: p.CommentCount,
            CreatedAt: p.CreatedAt,
            Source: p.Source,
            ViewerCanDelete: isOwner || p.ViewerIsUploader
        )).ToList();

        var nextCursor = hasMore ? page[^1].CreatedAt.ToString("o") : null;
        return new PhotoPageDto(dtos, nextCursor);
    }

    public async Task<ReactionResultDto> ToggleReactionAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default)
    {
        var circle = await GetVisiblePhotoCircleAsync(photoId, actor, ct);

        var existing = await db.PhotoReactions.FirstOrDefaultAsync(r =>
            r.PhotoId == photoId &&
            (actor.IsHost ? r.UserId == actor.Id : r.GuestSessionId == actor.Id), ct);

        bool reacted;
        if (existing is not null)
        {
            db.PhotoReactions.Remove(existing);
            reacted = false;
        }
        else
        {
            db.PhotoReactions.Add(new PhotoReaction
            {
                Id = Guid.NewGuid(),
                PhotoId = photoId,
                UserId = actor.IsHost ? actor.Id : null,
                GuestSessionId = actor.IsGuest ? actor.Id : null,
                CreatedAt = DateTimeOffset.UtcNow,
            });
            reacted = true;
        }

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            reacted = true;
        }

        var count = await db.PhotoReactions.CountAsync(r => r.PhotoId == photoId, ct);

        if (reacted && actor.Id != circle.OwnerUserId)
        {
            await notifications.NotifyAsync(circle.OwnerUserId, NotificationType.ReactionAdded, circle.Id, actor.DisplayName, photoId: photoId, ct: ct);
        }

        return new ReactionResultDto(reacted, count);
    }

    public async Task<CommentDto> AddCommentAsync(Guid photoId, CurrentActor actor, AddCommentRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Body))
        {
            throw new ValidationAppException("body gerekli.");
        }

        var circle = await GetVisiblePhotoCircleAsync(photoId, actor, ct);

        var comment = new Comment
        {
            Id = Guid.NewGuid(),
            PhotoId = photoId,
            UserId = actor.IsHost ? actor.Id : null,
            GuestSessionId = actor.IsGuest ? actor.Id : null,
            AuthorDisplayName = actor.DisplayName,
            Body = request.Body.Trim(),
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.Comments.Add(comment);
        await db.SaveChangesAsync(ct);

        if (actor.Id != circle.OwnerUserId)
        {
            await notifications.NotifyAsync(
                circle.OwnerUserId,
                NotificationType.CommentAdded,
                circle.Id,
                actor.DisplayName,
                photoId: photoId,
                preview: comment.Body.Length > 120 ? comment.Body[..120] : comment.Body,
                ct: ct);
        }

        return new CommentDto(comment.Id, comment.AuthorDisplayName, comment.Body, comment.CreatedAt);
    }

    public async Task DeletePhotoAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default)
    {
        var photo = await db.Photos.Include(p => p.Circle).FirstOrDefaultAsync(p => p.Id == photoId, ct)
            ?? throw new NotFoundAppException("Fotoğraf bulunamadı.");
        var circle = photo.Circle!;
        CircleService.EnsureActorCanAccess(circle, actor);

        var isOwner = actor.IsHost && circle.OwnerUserId == actor.Id;
        var isUploader = actor.IsHost ? photo.UploadedByUserId == actor.Id : photo.UploadedByGuestSessionId == actor.Id;
        if (!isOwner && !isUploader)
        {
            throw new ForbiddenAppException("Bu fotoğrafı yalnızca yükleyen kişi ya da çemberin sahibi silebilir.");
        }

        await photoRemover.RemoveAsync([photo], ct);
    }

    public async Task<CommentPageDto> GetCommentsAsync(Guid photoId, CurrentActor actor, string? cursor, int pageSize, CancellationToken ct = default)
    {
        await GetVisiblePhotoCircleAsync(photoId, actor, ct);

        var query = db.Comments.Where(c => c.PhotoId == photoId).VisibleTo(db, actor);
        if (cursor is not null && DateTimeOffset.TryParse(cursor, out var before))
        {
            query = query.Where(c => c.CreatedAt < before);
        }

        var rows = await query.OrderByDescending(c => c.CreatedAt).Take(pageSize + 1).ToListAsync(ct);
        var hasMore = rows.Count > pageSize;
        var page = rows.Take(pageSize).ToList();

        var dtos = page.Select(c => new CommentDto(c.Id, c.AuthorDisplayName, c.Body, c.CreatedAt)).ToList();
        var nextCursor = hasMore ? page[^1].CreatedAt.ToString("o") : null;
        return new CommentPageDto(dtos, nextCursor);
    }

    public async Task ExportZipAsync(Guid circleId, CurrentActor actor, Stream destination, CancellationToken ct = default)
    {
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        CircleService.EnsureActorCanAccess(circle, actor);
        EnsureNotDeveloping(circle);

        if (actor.IsGuest && !circle.AllowGuestDownloads)
        {
            throw new ForbiddenAppException("Bu çemberde misafir indirmeleri kapalı.");
        }

        var exportLimit = configuration.GetValue<int?>("Export:MaxPhotoCount") ?? 2000;
        var photos = await db.Photos
            .Where(p => p.CircleId == circleId && (p.IsPublished || (actor.IsHost && circle.OwnerUserId == actor.Id && p.ModerationHiddenAt == null)))
            .VisibleTo(db, actor)
            .OrderBy(p => p.CreatedAt)
            .Take(exportLimit)
            .ToListAsync(ct);

        using var archive = new ZipArchive(destination, ZipArchiveMode.Create, leaveOpen: true);
        var usedNames = new HashSet<string>();

        foreach (var photo in photos)
        {
            var name = UniqueEntryName(photo, usedNames);
            var entry = archive.CreateEntry(name, CompressionLevel.NoCompression);
            await using var entryStream = entry.Open();
            await using var source = await storage.OpenReadAsync(photo.OriginalKey, ct);
            await source.CopyToAsync(entryStream, ct);
        }
    }

    /// <summary>
    /// Loads the circle a photo belongs to, checking the actor may see it — and that it isn't
    /// still hidden in a developing (Banyo) circle, where no one may view or interact with photos yet.
    /// </summary>
    private async Task<Circle> GetVisiblePhotoCircleAsync(Guid photoId, CurrentActor actor, CancellationToken ct)
    {
        var circleId = await db.Photos.Where(p => p.Id == photoId).Select(p => (Guid?)p.CircleId).FirstOrDefaultAsync(ct)
            ?? throw new NotFoundAppException("Fotoğraf bulunamadı.");
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        CircleService.EnsureActorCanAccess(circle, actor);
        EnsureNotDeveloping(circle);
        return circle;
    }

    private static void EnsureNotDeveloping(Circle circle)
    {
        if (circle.IsDeveloping(DateTimeOffset.UtcNow))
        {
            throw new ForbiddenAppException("Fotoğraflar hâlâ banyoda.");
        }
    }

    private static void EnsureSourceAllowed(Circle circle, PhotoSource source)
    {
        var allowed = circle.UploadMode switch
        {
            PhotoUploadMode.QuickCaptureOnly => source == PhotoSource.QuickCapture,
            PhotoUploadMode.GalleryOnly => source == PhotoSource.Gallery,
            _ => true,
        };
        if (!allowed)
        {
            throw new ForbiddenAppException("Bu çember bu yükleme yöntemini kabul etmiyor.");
        }
    }

    private static string UniqueEntryName(Photo photo, HashSet<string> used)
    {
        var ext = ImageContentTypes.ExtensionFor(photo.ContentType);
        var baseName = $"{photo.CreatedAt:yyyyMMdd_HHmmss}_{photo.Id.ToString()[..8]}{ext}";
        var name = baseName;
        var i = 1;
        while (!used.Add(name))
        {
            name = $"{Path.GetFileNameWithoutExtension(baseName)}_{i++}{ext}";
        }
        return name;
    }
}

using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Services;

public class ProfileService(CemberDbContext db, IObjectStorageService storage, PhotoRemover photoRemover) : IProfileService
{
    private const long StorageTotalBytes = 25L * 1024 * 1024 * 1024;
    private const int PresignedUrlHours = 1;

    public async Task<ProfileDto> GetProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new NotFoundAppException("Kullanıcı bulunamadı.");

        var circleIds = await db.Circles.Where(c => c.OwnerUserId == userId).Select(c => c.Id).ToListAsync(ct);
        var circleCount = circleIds.Count;
        var eventCount = await db.Circles.CountAsync(c => c.OwnerUserId == userId && !c.IsArchived, ct);
        var photoCount = await db.Photos.CountAsync(p => circleIds.Contains(p.CircleId), ct);
        var storageUsed = await db.Photos.Where(p => circleIds.Contains(p.CircleId)).SumAsync(p => (long?)p.FileSizeBytes, ct) ?? 0L;
        var googleLink = await db.GoogleLinks.FirstOrDefaultAsync(g => g.UserId == userId, ct);

        return new ProfileDto(
            DisplayName: user.DisplayName,
            CircleCount: circleCount,
            PhotoCount: photoCount,
            EventCount: eventCount,
            StorageUsedBytes: storageUsed,
            StorageTotalBytes: StorageTotalBytes,
            OnlyUploadOnWifi: user.OnlyUploadOnWifi,
            NotifyOnPhotoAdded: user.NotifyOnPhotoAdded,
            NotifyOnComment: user.NotifyOnComment,
            NotifyOnReaction: user.NotifyOnReaction,
            NotifyOnGuestJoined: user.NotifyOnGuestJoined,
            LinkedGoogleEmail: googleLink?.Email
        );
    }

    public async Task UpdateSettingsAsync(Guid userId, UpdateSettingsRequest request, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new NotFoundAppException("Kullanıcı bulunamadı.");

        if (request.OnlyUploadOnWifi is { } wifi)
        {
            user.OnlyUploadOnWifi = wifi;
        }
        if (request.NotifyOnPhotoAdded is { } photoAdded)
        {
            user.NotifyOnPhotoAdded = photoAdded;
        }
        if (request.NotifyOnComment is { } comment)
        {
            user.NotifyOnComment = comment;
        }
        if (request.NotifyOnReaction is { } reaction)
        {
            user.NotifyOnReaction = reaction;
        }
        if (request.NotifyOnGuestJoined is { } guestJoined)
        {
            user.NotifyOnGuestJoined = guestJoined;
        }
        if (request.DisplayName is { } displayName)
        {
            var trimmed = displayName.Trim();
            if (trimmed.Length is 0 or > 40)
            {
                throw new ValidationAppException("Ad 1-40 karakter olmalı.");
            }
            user.DisplayName = trimmed;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<PhotoPageDto> GetFavoritesAsync(Guid userId, string? cursor, int pageSize, CancellationToken ct = default)
    {
        var query = db.PhotoReactions
            .Where(r => r.UserId == userId && r.Photo!.IsPublished)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => r.Photo!);

        if (cursor is not null && DateTimeOffset.TryParse(cursor, out var before))
        {
            query = db.PhotoReactions
                .Where(r => r.UserId == userId && r.Photo!.IsPublished && r.CreatedAt < before)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => r.Photo!);
        }

        var photos = await query.Take(pageSize + 1)
            .Select(p => new
            {
                p.Id,
                p.CreatedAt,
                p.ThumbnailKey,
                UploaderName = p.UploadedByUser != null ? p.UploadedByUser.DisplayName : (p.UploadedByGuestSession != null ? p.UploadedByGuestSession.DisplayName : "Bilinmeyen"),
                ReactionCount = p.Reactions.Count,
                CommentCount = p.Comments.Count,
                p.Source,
            })
            .ToListAsync(ct);

        var hasMore = photos.Count > pageSize;
        var page = photos.Take(pageSize).ToList();

        var dtos = page.Select(p => new PhotoDto(
            Id: p.Id,
            UploaderDisplayName: p.UploaderName,
            ThumbnailUrl: storage.GetPresignedUrl(p.ThumbnailKey, TimeSpan.FromHours(PresignedUrlHours)),
            ReactionCount: p.ReactionCount,
            ViewerHasReacted: true,
            CommentCount: p.CommentCount,
            CreatedAt: p.CreatedAt,
            Source: p.Source
        )).ToList();

        var nextCursor = hasMore ? page[^1].CreatedAt.ToString("o") : null;
        return new PhotoPageDto(dtos, nextCursor);
    }

    public async Task DeleteAccountAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct)
            ?? throw new NotFoundAppException("Kullanıcı bulunamadı.");

        // Photos posted in other people's circles go through the remover, so those circles' recap videos
        // are re-rendered without them.
        var photosElsewhere = await db.Photos
            .Where(p => p.UploadedByUserId == userId && p.Circle!.OwnerUserId != userId)
            .ToListAsync(ct);
        await photoRemover.RemoveAsync(photosElsewhere, ct);

        // Everything in the user's own circles is deleted with them. The database cascades the rows;
        // the stored files have to be collected first and deleted afterwards.
        var ownedCircles = await db.Circles.Where(c => c.OwnerUserId == userId)
            .Select(c => new { c.Id, c.CoverPhotoKey, c.RecapKey })
            .ToListAsync(ct);
        var ownedCircleIds = ownedCircles.Select(c => c.Id).ToList();
        var photoKeys = await db.Photos.Where(p => ownedCircleIds.Contains(p.CircleId))
            .Select(p => new { p.OriginalKey, p.ThumbnailKey })
            .ToListAsync(ct);

        var keys = photoKeys.SelectMany(k => new[] { k.OriginalKey, k.ThumbnailKey })
            .Concat(ownedCircles.SelectMany(c => new[] { c.CoverPhotoKey, c.RecapKey }).OfType<string>())
            .ToList();

        db.Users.Remove(user);
        await db.SaveChangesAsync(ct);

        await photoRemover.DeleteObjectsAsync(keys, ct);
    }

    public async Task DeleteGuestSessionAsync(Guid guestSessionId, CancellationToken ct = default)
    {
        var session = await db.GuestSessions.FirstOrDefaultAsync(g => g.Id == guestSessionId, ct)
            ?? throw new NotFoundAppException("Oturum bulunamadı.");

        var photos = await db.Photos.Where(p => p.UploadedByGuestSessionId == guestSessionId).ToListAsync(ct);
        await photoRemover.RemoveAsync(photos, ct);

        db.GuestSessions.Remove(session);
        await db.SaveChangesAsync(ct);
    }
}

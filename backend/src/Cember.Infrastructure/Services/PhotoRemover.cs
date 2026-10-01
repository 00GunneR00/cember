using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Cember.Infrastructure.Services;

/// <summary>
/// The one way photos get deleted — by their uploader, the circle owner, a moderator or account deletion —
/// so storage cleanup and recap invalidation can't be forgotten on any of those paths.
/// </summary>
public class PhotoRemover(CemberDbContext db, IObjectStorageService storage, ILogger<PhotoRemover> logger)
{
    public async Task RemoveAsync(IReadOnlyCollection<Photo> photos, CancellationToken ct)
    {
        if (photos.Count == 0) return;

        var keys = photos.SelectMany(p => new[] { p.OriginalKey, p.ThumbnailKey }).ToList();
        var circleIds = photos.Select(p => p.CircleId).Distinct().ToList();

        db.Photos.RemoveRange(photos); // reactions, comments and reports cascade
        await db.SaveChangesAsync(ct);

        await InvalidateRecapsAsync(circleIds, ct);
        await DeleteObjectsAsync(keys, ct);
    }

    /// <summary>
    /// A recap video may show photos that are now gone. Re-render it from what's left, or drop it when too
    /// few photos remain — a removed photo must not live on inside a shareable video.
    /// </summary>
    public async Task InvalidateRecapsAsync(IReadOnlyCollection<Guid> circleIds, CancellationToken ct)
    {
        var circles = await db.Circles
            .Where(c => circleIds.Contains(c.Id) && c.RecapStatus != RecapStatus.None)
            .ToListAsync(ct);
        if (circles.Count == 0) return;

        var staleKeys = new List<string>();
        foreach (var circle in circles)
        {
            var remaining = await db.Photos.CountAsync(p => p.CircleId == circle.Id && p.IsPublished, ct);
            if (remaining >= RecapLimits.MinPhotoCount)
            {
                // The worker replaces (and deletes) the old video when the new one is ready.
                circle.RecapStatus = RecapStatus.Pending;
                circle.RecapError = null;
            }
            else
            {
                if (circle.RecapKey is not null) staleKeys.Add(circle.RecapKey);
                circle.RecapKey = null;
                circle.RecapStatus = RecapStatus.None;
                circle.RecapError = null;
            }
        }
        await db.SaveChangesAsync(ct);
        await DeleteObjectsAsync(staleKeys, ct);
    }

    public async Task DeleteObjectsAsync(IEnumerable<string> keys, CancellationToken ct)
    {
        foreach (var key in keys)
        {
            try
            {
                await storage.DeleteObjectAsync(key, ct);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Depolama nesnesi silinemedi: {Key}", key);
            }
        }
    }
}

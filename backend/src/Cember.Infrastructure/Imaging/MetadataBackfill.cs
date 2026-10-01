using Cember.Application.Interfaces;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SixLabors.ImageSharp;

namespace Cember.Infrastructure.Imaging;

public record MetadataBackfillResult(int Checked, int Cleaned, int Failed);

/// <summary>
/// One-off cleanup for files stored before uploads started stripping metadata: rewrites every photo
/// original (and its thumbnail) and every circle cover that still carries EXIF/GPS, IPTC or XMP.
/// Safe to run repeatedly — files that are already clean are left untouched.
/// Run with: <c>dotnet run --project backend/src/Cember.Api -- strip-exif</c>
/// </summary>
public class MetadataBackfill(
    CemberDbContext db,
    IObjectStorageService storage,
    IImageProcessingService imaging,
    ILogger<MetadataBackfill> logger)
{
    private const int BatchSize = 100;

    public async Task<MetadataBackfillResult> RunAsync(CancellationToken ct)
    {
        int checkedCount = 0, cleaned = 0, failed = 0;

        Guid? lastId = null;
        while (true)
        {
            var batch = await db.Photos
                .Where(p => lastId == null || p.Id.CompareTo(lastId.Value) > 0)
                .OrderBy(p => p.Id)
                .Take(BatchSize)
                .ToListAsync(ct);
            if (batch.Count == 0) break;
            lastId = batch[^1].Id;

            foreach (var photo in batch)
            {
                checkedCount++;
                try
                {
                    var original = await ReadAllAsync(photo.OriginalKey, ct);
                    if (!HasMetadata(original)) continue;

                    var processed = await imaging.ProcessAsync(new MemoryStream(original), ct);
                    await storage.PutObjectAsync(photo.OriginalKey, new MemoryStream(processed.Original), photo.ContentType, ct);
                    await storage.PutObjectAsync(photo.ThumbnailKey, new MemoryStream(processed.Thumbnail), processed.ThumbnailContentType, ct);
                    photo.FileSizeBytes = processed.Original.LongLength;
                    photo.Width = processed.Width;
                    photo.Height = processed.Height;
                    cleaned++;
                }
                catch (Exception ex) when (!ct.IsCancellationRequested)
                {
                    failed++;
                    logger.LogWarning(ex, "Fotoğraf temizlenemedi: {PhotoId}", photo.Id);
                }
            }
            await db.SaveChangesAsync(ct);
        }

        var covers = await db.Circles.Where(c => c.CoverPhotoKey != null).Select(c => c.CoverPhotoKey!).ToListAsync(ct);
        foreach (var key in covers)
        {
            checkedCount++;
            try
            {
                var original = await ReadAllAsync(key, ct);
                if (!HasMetadata(original)) continue;

                var processed = await imaging.ProcessAsync(new MemoryStream(original), ct);
                await storage.PutObjectAsync(key, new MemoryStream(processed.Original), ContentTypeFor(key), ct);
                cleaned++;
            }
            catch (Exception ex) when (!ct.IsCancellationRequested)
            {
                failed++;
                logger.LogWarning(ex, "Kapak fotoğrafı temizlenemedi: {Key}", key);
            }
        }

        return new MetadataBackfillResult(checkedCount, cleaned, failed);
    }

    public static bool HasMetadata(byte[] image)
    {
        var info = Image.Identify(image);
        return info.Metadata.ExifProfile is not null || info.Metadata.IptcProfile is not null || info.Metadata.XmpProfile is not null;
    }

    private async Task<byte[]> ReadAllAsync(string key, CancellationToken ct)
    {
        await using var stream = await storage.OpenReadAsync(key, ct);
        using var buffer = new MemoryStream();
        await stream.CopyToAsync(buffer, ct);
        return buffer.ToArray();
    }

    private static string ContentTypeFor(string key) => Path.GetExtension(key).ToLowerInvariant() switch
    {
        ".png" => "image/png",
        ".webp" => "image/webp",
        _ => "image/jpeg",
    };
}

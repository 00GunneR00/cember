using Cember.Application.Interfaces;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace Cember.Infrastructure.Imaging;

public class ImageSharpProcessingService : IImageProcessingService
{
    private const int ThumbnailMaxDimension = 480;

    public async Task<ProcessedImage> ProcessAsync(Stream source, CancellationToken ct = default)
    {
        using var originalMemory = new MemoryStream();
        await source.CopyToAsync(originalMemory, ct);
        originalMemory.Position = 0;

        using var image = await Image.LoadAsync(originalMemory, ct);
        var format = image.Metadata.DecodedImageFormat ?? JpegFormat.Instance;

        // Bake the EXIF rotation into the pixels, then drop all embedded metadata: phones write the GPS
        // location (and device details) into every photo, and everyone in a circle can download originals.
        image.Mutate(x => x.AutoOrient());
        StripMetadata(image);

        var width = image.Width;
        var height = image.Height;

        // The original is re-encoded rather than stored byte-for-byte — that's the only way to be sure
        // no metadata survives. Same format as uploaded, so the stored content type stays correct.
        using var cleanOriginal = new MemoryStream();
        await image.SaveAsync(cleanOriginal, EncoderFor(image, format), ct);

        using var thumbnail = image.Clone(x => x.Resize(new ResizeOptions
        {
            Mode = ResizeMode.Max,
            Size = new Size(ThumbnailMaxDimension, ThumbnailMaxDimension),
        }));

        using var thumbnailStream = new MemoryStream();
        await thumbnail.SaveAsync(thumbnailStream, new JpegEncoder { Quality = 80 }, ct);

        return new ProcessedImage(
            Original: cleanOriginal.ToArray(),
            Thumbnail: thumbnailStream.ToArray(),
            Width: width,
            Height: height,
            ThumbnailContentType: "image/jpeg"
        );
    }

    /// <summary>Removes EXIF (incl. GPS), IPTC and XMP. The ICC colour profile is kept so colours don't shift.</summary>
    private static void StripMetadata(Image image)
    {
        image.Metadata.ExifProfile = null;
        image.Metadata.IptcProfile = null;
        image.Metadata.XmpProfile = null;
        foreach (var frame in image.Frames)
        {
            frame.Metadata.ExifProfile = null;
            frame.Metadata.IptcProfile = null;
            frame.Metadata.XmpProfile = null;
        }
    }

    private static IImageEncoder EncoderFor(Image image, IImageFormat format) =>
        format is JpegFormat
            ? new JpegEncoder { Quality = 92 }
            : image.Configuration.ImageFormatsManager.GetEncoder(format);
}

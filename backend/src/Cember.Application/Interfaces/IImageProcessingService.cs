namespace Cember.Application.Interfaces;

public record ProcessedImage(byte[] Original, byte[] Thumbnail, int Width, int Height, string ThumbnailContentType);

public interface IImageProcessingService
{
    Task<ProcessedImage> ProcessAsync(Stream source, CancellationToken ct = default);
}

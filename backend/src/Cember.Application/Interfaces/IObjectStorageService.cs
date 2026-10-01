namespace Cember.Application.Interfaces;

public interface IObjectStorageService
{
    Task<bool> BucketIsReachableAsync(CancellationToken ct = default);

    Task PutObjectAsync(string key, Stream content, string contentType, CancellationToken ct = default);

    Task<Stream> OpenReadAsync(string key, CancellationToken ct = default);

    string GetPresignedUrl(string key, TimeSpan expiry);

    Task DeleteObjectAsync(string key, CancellationToken ct = default);
}

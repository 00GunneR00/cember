using Amazon.S3;
using Amazon.S3.Model;
using Cember.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace Cember.Infrastructure.Storage;

public class S3ObjectStorageService : IObjectStorageService
{
    private readonly IAmazonS3 _client;
    private readonly S3Options _options;

    public S3ObjectStorageService(IAmazonS3 client, IOptions<S3Options> options)
    {
        _client = client;
        _options = options.Value;
    }

    public async Task<bool> BucketIsReachableAsync(CancellationToken ct = default)
    {
        try
        {
            await _client.GetBucketLocationAsync(_options.Bucket, ct);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task PutObjectAsync(string key, Stream content, string contentType, CancellationToken ct = default)
    {
        var request = new PutObjectRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            InputStream = content,
            ContentType = contentType,
            AutoCloseStream = false,
        };
        await _client.PutObjectAsync(request, ct);
    }

    public async Task<Stream> OpenReadAsync(string key, CancellationToken ct = default)
    {
        var response = await _client.GetObjectAsync(_options.Bucket, key, ct);
        return response.ResponseStream;
    }

    public string GetPresignedUrl(string key, TimeSpan expiry)
    {
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            Verb = HttpVerb.GET,
            Expires = DateTime.UtcNow.Add(expiry),
            Protocol = _options.Endpoint.StartsWith("http://") ? Protocol.HTTP : Protocol.HTTPS,
        };
        return _client.GetPreSignedURL(request);
    }

    public async Task DeleteObjectAsync(string key, CancellationToken ct = default)
    {
        await _client.DeleteObjectAsync(_options.Bucket, key, ct);
    }
}

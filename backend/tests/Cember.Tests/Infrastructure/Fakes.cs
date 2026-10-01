using System.Collections.Concurrent;
using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Infrastructure.Push;

namespace Cember.Tests.Infrastructure;

/// <summary>Object storage in a dictionary — lets tests assert which files exist after deletions.</summary>
public sealed class InMemoryStorage : IObjectStorageService
{
    public ConcurrentDictionary<string, (byte[] Bytes, string ContentType)> Objects { get; } = new();

    public Task<bool> BucketIsReachableAsync(CancellationToken ct = default) => Task.FromResult(true);

    public async Task PutObjectAsync(string key, Stream content, string contentType, CancellationToken ct = default)
    {
        using var buffer = new MemoryStream();
        await content.CopyToAsync(buffer, ct);
        Objects[key] = (buffer.ToArray(), contentType);
    }

    public Task<Stream> OpenReadAsync(string key, CancellationToken ct = default) =>
        Objects.TryGetValue(key, out var value)
            ? Task.FromResult<Stream>(new MemoryStream(value.Bytes))
            : throw new FileNotFoundException(key);

    public string GetPresignedUrl(string key, TimeSpan expiry) => $"https://storage.test/{key}";

    public Task DeleteObjectAsync(string key, CancellationToken ct = default)
    {
        Objects.TryRemove(key, out _);
        return Task.CompletedTask;
    }
}

/// <summary>Records queued pushes instead of sending them.</summary>
public sealed class RecordingPushService : IPushService
{
    public List<(Guid UserId, PushContent Content)> ToUsers { get; } = [];
    public List<(Guid CircleId, PushContent Content, bool IncludeOwner)> ToCircles { get; } = [];

    public Task RegisterDeviceAsync(CurrentActor actor, string token, string? platform, CancellationToken ct = default) => Task.CompletedTask;

    public Task UnregisterDeviceAsync(CurrentActor actor, string token, CancellationToken ct = default) => Task.CompletedTask;

    public void QueueToUser(Guid userId, PushContent content) => ToUsers.Add((userId, content));

    public void QueueToCircle(Guid circleId, PushContent content, bool includeOwner = true) => ToCircles.Add((circleId, content, includeOwner));
}

/// <summary>A push transport that records deliveries and treats chosen tokens as uninstalled apps.</summary>
public sealed class RecordingPushTransport : IPushTransport
{
    public HashSet<string> DeadTokens { get; } = [];
    public List<(string Token, PushContent Content)> Sent { get; } = [];

    public bool IsEnabled => true;

    public Task<PushSendResult> SendAsync(string deviceToken, PushContent content, CancellationToken ct)
    {
        if (DeadTokens.Contains(deviceToken)) return Task.FromResult(PushSendResult.InvalidToken);
        Sent.Add((deviceToken, content));
        return Task.FromResult(PushSendResult.Sent);
    }
}

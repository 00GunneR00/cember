using System.Threading.Channels;
using Cember.Application.Interfaces;

namespace Cember.Infrastructure.Push;

/// <summary>Who a queued push is for: one host's devices, or everyone in a circle.</summary>
public abstract record PushTarget;

public sealed record UserPushTarget(Guid UserId) : PushTarget;

public sealed record CirclePushTarget(Guid CircleId, bool IncludeOwner) : PushTarget;

public sealed record QueuedPush(PushTarget Target, PushContent Content);

/// <summary>
/// Hands pushes from request handlers to the background dispatcher, so a slow FCM round-trip never
/// delays an upload or a comment. Bounded: under a flood the oldest pushes are dropped, never requests.
/// </summary>
public sealed class PushQueue
{
    private readonly Channel<QueuedPush> _channel = Channel.CreateBounded<QueuedPush>(
        new BoundedChannelOptions(10_000) { FullMode = BoundedChannelFullMode.DropOldest, SingleReader = true });

    public void Enqueue(QueuedPush push) => _channel.Writer.TryWrite(push);

    public IAsyncEnumerable<QueuedPush> ReadAllAsync(CancellationToken ct) => _channel.Reader.ReadAllAsync(ct);
}

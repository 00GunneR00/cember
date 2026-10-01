using Cember.Application.Common;

namespace Cember.Application.Interfaces;

/// <summary>A push notification; <see cref="Data"/> tells the app what to open when it's tapped.</summary>
public record PushContent(string Title, string Body, IReadOnlyDictionary<string, string> Data);

public interface IPushService
{
    Task RegisterDeviceAsync(CurrentActor actor, string token, string? platform, CancellationToken ct = default);

    Task UnregisterDeviceAsync(CurrentActor actor, string token, CancellationToken ct = default);

    /// <summary>Queues a push to every device of a host. Returns immediately; delivery happens in the background.</summary>
    void QueueToUser(Guid userId, PushContent content);

    /// <summary>Queues a push to everyone in a circle — owner and guests — optionally skipping the owner.</summary>
    void QueueToCircle(Guid circleId, PushContent content, bool includeOwner = true);
}

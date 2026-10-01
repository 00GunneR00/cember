using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Push;

/// <summary>Resolves a queued push to device tokens and sends it, forgetting tokens FCM reports as dead.</summary>
public class PushDispatcher(CemberDbContext db, IPushTransport sender)
{
    public async Task DispatchAsync(QueuedPush push, CancellationToken ct)
    {
        if (!sender.IsEnabled) return;

        var tokens = push.Target switch
        {
            UserPushTarget user => await db.DeviceTokens
                .Where(d => d.UserId == user.UserId)
                .Select(d => new { d.Id, d.Token })
                .ToListAsync(ct),
            CirclePushTarget circle => await db.DeviceTokens
                .Where(d =>
                    (d.GuestSessionId != null && d.GuestSession!.CircleId == circle.CircleId) ||
                    (circle.IncludeOwner && d.UserId != null && db.Circles.Any(c => c.Id == circle.CircleId && c.OwnerUserId == d.UserId)))
                .Select(d => new { d.Id, d.Token })
                .ToListAsync(ct),
            _ => [],
        };

        // One phone can be registered under several identities (host + guest in this circle) —
        // it should still buzz only once.
        var deadTokenIds = new List<Guid>();
        foreach (var group in tokens.GroupBy(t => t.Token))
        {
            var result = await sender.SendAsync(group.Key, push.Content, ct);
            if (result == PushSendResult.InvalidToken)
            {
                deadTokenIds.AddRange(group.Select(t => t.Id));
            }
        }

        if (deadTokenIds.Count > 0)
        {
            await db.DeviceTokens.Where(d => deadTokenIds.Contains(d.Id)).ExecuteDeleteAsync(ct);
        }
    }
}

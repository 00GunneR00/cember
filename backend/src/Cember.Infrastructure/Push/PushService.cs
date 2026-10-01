using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Push;

public class PushService(CemberDbContext db, PushQueue queue) : IPushService
{
    public async Task RegisterDeviceAsync(CurrentActor actor, string token, string? platform, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 512)
        {
            throw new ValidationAppException("Geçersiz cihaz anahtarı.");
        }

        var now = DateTimeOffset.UtcNow;
        var existing = await db.DeviceTokens.FirstOrDefaultAsync(d => d.Token == token &&
            (actor.IsHost ? d.UserId == actor.Id : d.GuestSessionId == actor.Id), ct);
        if (existing is not null)
        {
            existing.LastSeenAt = now;
            existing.Platform = platform;
        }
        else
        {
            db.DeviceTokens.Add(new DeviceToken
            {
                Id = Guid.NewGuid(),
                Token = token,
                UserId = actor.IsHost ? actor.Id : null,
                GuestSessionId = actor.IsGuest ? actor.Id : null,
                Platform = platform,
                CreatedAt = now,
                LastSeenAt = now,
            });
        }

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Registered concurrently by the same phone — the row exists, which is all we need.
        }
    }

    public async Task UnregisterDeviceAsync(CurrentActor actor, string token, CancellationToken ct = default)
    {
        await db.DeviceTokens
            .Where(d => d.Token == token && (actor.IsHost ? d.UserId == actor.Id : d.GuestSessionId == actor.Id))
            .ExecuteDeleteAsync(ct);
    }

    public void QueueToUser(Guid userId, PushContent content) => queue.Enqueue(new QueuedPush(new UserPushTarget(userId), content));

    public void QueueToCircle(Guid circleId, PushContent content, bool includeOwner = true) =>
        queue.Enqueue(new QueuedPush(new CirclePushTarget(circleId, includeOwner), content));
}

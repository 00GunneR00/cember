using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Services;

public class ActorLookupService(CemberDbContext db) : IActorLookupService
{
    public async Task<CurrentActor?> FindByApiKeyAsync(string apiKey, CancellationToken ct = default)
    {
        var hash = SecretTokens.Hash(apiKey);
        var user = await db.Users.FirstOrDefaultAsync(u => u.ApiKeyHash == hash, ct);
        if (user is null)
        {
            // Not the host's original key — check keys issued via Google sign-in on another device.
            var linkedKey = await db.ApiKeys.Include(k => k.User).FirstOrDefaultAsync(k => k.ApiKeyHash == hash, ct);
            user = linkedKey?.User;
        }
        return user is null ? null : new CurrentActor(ActorKind.Host, user.Id, null, user.DisplayName, user.IsAdmin);
    }

    public async Task<CurrentActor?> FindByGuestSessionTokenAsync(string sessionToken, CancellationToken ct = default)
    {
        var hash = SecretTokens.Hash(sessionToken);
        var session = await db.GuestSessions.FirstOrDefaultAsync(g => g.SessionTokenHash == hash, ct);
        if (session is null)
        {
            return null;
        }

        session.LastSeenAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        return new CurrentActor(ActorKind.Guest, session.Id, session.CircleId, session.DisplayName);
    }
}

using Cember.Application.Common;

namespace Cember.Application.Interfaces;

public interface IActorLookupService
{
    Task<CurrentActor?> FindByApiKeyAsync(string apiKey, CancellationToken ct = default);

    Task<CurrentActor?> FindByGuestSessionTokenAsync(string sessionToken, CancellationToken ct = default);
}

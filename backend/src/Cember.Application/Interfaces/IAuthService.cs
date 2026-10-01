using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface IAuthService
{
    Task<RegisterHostResponse> RegisterHostAsync(RegisterHostRequest request, CancellationToken ct = default);

    /// <summary>
    /// Signs in with Google. Returns an existing host's credentials if this Google account is already
    /// linked, otherwise registers a brand-new host and links it.
    /// </summary>
    Task<RegisterHostResponse> GoogleSignInAsync(GoogleSignInRequest request, CancellationToken ct = default);

    /// <summary>Links a Google account to the currently signed-in host, for account recovery on other devices.</summary>
    Task LinkGoogleAsync(Guid hostId, LinkGoogleRequest request, CancellationToken ct = default);
}

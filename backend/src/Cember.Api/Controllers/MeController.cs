using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1/me")]
public class MeController(IProfileService profileService, IAuthService authService) : CemberControllerBase
{
    [HttpGet]
    public async Task<ActionResult<ProfileDto>> Get(CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await profileService.GetProfileAsync(hostId, ct));
    }

    /// <summary>Permanently deletes the signed-in host account and everything that belongs to it.</summary>
    [HttpDelete]
    public async Task<IActionResult> DeleteAccount(CancellationToken ct)
    {
        var hostId = RequireHostId();
        await profileService.DeleteAccountAsync(hostId, ct);
        return NoContent();
    }

    /// <summary>
    /// Called with a guest token: deletes that guest identity and what it posted. The app calls this for
    /// every circle it joined as a guest when the user deletes their account.
    /// </summary>
    [HttpDelete("guest-session")]
    public async Task<IActionResult> DeleteGuestSession(CancellationToken ct)
    {
        var actor = Actor;
        if (!actor.IsGuest)
        {
            throw new ForbiddenAppException("Bu işlem yalnızca misafir oturumları içindir.");
        }
        await profileService.DeleteGuestSessionAsync(actor.Id, ct);
        return NoContent();
    }

    /// <summary>Registers this phone for push under the calling identity — host or guest.</summary>
    [HttpPost("device-token")]
    public async Task<IActionResult> RegisterDeviceToken(DeviceTokenRequest request, [FromServices] IPushService push, CancellationToken ct)
    {
        await push.RegisterDeviceAsync(Actor, request.Token, request.Platform, ct);
        return NoContent();
    }

    /// <summary>Stops pushes to this phone for the calling identity — used on sign-out.</summary>
    [HttpDelete("device-token")]
    public async Task<IActionResult> UnregisterDeviceToken(DeviceTokenRequest request, [FromServices] IPushService push, CancellationToken ct)
    {
        await push.UnregisterDeviceAsync(Actor, request.Token, ct);
        return NoContent();
    }

    [HttpPatch("settings")]
    public async Task<IActionResult> UpdateSettings(UpdateSettingsRequest request, CancellationToken ct)
    {
        var hostId = RequireHostId();
        await profileService.UpdateSettingsAsync(hostId, request, ct);
        return NoContent();
    }

    [HttpPost("link-google")]
    public async Task<IActionResult> LinkGoogle(LinkGoogleRequest request, CancellationToken ct)
    {
        var hostId = RequireHostId();
        await authService.LinkGoogleAsync(hostId, request, ct);
        return NoContent();
    }

    [HttpGet("favorites")]
    public async Task<ActionResult<PhotoPageDto>> GetFavorites([FromQuery] string? cursor, [FromQuery] int pageSize, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await profileService.GetFavoritesAsync(hostId, cursor, pageSize <= 0 ? 40 : pageSize, ct));
    }
}

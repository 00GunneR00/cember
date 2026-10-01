using System.Security.Claims;
using System.Text.Encodings.Web;
using Cember.Application.Common;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Cember.Api.Auth;

public static class ActorClaimTypes
{
    public const string Kind = "cember_kind";
    public const string CircleId = "cember_circle";
    public const string IsAdmin = "cember_isadmin";
}

public class BearerActorAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder,
    IActorLookupService actorLookup) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Bearer";

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("Authorization", out var headerValue))
        {
            return AuthenticateResult.NoResult();
        }

        var header = headerValue.ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return AuthenticateResult.NoResult();
        }

        var token = header["Bearer ".Length..].Trim();
        if (string.IsNullOrEmpty(token))
        {
            return AuthenticateResult.NoResult();
        }

        CurrentActor? actor = await actorLookup.FindByApiKeyAsync(token, Context.RequestAborted);
        actor ??= await actorLookup.FindByGuestSessionTokenAsync(token, Context.RequestAborted);

        if (actor is null)
        {
            return AuthenticateResult.Fail("Geçersiz kimlik bilgisi.");
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, actor.Id.ToString()),
            new(ClaimTypes.Name, actor.DisplayName),
            new(ActorClaimTypes.Kind, actor.Kind.ToString()),
            new(ActorClaimTypes.IsAdmin, actor.IsAdmin.ToString()),
        };
        if (actor.GuestCircleId is { } circleId)
        {
            claims.Add(new Claim(ActorClaimTypes.CircleId, circleId.ToString()));
        }

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return AuthenticateResult.Success(ticket);
    }
}

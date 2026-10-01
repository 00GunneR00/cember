using System.Security.Claims;
using Cember.Application.Common;

namespace Cember.Api.Auth;

public static class ClaimsPrincipalExtensions
{
    public static CurrentActor ToActor(this ClaimsPrincipal principal)
    {
        var id = Guid.Parse(principal.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var name = principal.FindFirstValue(ClaimTypes.Name)!;
        var kind = Enum.Parse<ActorKind>(principal.FindFirstValue(ActorClaimTypes.Kind)!);
        Guid? circleId = principal.FindFirstValue(ActorClaimTypes.CircleId) is { } c ? Guid.Parse(c) : null;
        var isAdmin = bool.TryParse(principal.FindFirstValue(ActorClaimTypes.IsAdmin), out var admin) && admin;
        return new CurrentActor(kind, id, circleId, name, isAdmin);
    }
}

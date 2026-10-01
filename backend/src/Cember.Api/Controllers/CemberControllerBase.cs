using Cember.Api.Auth;
using Cember.Application.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[ApiController]
[Authorize]
public abstract class CemberControllerBase : ControllerBase
{
    protected CurrentActor Actor => User.ToActor();

    protected Guid RequireHostId()
    {
        var actor = Actor;
        if (!actor.IsHost)
        {
            throw new ForbiddenAppException("Bu işlem yalnızca hesap sahipleri içindir.");
        }
        return actor.Id;
    }

    protected void RequireAdmin()
    {
        if (!Actor.IsAdmin)
        {
            throw new ForbiddenAppException("Bu işlem yalnızca yöneticiler içindir.");
        }
    }
}

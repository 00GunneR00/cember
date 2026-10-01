using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1/auth")]
public class AuthController(IAuthService authService) : ControllerBase
{
    [HttpPost("host/register")]
    public async Task<ActionResult<RegisterHostResponse>> RegisterHost(RegisterHostRequest request, CancellationToken ct)
    {
        var result = await authService.RegisterHostAsync(request, ct);
        return Created(string.Empty, result);
    }

    [HttpPost("google")]
    public async Task<ActionResult<RegisterHostResponse>> GoogleSignIn(GoogleSignInRequest request, CancellationToken ct)
    {
        return Ok(await authService.GoogleSignInAsync(request, ct));
    }
}

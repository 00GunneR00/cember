using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1")]
public class InviteController(IInviteService inviteService) : CemberControllerBase
{
    [HttpPost("circles/{circleId:guid}/invite")]
    public async Task<ActionResult<InviteDto>> Rotate(Guid circleId, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await inviteService.RotateAsync(circleId, hostId, ct));
    }

    [HttpGet("circles/{circleId:guid}/invite")]
    public async Task<ActionResult<InviteDto>> GetCurrent(Guid circleId, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await inviteService.GetCurrentAsync(circleId, hostId, ct));
    }

    [HttpGet("invite/{token}")]
    [AllowAnonymous]
    public async Task<ActionResult<InvitePreviewDto>> GetPreview(string token, CancellationToken ct)
    {
        return Ok(await inviteService.GetPreviewAsync(token, ct));
    }

    [HttpPost("invite/{token}/join")]
    [AllowAnonymous]
    public async Task<ActionResult<JoinInviteResponse>> Join(string token, JoinInviteRequest request, CancellationToken ct)
    {
        return Ok(await inviteService.JoinAsync(token, request, ct));
    }
}

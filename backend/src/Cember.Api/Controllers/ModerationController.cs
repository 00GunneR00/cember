using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1")]
public class ModerationController(IModerationService moderationService) : CemberControllerBase
{
    [HttpGet("blocks")]
    public async Task<ActionResult<IReadOnlyList<BlockedUserDto>>> ListBlocks(CancellationToken ct)
    {
        return Ok(await moderationService.ListBlocksAsync(Actor, ct));
    }

    [HttpDelete("blocks/{blockId:guid}")]
    public async Task<IActionResult> Unblock(Guid blockId, CancellationToken ct)
    {
        await moderationService.UnblockAsync(blockId, Actor, ct);
        return NoContent();
    }

    [HttpGet("admin/reports")]
    public async Task<ActionResult<IReadOnlyList<ReportedPhotoDto>>> ListOpenReports(CancellationToken ct)
    {
        RequireAdmin();
        return Ok(await moderationService.ListOpenReportsAsync(ct));
    }

    [HttpPost("admin/reports/{photoId:guid}/resolve")]
    public async Task<IActionResult> Resolve(Guid photoId, ResolveReportsRequest request, CancellationToken ct)
    {
        RequireAdmin();
        await moderationService.ResolveReportsAsync(photoId, request.RemovePhoto, ct);
        return NoContent();
    }
}

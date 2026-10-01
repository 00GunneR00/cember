using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1/circles")]
public class CirclesController(ICircleService circleService, IInviteService inviteService) : CemberControllerBase
{
    [HttpPost]
    public async Task<ActionResult<CircleSummaryDto>> Create(CreateCircleRequest request, CancellationToken ct)
    {
        var hostId = RequireHostId();
        var result = await circleService.CreateAsync(hostId, request, ct);
        return CreatedAtAction(nameof(GetDetail), new { id = result.Id }, result);
    }

    [HttpGet]
    public async Task<ActionResult<CirclesOverviewDto>> GetOverview(CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await circleService.GetOverviewAsync(hostId, ct));
    }

    [HttpGet("discover")]
    public async Task<ActionResult<DiscoverCirclesPageDto>> Discover([FromQuery] string? query, [FromQuery] string? cursor, [FromQuery] int pageSize, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await circleService.DiscoverAsync(hostId, query, cursor, pageSize <= 0 ? 20 : pageSize, ct));
    }

    [HttpGet("{id:guid}/preview-photos")]
    public async Task<ActionResult<CirclePreviewPhotosDto>> GetPreviewPhotos(Guid id, [FromQuery] int limit, CancellationToken ct)
    {
        RequireHostId();
        var capped = limit <= 0 ? 10 : Math.Min(limit, 10);
        return Ok(await circleService.GetPreviewPhotosAsync(id, capped, ct));
    }

    [HttpPost("{id:guid}/join")]
    public async Task<ActionResult<JoinInviteResponse>> JoinOpenCircle(Guid id, CancellationToken ct)
    {
        RequireHostId();
        return Ok(await inviteService.JoinOpenCircleAsync(id, Actor, ct));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CircleDetailDto>> GetDetail(Guid id, CancellationToken ct)
    {
        return Ok(await circleService.GetDetailAsync(id, Actor, ct));
    }

    [HttpPatch("{id:guid}")]
    public async Task<ActionResult<CircleDetailDto>> Update(Guid id, UpdateCircleRequest request, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await circleService.UpdateAsync(id, hostId, request, ct));
    }

    [HttpPost("{id:guid}/recap")]
    public async Task<ActionResult<CircleDetailDto>> RequestRecap(Guid id, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await circleService.RequestRecapAsync(id, hostId, ct));
    }

    [HttpPost("{id:guid}/cover")]
    [RequestSizeLimit(20_000_000)]
    public async Task<ActionResult<CircleDetailDto>> SetCover(Guid id, IFormFile file, CancellationToken ct)
    {
        var hostId = RequireHostId();
        var uploaded = new UploadedFile(file.FileName, file.ContentType, file.OpenReadStream(), file.Length);
        return Ok(await circleService.SetCoverPhotoAsync(id, hostId, uploaded, ct));
    }

    [HttpPost("{id:guid}/deletion-request")]
    public async Task<ActionResult<DeletionRequestStatusDto>> RequestDeletion(Guid id, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await circleService.RequestDeletionAsync(id, hostId, ct));
    }

    [HttpGet("{id:guid}/deletion-request")]
    public async Task<ActionResult<DeletionRequestStatusDto>> GetDeletionRequest(Guid id, CancellationToken ct)
    {
        return Ok(await circleService.GetDeletionStatusAsync(id, Actor, ct));
    }

    [HttpPost("{id:guid}/deletion-request/vote")]
    public async Task<ActionResult<DeletionRequestStatusDto>> VoteOnDeletion(Guid id, VoteOnDeletionRequest request, CancellationToken ct)
    {
        return Ok(await circleService.VoteOnDeletionAsync(id, Actor, request.Approve, ct));
    }

    [HttpDelete("{id:guid}/deletion-request")]
    public async Task<IActionResult> CancelDeletion(Guid id, CancellationToken ct)
    {
        var hostId = RequireHostId();
        await circleService.CancelDeletionRequestAsync(id, hostId, ct);
        return NoContent();
    }
}

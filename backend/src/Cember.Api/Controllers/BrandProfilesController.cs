using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1/admin")]
public class BrandProfilesController(IBrandService brandService, ICircleService circleService) : CemberControllerBase
{
    [HttpPost("brand-profiles")]
    public async Task<ActionResult<BrandProfileDto>> Create(
        [FromForm] string name,
        [FromForm] string primaryColorHex,
        [FromForm] string? secondaryColorHex,
        IFormFile? logo,
        CancellationToken ct)
    {
        RequireAdmin();
        var request = new CreateBrandProfileRequest(name, primaryColorHex, secondaryColorHex);
        var uploaded = logo is null ? null : new UploadedFile(logo.FileName, logo.ContentType, logo.OpenReadStream(), logo.Length);
        var result = await brandService.CreateBrandProfileAsync(request, uploaded, ct);
        return Created(string.Empty, result);
    }

    [HttpGet("brand-profiles")]
    public async Task<ActionResult<IReadOnlyList<BrandProfileDto>>> List(CancellationToken ct)
    {
        RequireAdmin();
        return Ok(await brandService.ListBrandProfilesAsync(ct));
    }

    [HttpPatch("circles/{circleId:guid}/brand")]
    public async Task<ActionResult<CircleDetailDto>> AssignBrand(Guid circleId, AssignBrandRequest request, CancellationToken ct)
    {
        RequireAdmin();
        return Ok(await circleService.AssignBrandAsync(circleId, request.BrandProfileId, ct));
    }

    [HttpGet("circles")]
    public async Task<ActionResult<IReadOnlyList<AdminCircleSummaryDto>>> ListCircles(CancellationToken ct)
    {
        RequireAdmin();
        return Ok(await circleService.ListAllForAdminAsync(ct));
    }
}

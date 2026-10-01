using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1/challenges")]
public class ChallengesController(IChallengeService challengeService) : CemberControllerBase
{
    /// <summary>Keşfet > Challenge: ready-made circle ideas to start with friends.</summary>
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ChallengeTemplateDto>>> List(CancellationToken ct)
    {
        RequireHostId();
        return Ok(await challengeService.ListAsync(ct));
    }
}

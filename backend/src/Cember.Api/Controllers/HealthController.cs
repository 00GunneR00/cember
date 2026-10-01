using Cember.Application.Interfaces;
using Cember.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Cember.Api.Controllers;

[ApiController]
[AllowAnonymous]
[Route("api/v1")]
public class HealthController(CemberDbContext db, IObjectStorageService storage) : ControllerBase
{
    [HttpGet("health")]
    public async Task<IActionResult> Get(CancellationToken ct)
    {
        var dbOk = await CheckDatabaseAsync(ct);
        var storageOk = await storage.BucketIsReachableAsync(ct);
        var status = dbOk && storageOk ? "ok" : "degraded";
        return Ok(new { status, db = dbOk, storage = storageOk });
    }

    private async Task<bool> CheckDatabaseAsync(CancellationToken ct)
    {
        try
        {
            return await db.Database.CanConnectAsync(ct);
        }
        catch
        {
            return false;
        }
    }
}

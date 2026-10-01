using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Api.Controllers;

[Route("api/v1/notifications")]
public class NotificationsController(INotificationService notificationService) : CemberControllerBase
{
    [HttpGet]
    public async Task<ActionResult<NotificationPageDto>> GetPage([FromQuery] string? cursor, [FromQuery] int pageSize, CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await notificationService.GetPageAsync(hostId, cursor, pageSize <= 0 ? 30 : pageSize, ct));
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<int>> GetUnreadCount(CancellationToken ct)
    {
        var hostId = RequireHostId();
        return Ok(await notificationService.GetUnreadCountAsync(hostId, ct));
    }

    [HttpPost("{id:guid}/read")]
    public async Task<IActionResult> MarkRead(Guid id, CancellationToken ct)
    {
        var hostId = RequireHostId();
        await notificationService.MarkReadAsync(hostId, id, ct);
        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead(CancellationToken ct)
    {
        var hostId = RequireHostId();
        await notificationService.MarkAllReadAsync(hostId, ct);
        return NoContent();
    }
}

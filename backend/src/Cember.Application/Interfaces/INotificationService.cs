using Cember.Application.Dtos;
using Cember.Domain.Entities;

namespace Cember.Application.Interfaces;

public interface INotificationService
{
    /// <summary>
    /// Records a notification for a recipient host. Never throws — a notification failure must not fail the action that triggered it.
    /// </summary>
    Task NotifyAsync(
        Guid recipientUserId,
        NotificationType type,
        Guid circleId,
        string actorDisplayName,
        Guid? photoId = null,
        string? preview = null,
        CancellationToken ct = default);

    Task<NotificationPageDto> GetPageAsync(Guid recipientUserId, string? cursor, int pageSize, CancellationToken ct = default);

    Task<int> GetUnreadCountAsync(Guid recipientUserId, CancellationToken ct = default);

    Task MarkReadAsync(Guid recipientUserId, Guid notificationId, CancellationToken ct = default);

    Task MarkAllReadAsync(Guid recipientUserId, CancellationToken ct = default);
}

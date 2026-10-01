using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Push;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Cember.Infrastructure.Services;

public class NotificationService(CemberDbContext db, IPushService push, ILogger<NotificationService> logger) : INotificationService
{
    public async Task NotifyAsync(
        Guid recipientUserId,
        NotificationType type,
        Guid circleId,
        string actorDisplayName,
        Guid? photoId = null,
        string? preview = null,
        CancellationToken ct = default)
    {
        try
        {
            var recipient = await db.Users.FirstOrDefaultAsync(u => u.Id == recipientUserId, ct);
            if (recipient is null || !IsEnabled(recipient, type))
            {
                return;
            }

            db.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                RecipientUserId = recipientUserId,
                CircleId = circleId,
                Type = type,
                ActorDisplayName = actorDisplayName,
                PhotoId = photoId,
                Preview = preview,
                IsRead = false,
                CreatedAt = DateTimeOffset.UtcNow,
            });
            await db.SaveChangesAsync(ct);

            var circleName = await db.Circles.Where(c => c.Id == circleId).Select(c => c.Name).FirstOrDefaultAsync(ct) ?? "";
            push.QueueToUser(recipientUserId, PushMessages.For(type, circleId, circleName, actorDisplayName, preview));
        }
        catch (Exception ex)
        {
            // A notification is a side effect of the real action (upload, comment, join, ...).
            // Never let it fail the action that triggered it.
            logger.LogWarning(ex, "Bildirim oluşturulamadı: {Type} / {CircleId}", type, circleId);
        }
    }

    // DeletionVoteNeeded requires an action from the recipient, so it always fires regardless of preferences.
    private static bool IsEnabled(User recipient, NotificationType type) => type switch
    {
        NotificationType.PhotoAdded => recipient.NotifyOnPhotoAdded,
        NotificationType.CommentAdded => recipient.NotifyOnComment,
        NotificationType.ReactionAdded => recipient.NotifyOnReaction,
        NotificationType.GuestJoined => recipient.NotifyOnGuestJoined,
        _ => true,
    };

    public async Task<NotificationPageDto> GetPageAsync(Guid recipientUserId, string? cursor, int pageSize, CancellationToken ct = default)
    {
        var query = db.Notifications.Include(n => n.Circle).Where(n => n.RecipientUserId == recipientUserId);
        if (cursor is not null && DateTimeOffset.TryParse(cursor, out var before))
        {
            query = query.Where(n => n.CreatedAt < before);
        }

        var rows = await query.OrderByDescending(n => n.CreatedAt).Take(pageSize + 1).ToListAsync(ct);
        var hasMore = rows.Count > pageSize;
        var page = rows.Take(pageSize).ToList();

        var dtos = page.Select(ToDto).ToList();
        var nextCursor = hasMore ? page[^1].CreatedAt.ToString("o") : null;
        var unreadCount = await GetUnreadCountAsync(recipientUserId, ct);

        return new NotificationPageDto(dtos, nextCursor, unreadCount);
    }

    public Task<int> GetUnreadCountAsync(Guid recipientUserId, CancellationToken ct = default) =>
        db.Notifications.CountAsync(n => n.RecipientUserId == recipientUserId && !n.IsRead, ct);

    public async Task MarkReadAsync(Guid recipientUserId, Guid notificationId, CancellationToken ct = default)
    {
        var notification = await db.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.RecipientUserId == recipientUserId, ct);
        if (notification is null || notification.IsRead)
        {
            return;
        }

        notification.IsRead = true;
        await db.SaveChangesAsync(ct);
    }

    public async Task MarkAllReadAsync(Guid recipientUserId, CancellationToken ct = default)
    {
        await db.Notifications
            .Where(n => n.RecipientUserId == recipientUserId && !n.IsRead)
            .ExecuteUpdateAsync(setters => setters.SetProperty(n => n.IsRead, true), ct);
    }

    private static NotificationDto ToDto(Notification n) => new(
        Id: n.Id,
        Type: n.Type,
        CircleId: n.CircleId,
        CircleName: n.Circle?.Name ?? "",
        ActorDisplayName: n.ActorDisplayName,
        PhotoId: n.PhotoId,
        Preview: n.Preview,
        IsRead: n.IsRead,
        CreatedAt: n.CreatedAt
    );
}

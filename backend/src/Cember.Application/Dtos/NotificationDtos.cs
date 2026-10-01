using Cember.Domain.Entities;

namespace Cember.Application.Dtos;

public record NotificationDto(
    Guid Id,
    NotificationType Type,
    Guid CircleId,
    string CircleName,
    string ActorDisplayName,
    Guid? PhotoId,
    string? Preview,
    bool IsRead,
    DateTimeOffset CreatedAt
);

public record NotificationPageDto(List<NotificationDto> Items, string? NextCursor, int UnreadCount);

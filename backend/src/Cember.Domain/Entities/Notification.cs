namespace Cember.Domain.Entities;

public class Notification
{
    public Guid Id { get; set; }
    public Guid RecipientUserId { get; set; }
    public User? RecipientUser { get; set; }
    public Guid CircleId { get; set; }
    public Circle? Circle { get; set; }
    public NotificationType Type { get; set; }
    public required string ActorDisplayName { get; set; }
    public Guid? PhotoId { get; set; }
    public string? Preview { get; set; }
    public bool IsRead { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

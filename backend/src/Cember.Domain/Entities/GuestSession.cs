namespace Cember.Domain.Entities;

public class GuestSession
{
    public Guid Id { get; set; }
    public Guid CircleId { get; set; }
    public Circle? Circle { get; set; }
    public Guid InviteTokenId { get; set; }
    public InviteToken? InviteToken { get; set; }
    public required string DisplayName { get; set; }
    public required string SessionTokenHash { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset LastSeenAt { get; set; }
}

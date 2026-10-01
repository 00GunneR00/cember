namespace Cember.Domain.Entities;

public class InviteToken
{
    public Guid Id { get; set; }
    public Guid CircleId { get; set; }
    public Circle? Circle { get; set; }
    public required string Token { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? RevokedAt { get; set; }
    public DateTimeOffset? ExpiresAt { get; set; }

    public ICollection<GuestSession> GuestSessions { get; set; } = new List<GuestSession>();
}

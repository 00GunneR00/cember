namespace Cember.Domain.Entities;

/// <summary>
/// One participant hiding another's photos and comments from themselves. Identities in Cember are
/// either a host account or a per-circle guest session, so each side has exactly one of its two ids set.
/// </summary>
public class UserBlock
{
    public Guid Id { get; set; }
    public Guid? BlockerUserId { get; set; }
    public User? BlockerUser { get; set; }
    public Guid? BlockerGuestSessionId { get; set; }
    public GuestSession? BlockerGuestSession { get; set; }
    public Guid? BlockedUserId { get; set; }
    public User? BlockedUser { get; set; }
    public Guid? BlockedGuestSessionId { get; set; }
    public GuestSession? BlockedGuestSession { get; set; }
    /// <summary>Kept so the block list stays readable without extra lookups.</summary>
    public required string BlockedDisplayName { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

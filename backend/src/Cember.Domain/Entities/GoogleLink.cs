namespace Cember.Domain.Entities;

/// <summary>
/// Links a host's Google account to their Cember identity, so they can sign back in
/// with Google on a new device instead of losing access when the local apiKey is gone.
/// </summary>
public class GoogleLink
{
    public Guid Id { get; set; }
    public required Guid UserId { get; set; }
    public required string GoogleSub { get; set; }
    public required string Email { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User? User { get; set; }
}

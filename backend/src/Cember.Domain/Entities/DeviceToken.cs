namespace Cember.Domain.Entities;

/// <summary>
/// A phone's push (FCM) token, registered per identity: the same phone appears once for its host account
/// and once for every circle it joined as a guest, so guests get the circle's pushes too.
/// </summary>
public class DeviceToken
{
    public Guid Id { get; set; }
    public required string Token { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public Guid? GuestSessionId { get; set; }
    public GuestSession? GuestSession { get; set; }
    public string? Platform { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset LastSeenAt { get; set; }
}

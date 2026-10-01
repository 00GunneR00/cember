namespace Cember.Domain.Entities;

/// <summary>
/// An additional device credential for a host, issued after Google sign-in. Kept separate from
/// User.ApiKeyHash so multiple devices can hold independent, individually valid keys for the same host.
/// </summary>
public class ApiKey
{
    public Guid Id { get; set; }
    public required Guid UserId { get; set; }
    public required string ApiKeyHash { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public User? User { get; set; }
}

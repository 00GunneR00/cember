namespace Cember.Domain.Entities;

public class Comment
{
    public Guid Id { get; set; }
    public Guid PhotoId { get; set; }
    public Photo? Photo { get; set; }
    public Guid? UserId { get; set; }
    public User? User { get; set; }
    public Guid? GuestSessionId { get; set; }
    public GuestSession? GuestSession { get; set; }
    public required string AuthorDisplayName { get; set; }
    public required string Body { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

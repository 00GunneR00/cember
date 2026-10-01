namespace Cember.Domain.Entities;

public class CircleDeletionVote
{
    public Guid Id { get; set; }
    public Guid CircleId { get; set; }
    public Circle? Circle { get; set; }
    public Guid? VoterUserId { get; set; }
    public User? VoterUser { get; set; }
    public Guid? VoterGuestSessionId { get; set; }
    public GuestSession? VoterGuestSession { get; set; }
    public bool Approved { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

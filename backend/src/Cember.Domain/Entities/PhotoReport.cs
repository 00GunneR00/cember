namespace Cember.Domain.Entities;

/// <summary>A participant flagging a photo for review. Exactly one of the reporter ids is set.</summary>
public class PhotoReport
{
    public Guid Id { get; set; }
    public Guid PhotoId { get; set; }
    public Photo? Photo { get; set; }
    public Guid? ReporterUserId { get; set; }
    public User? ReporterUser { get; set; }
    public Guid? ReporterGuestSessionId { get; set; }
    public GuestSession? ReporterGuestSession { get; set; }
    public ReportReason Reason { get; set; }
    public string? Note { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? ResolvedAt { get; set; }
}

namespace Cember.Domain.Entities;

public class Photo
{
    public Guid Id { get; set; }
    public Guid CircleId { get; set; }
    public Circle? Circle { get; set; }
    public Guid? UploadedByUserId { get; set; }
    public User? UploadedByUser { get; set; }
    public Guid? UploadedByGuestSessionId { get; set; }
    public GuestSession? UploadedByGuestSession { get; set; }
    public required string OriginalKey { get; set; }
    public required string ThumbnailKey { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public long FileSizeBytes { get; set; }
    public required string ContentType { get; set; }
    public bool IsPublished { get; set; } = true;
    /// <summary>Set when enough participants reported the photo — it stays hidden from everyone (owner included) until an admin reviews it.</summary>
    public DateTimeOffset? ModerationHiddenAt { get; set; }
    public PhotoSource Source { get; set; }
    /// <summary>Whether the uploader allowed this photo's commercial use by the circle's brand sponsor, if any.</summary>
    public bool CommercialUseConsent { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<PhotoReaction> Reactions { get; set; } = new List<PhotoReaction>();
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
    public ICollection<PhotoReport> Reports { get; set; } = new List<PhotoReport>();

    public string UploaderDisplayName => UploadedByUser?.DisplayName ?? UploadedByGuestSession?.DisplayName ?? "Bilinmeyen";
}

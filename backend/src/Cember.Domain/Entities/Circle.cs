namespace Cember.Domain.Entities;

public class Circle
{
    public Guid Id { get; set; }
    public Guid OwnerUserId { get; set; }
    public User? Owner { get; set; }
    public required string Name { get; set; }
    /// <summary>
    /// A short tagline shown on the Discover listing — a personal blurb for ordinary circles,
    /// or a brand's motto/slogan for a promotional circle (e.g. "Red Bull kanatlandırır").
    /// </summary>
    public string? Description { get; set; }
    public DateOnly? EventDate { get; set; }
    public string? CoverPhotoKey { get; set; }
    public bool IsArchived { get; set; }
    public bool AutoPublish { get; set; } = true;
    public bool AllowGuestDownloads { get; set; } = true;
    public bool IsOpenJoin { get; set; } = true;
    /// <summary>Which upload paths this circle accepts photos from — set by the owner at creation time.</summary>
    public PhotoUploadMode UploadMode { get; set; } = PhotoUploadMode.Both;
    public DateTimeOffset? DeletionRequestedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    /// <summary>
    /// "Banyo modu": when set, every photo stays hidden from everyone — the owner included —
    /// until this moment, then all of them are revealed together (like developing a film roll).
    /// </summary>
    public DateTimeOffset? RevealAt { get; set; }
    /// <summary>When the reveal was announced — lets the background worker fire it exactly once.</summary>
    public DateTimeOffset? RevealNotifiedAt { get; set; }

    public RecapStatus RecapStatus { get; set; } = RecapStatus.None;
    /// <summary>Object-storage key of the generated recap video (vertical MP4), once <see cref="RecapStatus.Ready"/>.</summary>
    public string? RecapKey { get; set; }
    public string? RecapError { get; set; }
    public DateTimeOffset? RecapGeneratedAt { get; set; }

    public bool IsDeveloping(DateTimeOffset now) => RevealAt is { } revealAt && now < revealAt;

    /// <summary>Set only via an admin-only endpoint — marks this as a paid brand-sponsorship circle.</summary>
    public Guid? BrandProfileId { get; set; }
    public BrandProfile? BrandProfile { get; set; }

    /// <summary>The circle's rules / photo tasks, shown to everyone inside it. Copied from the challenge when started from one.</summary>
    public List<string> Rules { get; set; } = [];

    /// <summary>Set when the circle was started from a Keşfet challenge; its prompts show inside the circle.</summary>
    public Guid? ChallengeTemplateId { get; set; }
    public ChallengeTemplate? ChallengeTemplate { get; set; }

    public ICollection<InviteToken> InviteTokens { get; set; } = new List<InviteToken>();
    public ICollection<GuestSession> GuestSessions { get; set; } = new List<GuestSession>();
    public ICollection<Photo> Photos { get; set; } = new List<Photo>();
    public ICollection<CircleDeletionVote> DeletionVotes { get; set; } = new List<CircleDeletionVote>();
}

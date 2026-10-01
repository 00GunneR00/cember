namespace Cember.Domain.Entities;

/// <summary>
/// A ready-made circle idea on Keşfet > Challenge: inspiring enough to share, concrete enough to start in one
/// tap. Starting it creates the user's own circle pre-filled with its settings and photo prompts.
/// Created by Çember or, when <see cref="CreatorName"/> is set, by an influencer.
/// </summary>
public class ChallengeTemplate
{
    public Guid Id { get; set; }
    /// <summary>Stable identifier used by the seed catalog and in share links.</summary>
    public required string Slug { get; set; }
    public required string Title { get; set; }
    /// <summary>The one-line motto shown on the card.</summary>
    public required string Tagline { get; set; }
    /// <summary>How to play, in two or three sentences.</summary>
    public required string Description { get; set; }
    public required string Emoji { get; set; }
    public ChallengeCategory Category { get; set; }
    public required string GradientStartHex { get; set; }
    public required string GradientEndHex { get; set; }
    public PhotoUploadMode UploadMode { get; set; } = PhotoUploadMode.Both;
    /// <summary>
    /// Banyo default: photos reveal this many days after the event day, at <see cref="RevealHour"/> local time.
    /// Null means the challenge doesn't use Banyo.
    /// </summary>
    public int? RevealAfterDays { get; set; }
    public int RevealHour { get; set; } = 10;
    /// <summary>Photo tasks shown inside every circle started from this challenge.</summary>
    public List<string> Prompts { get; set; } = [];
    public string? CreatorName { get; set; }
    public string? CreatorHandle { get; set; }
    public bool CreatorVerified { get; set; }
    public bool IsFeatured { get; set; }
    public bool IsActive { get; set; } = true;
    public int SortOrder { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public enum ChallengeCategory
{
    Gece,
    Kutlama,
    Gezi,
    Gunluk,
    Spor,
    Dugun,
}

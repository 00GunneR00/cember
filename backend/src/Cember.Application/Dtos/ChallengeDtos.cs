using Cember.Domain.Entities;

namespace Cember.Application.Dtos;

public record ChallengeTemplateDto(
    Guid Id,
    string Slug,
    string Title,
    string Tagline,
    string Description,
    string Emoji,
    ChallengeCategory Category,
    string GradientStartHex,
    string GradientEndHex,
    PhotoUploadMode UploadMode,
    int? RevealAfterDays,
    int RevealHour,
    List<string> Prompts,
    string? CreatorName,
    string? CreatorHandle,
    bool CreatorVerified,
    bool IsFeatured,
    // How many circles have been started from it — social proof on the card.
    int StartedCount
);

/// <summary>The challenge a circle was started from, shown inside the circle as its photo tasks.</summary>
public record CircleChallengeDto(
    Guid Id,
    string Title,
    string Emoji,
    List<string> Prompts,
    string? CreatorName,
    string? CreatorHandle,
    bool CreatorVerified
);

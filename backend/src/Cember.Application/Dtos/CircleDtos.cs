using Cember.Domain.Entities;

namespace Cember.Application.Dtos;

public record CreateCircleRequest(
    string Name,
    DateOnly? EventDate,
    bool IsOpenJoin,
    string? Description = null,
    PhotoUploadMode? UploadMode = null,
    DateTimeOffset? RevealAt = null,
    // Set when started from a Keşfet challenge — links the circle to its photo prompts.
    Guid? ChallengeTemplateId = null,
    // When null and started from a challenge, the challenge's prompts become the rules.
    List<string>? Rules = null
);

public record CircleSummaryDto(
    Guid Id,
    string Name,
    DateOnly? EventDate,
    bool IsArchived,
    bool IsOpenJoin,
    int PhotoCount,
    int ParticipantCount,
    string? CoverUrl,
    string? Description,
    PhotoUploadMode UploadMode,
    BrandProfileDto? Brand = null,
    DateTimeOffset? RevealAt = null,
    bool IsDeveloping = false
);

public record CirclesOverviewDto(List<CircleSummaryDto> Live, List<CircleSummaryDto> Past);

/// <summary>Admin-only, system-wide circle listing (not scoped to a single owner) used by the admin panel to assign brands.</summary>
public record AdminCircleSummaryDto(
    Guid Id,
    string Name,
    DateOnly? EventDate,
    string HostDisplayName,
    bool IsArchived,
    BrandProfileDto? Brand
);

public record CircleDetailDto(
    Guid Id,
    string Name,
    DateOnly? EventDate,
    int ParticipantCount,
    int MemoryCount,
    bool IsOpenJoin,
    bool AutoPublish,
    bool AllowGuestDownloads,
    bool ViewerIsHost,
    string HostDisplayName,
    string? CoverUrl,
    string? Description,
    PhotoUploadMode UploadMode,
    BrandProfileDto? Brand = null,
    DateTimeOffset? RevealAt = null,
    bool IsDeveloping = false,
    // How many of the hidden photos the viewer took themselves — shown while the circle is developing.
    int ViewerUploadCount = 0,
    RecapStatus RecapStatus = RecapStatus.None,
    string? RecapUrl = null,
    string? RecapError = null,
    CircleChallengeDto? Challenge = null,
    List<string>? Rules = null
);

public record UpdateCircleRequest(
    string? Name,
    DateOnly? EventDate,
    bool? IsArchived,
    bool? AutoPublish,
    bool? AllowGuestDownloads,
    bool? IsOpenJoin,
    string? Description,
    // Moves (or, on a circle with no photos yet, turns on) the Banyo reveal time. Must be in the future.
    DateTimeOffset? RevealAt = null,
    // Reveals a developing circle right now.
    bool? RevealNow = null,
    // Replaces the circle's rules (an empty list clears them).
    List<string>? Rules = null
);

public record DeletionRequestStatusDto(
    bool IsPending,
    string? RequestedByDisplayName,
    int EligibleVoterCount,
    int RequiredApprovals,
    int CurrentApprovals,
    bool ViewerIsEligible,
    bool? ViewerVote,
    bool Deleted
);

public record VoteOnDeletionRequest(bool Approve);

public record PublicCircleSummaryDto(
    Guid Id,
    string Name,
    DateOnly? EventDate,
    string HostDisplayName,
    int PhotoCount,
    int ParticipantCount,
    string? CoverUrl,
    string? Description,
    BrandProfileDto? Brand = null
);

public record DiscoverCirclesPageDto(List<PublicCircleSummaryDto> Items, string? NextCursor);

/// A capped sample of what's already been shared in an open circle — shown on the Discover
/// preview screen so a viewer can see what kind of thing this is before joining.
public record CirclePreviewPhotosDto(List<string> ThumbnailUrls);

namespace Cember.Application.Dtos;

public record InviteDto(
    string Token,
    string InviteUrl,
    int ConnectedGuestCount,
    int SharedMemoryCount,
    bool AutoPublish,
    bool AllowGuestDownloads
);

public record InvitePreviewDto(string CircleName, DateOnly? EventDate, string? CoverUrl, string HostDisplayName);

public record JoinInviteRequest(string DisplayName);

public record JoinInviteResponse(string GuestSessionToken, CircleDetailDto Circle);

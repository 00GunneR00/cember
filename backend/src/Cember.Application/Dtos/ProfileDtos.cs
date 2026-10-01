namespace Cember.Application.Dtos;

public record ProfileDto(
    string DisplayName,
    int CircleCount,
    int PhotoCount,
    int EventCount,
    long StorageUsedBytes,
    long StorageTotalBytes,
    bool OnlyUploadOnWifi,
    bool NotifyOnPhotoAdded,
    bool NotifyOnComment,
    bool NotifyOnReaction,
    bool NotifyOnGuestJoined,
    string? LinkedGoogleEmail
);

public record UpdateSettingsRequest(
    bool? OnlyUploadOnWifi,
    bool? NotifyOnPhotoAdded,
    bool? NotifyOnComment,
    bool? NotifyOnReaction,
    bool? NotifyOnGuestJoined,
    string? DisplayName = null
);

public record DeviceTokenRequest(string Token, string? Platform = null);

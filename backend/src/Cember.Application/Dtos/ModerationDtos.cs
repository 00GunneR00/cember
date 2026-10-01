using Cember.Domain.Entities;

namespace Cember.Application.Dtos;

public record ReportPhotoRequest(ReportReason Reason, string? Note = null);

/// <summary><see cref="CircleName"/> is set when the block was made inside a circle joined as a guest — it only applies there.</summary>
public record BlockedUserDto(Guid Id, string DisplayName, DateTimeOffset CreatedAt, string? CircleName = null);

/// <summary>Admin view of one photo with open reports against it.</summary>
public record ReportedPhotoDto(
    Guid PhotoId,
    Guid CircleId,
    string CircleName,
    string UploaderDisplayName,
    string ThumbnailUrl,
    int ReportCount,
    List<ReportReason> Reasons,
    List<string> Notes,
    bool IsHidden,
    DateTimeOffset FirstReportedAt
);

public record ResolveReportsRequest(bool RemovePhoto);

using Cember.Application.Common;
using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface IModerationService
{
    /// <summary>
    /// Flags a photo. The reporter stops seeing it right away; once enough different people report it,
    /// it's hidden from everyone until an admin reviews it.
    /// </summary>
    Task ReportPhotoAsync(Guid photoId, CurrentActor actor, ReportPhotoRequest request, CancellationToken ct = default);

    /// <summary>Hides every photo and comment by this photo's uploader from the actor.</summary>
    Task<BlockedUserDto> BlockUploaderAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default);

    Task<IReadOnlyList<BlockedUserDto>> ListBlocksAsync(CurrentActor actor, CancellationToken ct = default);

    Task UnblockAsync(Guid blockId, CurrentActor actor, CancellationToken ct = default);

    /// <summary>Admin-only: photos with unresolved reports, most-reported first.</summary>
    Task<IReadOnlyList<ReportedPhotoDto>> ListOpenReportsAsync(CancellationToken ct = default);

    /// <summary>Admin-only: closes a photo's open reports, either removing the photo or restoring it.</summary>
    Task ResolveReportsAsync(Guid photoId, bool removePhoto, CancellationToken ct = default);
}

using Cember.Application.Common;
using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface ICircleService
{
    Task<CircleSummaryDto> CreateAsync(Guid ownerUserId, CreateCircleRequest request, CancellationToken ct = default);

    Task<CirclesOverviewDto> GetOverviewAsync(Guid ownerUserId, CancellationToken ct = default);

    Task<DiscoverCirclesPageDto> DiscoverAsync(Guid viewerHostId, string? query, string? cursor, int pageSize, CancellationToken ct = default);

    /// <summary>
    /// A capped sample of an open circle's already-shared photos, viewable before joining.
    /// Only ever available for open (<see cref="Domain.Entities.Circle.IsOpenJoin"/>), non-archived circles.
    /// </summary>
    Task<CirclePreviewPhotosDto> GetPreviewPhotosAsync(Guid circleId, int limit, CancellationToken ct = default);

    Task<CircleDetailDto> GetDetailAsync(Guid circleId, CurrentActor actor, CancellationToken ct = default);

    /// <summary>Queues (re)generation of the circle's recap video; the background worker renders it.</summary>
    Task<CircleDetailDto> RequestRecapAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default);

    Task<CircleDetailDto> UpdateAsync(Guid circleId, Guid ownerUserId, UpdateCircleRequest request, CancellationToken ct = default);

    /// <summary>
    /// Sets (or replaces) the circle's cover photo. Works the same for open and locked circles —
    /// only ownership is checked, never <see cref="Domain.Entities.Circle.IsOpenJoin"/>.
    /// </summary>
    Task<CircleDetailDto> SetCoverPhotoAsync(Guid circleId, Guid ownerUserId, UploadedFile file, CancellationToken ct = default);

    Task<DeletionRequestStatusDto> RequestDeletionAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default);

    Task<DeletionRequestStatusDto> GetDeletionStatusAsync(Guid circleId, CurrentActor actor, CancellationToken ct = default);

    Task<DeletionRequestStatusDto> VoteOnDeletionAsync(Guid circleId, CurrentActor actor, bool approve, CancellationToken ct = default);

    Task CancelDeletionRequestAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default);

    /// <summary>Admin-only: attaches (or, with a null id, removes) a brand sponsorship on any circle, regardless of ownership.</summary>
    Task<CircleDetailDto> AssignBrandAsync(Guid circleId, Guid? brandProfileId, CancellationToken ct = default);

    /// <summary>Admin-only: lists every circle system-wide (not scoped to one owner) so a brand can be assigned to any of them.</summary>
    Task<IReadOnlyList<AdminCircleSummaryDto>> ListAllForAdminAsync(CancellationToken ct = default);
}

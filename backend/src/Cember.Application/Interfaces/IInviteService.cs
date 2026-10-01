using Cember.Application.Common;
using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface IInviteService
{
    Task<InviteDto> RotateAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default);

    Task<InviteDto> GetCurrentAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default);

    Task<InvitePreviewDto> GetPreviewAsync(string token, CancellationToken ct = default);

    Task<JoinInviteResponse> JoinAsync(string token, JoinInviteRequest request, CancellationToken ct = default);

    /// <summary>
    /// Joins a registered host onto another host's open-join circle as a guest participant,
    /// without needing that circle's private invite token (used by circle discovery).
    /// </summary>
    Task<JoinInviteResponse> JoinOpenCircleAsync(Guid circleId, CurrentActor hostActor, CancellationToken ct = default);
}

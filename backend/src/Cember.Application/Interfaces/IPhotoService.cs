using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Domain.Entities;

namespace Cember.Application.Interfaces;

public interface IPhotoService
{
    Task<UploadPhotoResultDto> UploadAsync(Guid circleId, CurrentActor actor, IReadOnlyList<UploadedFile> files, PhotoSource source, bool commercialUseConsent = false, CancellationToken ct = default);

    Task<PhotoPageDto> GetPhotosAsync(Guid circleId, CurrentActor actor, string? cursor, int pageSize, PhotoSource? source = null, CancellationToken ct = default);

    Task<ReactionResultDto> ToggleReactionAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default);

    Task<CommentDto> AddCommentAsync(Guid photoId, CurrentActor actor, AddCommentRequest request, CancellationToken ct = default);

    /// <summary>Deletes a photo — allowed for whoever uploaded it and for the circle owner.</summary>
    Task DeletePhotoAsync(Guid photoId, CurrentActor actor, CancellationToken ct = default);

    Task<CommentPageDto> GetCommentsAsync(Guid photoId, CurrentActor actor, string? cursor, int pageSize, CancellationToken ct = default);

    Task ExportZipAsync(Guid circleId, CurrentActor actor, Stream destination, CancellationToken ct = default);
}

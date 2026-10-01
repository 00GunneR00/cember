using Cember.Domain.Entities;

namespace Cember.Application.Dtos;

public record PhotoDto(
    Guid Id,
    string UploaderDisplayName,
    string ThumbnailUrl,
    int ReactionCount,
    bool ViewerHasReacted,
    int CommentCount,
    DateTimeOffset CreatedAt,
    PhotoSource Source,
    // True when the viewer uploaded it or owns the circle — the app then offers "Sil" instead of "Şikayet Et".
    bool ViewerCanDelete = false
);

public record PhotoPageDto(List<PhotoDto> Photos, string? NextCursor);

public record UploadPhotoResultDto(List<PhotoDto> Created, List<string> Errors);

public record ReactionResultDto(bool Reacted, int ReactionCount);

public record CommentDto(Guid Id, string AuthorDisplayName, string Body, DateTimeOffset CreatedAt);

public record CommentPageDto(List<CommentDto> Comments, string? NextCursor);

public record AddCommentRequest(string Body);

public record UploadedFile(string FileName, string ContentType, Stream Content, long Length);

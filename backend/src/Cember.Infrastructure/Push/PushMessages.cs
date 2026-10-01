using Cember.Application.Interfaces;
using Cember.Domain.Entities;

namespace Cember.Infrastructure.Push;

/// <summary>The wording of every push. The data payload tells the app which circle to open on tap.</summary>
public static class PushMessages
{
    public static PushContent For(NotificationType type, Guid circleId, string circleName, string actor, string? preview)
    {
        var (title, body) = type switch
        {
            NotificationType.PhotoAdded => (circleName, preview is null ? $"{actor} yeni bir fotoğraf ekledi 📸" : $"{actor} {preview} ekledi 📸"),
            NotificationType.CommentAdded => (circleName, $"{actor} fotoğrafına yorum yaptı: {preview}"),
            NotificationType.ReactionAdded => (circleName, $"{actor} fotoğrafını beğendi ❤️"),
            NotificationType.GuestJoined => (circleName, $"{actor} çembere katıldı 👋"),
            NotificationType.DeletionVoteNeeded => (circleName, "Çemberi silme oylaması açıldı, oyun gerekiyor."),
            NotificationType.PhotosRevealed => Revealed(circleName, preview),
            NotificationType.RecapReady => RecapReady(circleName),
            _ => (circleName, preview ?? ""),
        };
        return Content(type, circleId, title, body);
    }

    /// <summary>For everyone in the circle when a Banyo circle opens.</summary>
    public static PushContent PhotosRevealed(Guid circleId, string circleName, int photoCount)
    {
        var (title, body) = Revealed(circleName, $"{photoCount} kare banyodan çıktı");
        return Content(NotificationType.PhotosRevealed, circleId, title, body);
    }

    /// <summary>For everyone in the circle when its recap video is ready.</summary>
    public static PushContent RecapReadyForCircle(Guid circleId, string circleName)
    {
        var (title, body) = RecapReady(circleName);
        return Content(NotificationType.RecapReady, circleId, title, body);
    }

    private static (string, string) Revealed(string circleName, string? preview) =>
        ($"🎞️ {circleName} banyodan çıktı!", $"{preview ?? "Anılar açıldı"} — hemen bak!");

    private static (string, string) RecapReady(string circleName) =>
        ($"🎬 {circleName} özet videosu hazır", "En güzel kareler tek videoda. İzle ve paylaş!");

    private static PushContent Content(NotificationType type, Guid circleId, string title, string body) =>
        new(title, body, new Dictionary<string, string> { ["type"] = type.ToString(), ["circleId"] = circleId.ToString() });
}

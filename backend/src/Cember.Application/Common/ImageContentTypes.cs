namespace Cember.Application.Common;

/// <summary>
/// Shared image-upload rules used by any service that accepts a user-supplied image
/// (circle photos, circle cover photos, ...).
/// </summary>
public static class ImageContentTypes
{
    public static readonly HashSet<string> Allowed = ["image/jpeg", "image/png", "image/webp"];

    public static string ExtensionFor(string contentType) => contentType switch
    {
        "image/png" => ".png",
        "image/webp" => ".webp",
        _ => ".jpg",
    };
}

namespace Cember.Domain.Entities;

/// <summary>
/// Which upload paths a circle accepts photos from — set by the owner at creation time.
/// </summary>
public enum PhotoUploadMode
{
    QuickCaptureOnly,
    GalleryOnly,
    Both,
}

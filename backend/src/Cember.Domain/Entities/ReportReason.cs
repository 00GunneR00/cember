namespace Cember.Domain.Entities;

public enum ReportReason
{
    /// <summary>Nudity or sexual content.</summary>
    Inappropriate,
    /// <summary>Violence, hate or harassment.</summary>
    Violence,
    /// <summary>The reporter is in the photo and didn't agree to it being shared.</summary>
    Privacy,
    Spam,
    Other,
}

namespace Cember.Application.Common;

public static class RecapLimits
{
    /// <summary>A recap needs at least this many published photos to be worth a video.</summary>
    public const int MinPhotoCount = 3;

    /// <summary>The recap uses at most this many photos — the most-liked ones, shown in the order they were taken.</summary>
    public const int MaxPhotoCount = 12;

    /// <summary>How far ahead a Banyo reveal may be scheduled.</summary>
    public static readonly TimeSpan MaxRevealDelay = TimeSpan.FromDays(30);
}

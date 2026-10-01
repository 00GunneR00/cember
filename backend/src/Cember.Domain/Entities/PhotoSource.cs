namespace Cember.Domain.Entities;

/// <summary>
/// Which upload path a specific photo came through — lets a "Both" circle show
/// Şipşak and gallery photos as separate feeds.
/// </summary>
public enum PhotoSource
{
    QuickCapture,
    Gallery,
}

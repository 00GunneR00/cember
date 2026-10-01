namespace Cember.Domain.Entities;

/// <summary>Lifecycle of a circle's auto-generated recap video.</summary>
public enum RecapStatus
{
    None,
    Pending,
    Processing,
    Ready,
    Failed,
}

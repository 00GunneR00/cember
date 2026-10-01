namespace Cember.Domain.Entities;

/// <summary>
/// A sponsor's identity (name, logo, colors) an admin can attach to a <see cref="Circle"/> to
/// rebrand its QR/album screens for a paid brand-sponsorship event. Created and assigned only
/// through admin-only endpoints — regular hosts never see or manage these.
/// </summary>
public class BrandProfile
{
    public Guid Id { get; set; }
    public required string Name { get; set; }
    public string? LogoKey { get; set; }
    public required string PrimaryColorHex { get; set; }
    public string? SecondaryColorHex { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public ICollection<Circle> Circles { get; set; } = new List<Circle>();
}

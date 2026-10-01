namespace Cember.Application.Common;

public static class CircleRules
{
    public const int MaxCount = 10;
    public const int MaxLength = 140;

    /// <summary>Trims each rule and drops blank ones; rejects lists that are too long.</summary>
    public static List<string> Normalize(IEnumerable<string>? rules)
    {
        var cleaned = (rules ?? []).Select(r => r?.Trim() ?? "").Where(r => r.Length > 0).ToList();
        if (cleaned.Count > MaxCount)
        {
            throw new ValidationAppException($"En fazla {MaxCount} kural ekleyebilirsin.");
        }
        if (cleaned.Any(r => r.Length > MaxLength))
        {
            throw new ValidationAppException($"Her kural en fazla {MaxLength} karakter olabilir.");
        }
        return cleaned;
    }
}

using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface IChallengeService
{
    /// <summary>Active challenges for Keşfet — featured first, then in catalog order.</summary>
    Task<IReadOnlyList<ChallengeTemplateDto>> ListAsync(CancellationToken ct = default);
}

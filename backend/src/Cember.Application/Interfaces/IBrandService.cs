using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

/// <summary>Admin-only management of sponsor brand profiles. Assigning a brand to a circle lives on <see cref="ICircleService"/>.</summary>
public interface IBrandService
{
    Task<BrandProfileDto> CreateBrandProfileAsync(CreateBrandProfileRequest request, UploadedFile? logo, CancellationToken ct = default);

    Task<IReadOnlyList<BrandProfileDto>> ListBrandProfilesAsync(CancellationToken ct = default);
}

using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Services;

public class BrandService(CemberDbContext db, IObjectStorageService storage) : IBrandService
{
    private const int LogoPresignedUrlHours = 1;

    public async Task<BrandProfileDto> CreateBrandProfileAsync(CreateBrandProfileRequest request, UploadedFile? logo, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ValidationAppException("name gerekli.");
        }
        if (string.IsNullOrWhiteSpace(request.PrimaryColorHex))
        {
            throw new ValidationAppException("primaryColorHex gerekli.");
        }

        var brand = new BrandProfile
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            PrimaryColorHex = request.PrimaryColorHex.Trim(),
            SecondaryColorHex = string.IsNullOrWhiteSpace(request.SecondaryColorHex) ? null : request.SecondaryColorHex.Trim(),
            CreatedAt = DateTimeOffset.UtcNow,
        };

        if (logo is not null)
        {
            if (!ImageContentTypes.Allowed.Contains(logo.ContentType))
            {
                throw new ValidationAppException("Desteklenmeyen dosya türü.");
            }

            // Skip the shared image pipeline on purpose: it re-encodes thumbnails as JPEG, which
            // would flatten a transparent PNG logo's background. Logos are stored as-is.
            var ext = ImageContentTypes.ExtensionFor(logo.ContentType);
            var key = $"brands/{brand.Id}/logo/{Guid.NewGuid()}{ext}";
            await storage.PutObjectAsync(key, logo.Content, logo.ContentType, ct);
            brand.LogoKey = key;
        }

        db.BrandProfiles.Add(brand);
        await db.SaveChangesAsync(ct);

        return ToDto(brand);
    }

    public async Task<IReadOnlyList<BrandProfileDto>> ListBrandProfilesAsync(CancellationToken ct = default)
    {
        var brands = await db.BrandProfiles.OrderByDescending(b => b.CreatedAt).ToListAsync(ct);
        return brands.Select(ToDto).ToList();
    }

    private BrandProfileDto ToDto(BrandProfile brand) => new(
        Id: brand.Id,
        Name: brand.Name,
        LogoUrl: brand.LogoKey is null ? null : storage.GetPresignedUrl(brand.LogoKey, TimeSpan.FromHours(LogoPresignedUrlHours)),
        PrimaryColorHex: brand.PrimaryColorHex,
        SecondaryColorHex: brand.SecondaryColorHex
    );
}

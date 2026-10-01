namespace Cember.Application.Dtos;

public record BrandProfileDto(
    Guid Id,
    string Name,
    string? LogoUrl,
    string PrimaryColorHex,
    string? SecondaryColorHex
);

public record CreateBrandProfileRequest(
    string Name,
    string PrimaryColorHex,
    string? SecondaryColorHex
);

public record AssignBrandRequest(Guid? BrandProfileId);

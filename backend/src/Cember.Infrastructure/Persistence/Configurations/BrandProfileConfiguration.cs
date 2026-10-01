using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class BrandProfileConfiguration : IEntityTypeConfiguration<BrandProfile>
{
    public void Configure(EntityTypeBuilder<BrandProfile> builder)
    {
        builder.HasKey(b => b.Id);
        builder.Property(b => b.Name).IsRequired().HasMaxLength(200);
        builder.Property(b => b.PrimaryColorHex).IsRequired().HasMaxLength(9);
        builder.Property(b => b.SecondaryColorHex).HasMaxLength(9);

        builder.HasMany(b => b.Circles)
            .WithOne(c => c.BrandProfile)
            .HasForeignKey(c => c.BrandProfileId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

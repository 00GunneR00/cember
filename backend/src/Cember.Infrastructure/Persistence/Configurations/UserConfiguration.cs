using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(u => u.Id);
        builder.Property(u => u.DisplayName).IsRequired().HasMaxLength(120);
        builder.Property(u => u.ApiKeyHash).IsRequired();
        builder.HasIndex(u => u.ApiKeyHash).IsUnique();
        builder.Property(u => u.IsAdmin).HasDefaultValue(false);

        builder.HasMany(u => u.OwnedCircles)
            .WithOne(c => c.Owner)
            .HasForeignKey(c => c.OwnerUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

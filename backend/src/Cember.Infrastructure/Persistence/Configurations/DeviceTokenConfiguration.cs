using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
{
    public void Configure(EntityTypeBuilder<DeviceToken> builder)
    {
        builder.HasKey(d => d.Id);
        builder.Property(d => d.Token).IsRequired().HasMaxLength(512);
        builder.Property(d => d.Platform).HasMaxLength(20);

        builder.HasOne(d => d.User).WithMany().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(d => d.GuestSession).WithMany().HasForeignKey(d => d.GuestSessionId).OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(d => new { d.Token, d.UserId }).IsUnique().HasFilter("\"UserId\" IS NOT NULL");
        builder.HasIndex(d => new { d.Token, d.GuestSessionId }).IsUnique().HasFilter("\"GuestSessionId\" IS NOT NULL");
        builder.HasIndex(d => d.Token);
    }
}

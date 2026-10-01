using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class UserBlockConfiguration : IEntityTypeConfiguration<UserBlock>
{
    public void Configure(EntityTypeBuilder<UserBlock> builder)
    {
        builder.HasKey(b => b.Id);
        builder.Property(b => b.BlockedDisplayName).IsRequired().HasMaxLength(120);

        builder.HasOne(b => b.BlockerUser).WithMany().HasForeignKey(b => b.BlockerUserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(b => b.BlockerGuestSession).WithMany().HasForeignKey(b => b.BlockerGuestSessionId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(b => b.BlockedUser).WithMany().HasForeignKey(b => b.BlockedUserId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(b => b.BlockedGuestSession).WithMany().HasForeignKey(b => b.BlockedGuestSessionId).OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(b => b.BlockerUserId);
        builder.HasIndex(b => b.BlockerGuestSessionId);
    }
}

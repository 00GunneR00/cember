using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class CircleConfiguration : IEntityTypeConfiguration<Circle>
{
    public void Configure(EntityTypeBuilder<Circle> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Name).IsRequired().HasMaxLength(200);
        builder.Property(c => c.Description).HasMaxLength(160);
        builder.Property(c => c.UploadMode).HasConversion<string>().HasMaxLength(20);
        builder.Property(c => c.RecapStatus).HasConversion<string>().HasMaxLength(20);
        builder.Property(c => c.RecapError).HasMaxLength(300);
        builder.HasIndex(c => c.RevealAt).HasFilter("\"RevealNotifiedAt\" IS NULL");
        builder.HasIndex(c => c.RecapStatus);

        builder.HasMany(c => c.InviteTokens)
            .WithOne(i => i.Circle)
            .HasForeignKey(i => i.CircleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.GuestSessions)
            .WithOne(g => g.Circle)
            .HasForeignKey(g => g.CircleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.Photos)
            .WithOne(p => p.Circle)
            .HasForeignKey(p => p.CircleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(c => c.DeletionVotes)
            .WithOne(v => v.Circle)
            .HasForeignKey(v => v.CircleId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

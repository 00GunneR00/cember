using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class ChallengeTemplateConfiguration : IEntityTypeConfiguration<ChallengeTemplate>
{
    public void Configure(EntityTypeBuilder<ChallengeTemplate> builder)
    {
        builder.HasKey(t => t.Id);
        builder.Property(t => t.Slug).IsRequired().HasMaxLength(80);
        builder.HasIndex(t => t.Slug).IsUnique();
        builder.Property(t => t.Title).IsRequired().HasMaxLength(80);
        builder.Property(t => t.Tagline).IsRequired().HasMaxLength(160);
        builder.Property(t => t.Description).IsRequired().HasMaxLength(600);
        builder.Property(t => t.Emoji).IsRequired().HasMaxLength(16);
        builder.Property(t => t.Category).HasConversion<string>().HasMaxLength(20);
        builder.Property(t => t.GradientStartHex).IsRequired().HasMaxLength(9);
        builder.Property(t => t.GradientEndHex).IsRequired().HasMaxLength(9);
        builder.Property(t => t.UploadMode).HasConversion<string>().HasMaxLength(20);
        builder.Property(t => t.CreatorName).HasMaxLength(80);
        builder.Property(t => t.CreatorHandle).HasMaxLength(60);

        builder.HasMany<Circle>()
            .WithOne(c => c.ChallengeTemplate)
            .HasForeignKey(c => c.ChallengeTemplateId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

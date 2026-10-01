using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class PhotoConfiguration : IEntityTypeConfiguration<Photo>
{
    public void Configure(EntityTypeBuilder<Photo> builder)
    {
        builder.HasKey(p => p.Id);
        builder.Property(p => p.OriginalKey).IsRequired();
        builder.Property(p => p.ThumbnailKey).IsRequired();
        builder.Property(p => p.ContentType).IsRequired().HasMaxLength(100);
        builder.Property(p => p.Source).HasConversion<string>().HasMaxLength(20);
        builder.Property(p => p.CommercialUseConsent).HasDefaultValue(false);
        builder.Ignore(p => p.UploaderDisplayName);

        builder.HasOne(p => p.UploadedByUser)
            .WithMany()
            .HasForeignKey(p => p.UploadedByUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.UploadedByGuestSession)
            .WithMany()
            .HasForeignKey(p => p.UploadedByGuestSessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Reactions)
            .WithOne(r => r.Photo)
            .HasForeignKey(r => r.PhotoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(p => p.Comments)
            .WithOne(c => c.Photo)
            .HasForeignKey(c => c.PhotoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => new { p.CircleId, p.CreatedAt });

        builder.ToTable(t => t.HasCheckConstraint(
            "CK_Photo_ExactlyOneUploader",
            "(\"UploadedByUserId\" IS NOT NULL) <> (\"UploadedByGuestSessionId\" IS NOT NULL)"));
    }
}

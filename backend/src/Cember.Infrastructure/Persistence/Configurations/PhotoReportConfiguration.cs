using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class PhotoReportConfiguration : IEntityTypeConfiguration<PhotoReport>
{
    public void Configure(EntityTypeBuilder<PhotoReport> builder)
    {
        builder.HasKey(r => r.Id);
        builder.Property(r => r.Reason).HasConversion<string>().HasMaxLength(20);
        builder.Property(r => r.Note).HasMaxLength(500);

        builder.HasOne(r => r.Photo)
            .WithMany(p => p.Reports)
            .HasForeignKey(r => r.PhotoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.ReporterUser)
            .WithMany()
            .HasForeignKey(r => r.ReporterUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.ReporterGuestSession)
            .WithMany()
            .HasForeignKey(r => r.ReporterGuestSessionId)
            .OnDelete(DeleteBehavior.Cascade);

        // One report per person per photo — reporting twice mustn't count twice towards auto-hiding.
        builder.HasIndex(r => new { r.PhotoId, r.ReporterUserId }).IsUnique().HasFilter("\"ReporterUserId\" IS NOT NULL");
        builder.HasIndex(r => new { r.PhotoId, r.ReporterGuestSessionId }).IsUnique().HasFilter("\"ReporterGuestSessionId\" IS NOT NULL");
        builder.HasIndex(r => r.ResolvedAt);
    }
}

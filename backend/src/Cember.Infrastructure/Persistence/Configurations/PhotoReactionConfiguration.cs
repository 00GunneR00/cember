using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class PhotoReactionConfiguration : IEntityTypeConfiguration<PhotoReaction>
{
    public void Configure(EntityTypeBuilder<PhotoReaction> builder)
    {
        builder.HasKey(r => r.Id);

        builder.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.GuestSession)
            .WithMany()
            .HasForeignKey(r => r.GuestSessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => new { r.PhotoId, r.UserId }).IsUnique().HasFilter("\"UserId\" IS NOT NULL");
        builder.HasIndex(r => new { r.PhotoId, r.GuestSessionId }).IsUnique().HasFilter("\"GuestSessionId\" IS NOT NULL");

        builder.ToTable(t => t.HasCheckConstraint(
            "CK_PhotoReaction_ExactlyOneAuthor",
            "(\"UserId\" IS NOT NULL) <> (\"GuestSessionId\" IS NOT NULL)"));
    }
}

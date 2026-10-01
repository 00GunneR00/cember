using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class CommentConfiguration : IEntityTypeConfiguration<Comment>
{
    public void Configure(EntityTypeBuilder<Comment> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.AuthorDisplayName).IsRequired().HasMaxLength(120);
        builder.Property(c => c.Body).IsRequired().HasMaxLength(2000);

        builder.HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.GuestSession)
            .WithMany()
            .HasForeignKey(c => c.GuestSessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => new { c.PhotoId, c.CreatedAt });

        builder.ToTable(t => t.HasCheckConstraint(
            "CK_Comment_ExactlyOneAuthor",
            "(\"UserId\" IS NOT NULL) <> (\"GuestSessionId\" IS NOT NULL)"));
    }
}

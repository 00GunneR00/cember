using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class GoogleLinkConfiguration : IEntityTypeConfiguration<GoogleLink>
{
    public void Configure(EntityTypeBuilder<GoogleLink> builder)
    {
        builder.HasKey(g => g.Id);
        builder.Property(g => g.GoogleSub).IsRequired();
        builder.Property(g => g.Email).IsRequired();
        builder.HasIndex(g => g.GoogleSub).IsUnique();

        builder.HasOne(g => g.User)
            .WithMany()
            .HasForeignKey(g => g.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

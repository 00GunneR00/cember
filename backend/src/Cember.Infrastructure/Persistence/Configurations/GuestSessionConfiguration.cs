using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class GuestSessionConfiguration : IEntityTypeConfiguration<GuestSession>
{
    public void Configure(EntityTypeBuilder<GuestSession> builder)
    {
        builder.HasKey(g => g.Id);
        builder.Property(g => g.DisplayName).IsRequired().HasMaxLength(120);
        builder.Property(g => g.SessionTokenHash).IsRequired();
        builder.HasIndex(g => g.SessionTokenHash).IsUnique();
    }
}

using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class InviteTokenConfiguration : IEntityTypeConfiguration<InviteToken>
{
    public void Configure(EntityTypeBuilder<InviteToken> builder)
    {
        builder.HasKey(i => i.Id);
        builder.Property(i => i.Token).IsRequired();
        builder.HasIndex(i => i.Token).IsUnique();

        builder.HasMany(i => i.GuestSessions)
            .WithOne(g => g.InviteToken)
            .HasForeignKey(g => g.InviteTokenId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}

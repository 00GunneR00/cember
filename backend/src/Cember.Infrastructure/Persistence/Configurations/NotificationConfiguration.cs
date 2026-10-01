using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.HasKey(n => n.Id);
        builder.Property(n => n.ActorDisplayName).IsRequired().HasMaxLength(120);
        builder.Property(n => n.Type).HasConversion<string>().HasMaxLength(40);

        builder.HasOne(n => n.RecipientUser)
            .WithMany()
            .HasForeignKey(n => n.RecipientUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(n => n.Circle)
            .WithMany()
            .HasForeignKey(n => n.CircleId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(n => new { n.RecipientUserId, n.CreatedAt });
        builder.HasIndex(n => new { n.RecipientUserId, n.IsRead });
    }
}

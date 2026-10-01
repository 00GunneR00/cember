using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Cember.Infrastructure.Persistence.Configurations;

public class CircleDeletionVoteConfiguration : IEntityTypeConfiguration<CircleDeletionVote>
{
    public void Configure(EntityTypeBuilder<CircleDeletionVote> builder)
    {
        builder.HasKey(v => v.Id);

        builder.HasOne(v => v.VoterUser)
            .WithMany()
            .HasForeignKey(v => v.VoterUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(v => v.VoterGuestSession)
            .WithMany()
            .HasForeignKey(v => v.VoterGuestSessionId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(v => new { v.CircleId, v.VoterUserId }).IsUnique().HasFilter("\"VoterUserId\" IS NOT NULL");
        builder.HasIndex(v => new { v.CircleId, v.VoterGuestSessionId }).IsUnique().HasFilter("\"VoterGuestSessionId\" IS NOT NULL");

        builder.ToTable(t => t.HasCheckConstraint(
            "CK_CircleDeletionVote_ExactlyOneVoter",
            "(\"VoterUserId\" IS NOT NULL) <> (\"VoterGuestSessionId\" IS NOT NULL)"));
    }
}

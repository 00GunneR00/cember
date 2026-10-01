using Cember.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Cember.Infrastructure.Persistence;

public class CemberDbContext(DbContextOptions<CemberDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Circle> Circles => Set<Circle>();
    public DbSet<InviteToken> InviteTokens => Set<InviteToken>();
    public DbSet<GuestSession> GuestSessions => Set<GuestSession>();
    public DbSet<Photo> Photos => Set<Photo>();
    public DbSet<PhotoReaction> PhotoReactions => Set<PhotoReaction>();
    public DbSet<Comment> Comments => Set<Comment>();
    public DbSet<CircleDeletionVote> CircleDeletionVotes => Set<CircleDeletionVote>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<GoogleLink> GoogleLinks => Set<GoogleLink>();
    public DbSet<ApiKey> ApiKeys => Set<ApiKey>();
    public DbSet<BrandProfile> BrandProfiles => Set<BrandProfile>();
    public DbSet<PhotoReport> PhotoReports => Set<PhotoReport>();
    public DbSet<UserBlock> UserBlocks => Set<UserBlock>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<ChallengeTemplate> ChallengeTemplates => Set<ChallengeTemplate>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CemberDbContext).Assembly);
    }
}

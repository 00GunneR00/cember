using Cember.Application.Common;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;

namespace Cember.Infrastructure.Services;

/// <summary>Per-viewer filtering: people the viewer blocked, and photos the viewer reported, disappear for them.</summary>
public static class VisibilityFilters
{
    public static IQueryable<UserBlock> BlocksBy(this CemberDbContext db, CurrentActor actor) => actor.IsHost
        ? db.UserBlocks.Where(b => b.BlockerUserId == actor.Id)
        : db.UserBlocks.Where(b => b.BlockerGuestSessionId == actor.Id);

    public static IQueryable<Photo> VisibleTo(this IQueryable<Photo> photos, CemberDbContext db, CurrentActor actor)
    {
        var blocks = db.BlocksBy(actor);
        photos = photos.Where(p => !blocks.Any(b =>
            (b.BlockedUserId != null && b.BlockedUserId == p.UploadedByUserId) ||
            (b.BlockedGuestSessionId != null && b.BlockedGuestSessionId == p.UploadedByGuestSessionId)));

        return actor.IsHost
            ? photos.Where(p => !p.Reports.Any(r => r.ReporterUserId == actor.Id))
            : photos.Where(p => !p.Reports.Any(r => r.ReporterGuestSessionId == actor.Id));
    }

    public static IQueryable<Comment> VisibleTo(this IQueryable<Comment> comments, CemberDbContext db, CurrentActor actor)
    {
        var blocks = db.BlocksBy(actor);
        return comments.Where(c => !blocks.Any(b =>
            (b.BlockedUserId != null && b.BlockedUserId == c.UserId) ||
            (b.BlockedGuestSessionId != null && b.BlockedGuestSessionId == c.GuestSessionId)));
    }
}

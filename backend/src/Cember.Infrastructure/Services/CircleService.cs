using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Cember.Infrastructure.Services;

public class CircleService(
    CemberDbContext db,
    IObjectStorageService storage,
    IImageProcessingService imaging,
    INotificationService notifications,
    ILogger<CircleService> logger) : ICircleService
{
    private const int PresignedUrlHours = 1;

    public async Task<CircleSummaryDto> CreateAsync(Guid ownerUserId, CreateCircleRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            throw new ValidationAppException("name gerekli.");
        }

        var now = DateTimeOffset.UtcNow;
        if (request.RevealAt is { } revealAt)
        {
            EnsureValidRevealTime(revealAt, now);
        }

        ChallengeTemplate? challenge = null;
        if (request.ChallengeTemplateId is { } challengeId)
        {
            challenge = await db.ChallengeTemplates.FirstOrDefaultAsync(t => t.Id == challengeId && t.IsActive, ct)
                ?? throw new ValidationAppException("Bu challenge artık mevcut değil.");
        }

        var circle = new Circle
        {
            Id = Guid.NewGuid(),
            RevealAt = request.RevealAt?.ToUniversalTime(),
            ChallengeTemplateId = challenge?.Id,
            ChallengeTemplate = challenge,
            Rules = CircleRules.Normalize(request.Rules ?? challenge?.Prompts),
            OwnerUserId = ownerUserId,
            Name = request.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim(),
            EventDate = request.EventDate,
            IsArchived = false,
            AutoPublish = true,
            AllowGuestDownloads = true,
            IsOpenJoin = request.IsOpenJoin,
            UploadMode = request.UploadMode ?? PhotoUploadMode.Both,
            CreatedAt = now,
        };

        db.Circles.Add(circle);
        await db.SaveChangesAsync(ct);

        return ToSummary(circle, photoCount: 0, participantCount: 0);
    }

    public async Task<CirclesOverviewDto> GetOverviewAsync(Guid ownerUserId, CancellationToken ct = default)
    {
        var circles = await db.Circles
            .Include(c => c.BrandProfile)
            .Where(c => c.OwnerUserId == ownerUserId)
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new
            {
                Circle = c,
                PhotoCount = c.Photos.Count,
                ParticipantCount = c.GuestSessions.Select(g => g.Id).Distinct().Count() + 1,
            })
            .ToListAsync(ct);

        var live = circles.Where(c => !c.Circle.IsArchived)
            .Select(c => ToSummary(c.Circle, c.PhotoCount, c.ParticipantCount)).ToList();
        var past = circles.Where(c => c.Circle.IsArchived)
            .Select(c => ToSummary(c.Circle, c.PhotoCount, c.ParticipantCount)).ToList();

        return new CirclesOverviewDto(live, past);
    }

    public async Task<DiscoverCirclesPageDto> DiscoverAsync(Guid viewerHostId, string? query, string? cursor, int pageSize, CancellationToken ct = default)
    {
        // Keşfet > Markalar lists brand-sponsored circles only; friends' open circles stay reachable by link
        // but are never listed publicly.
        var circlesQuery = db.Circles.Include(c => c.Owner).Include(c => c.BrandProfile)
            .Where(c => c.BrandProfileId != null && c.IsOpenJoin && !c.IsArchived && c.OwnerUserId != viewerHostId);

        if (!string.IsNullOrWhiteSpace(query))
        {
            var trimmed = query.Trim();
            circlesQuery = circlesQuery.Where(c => EF.Functions.ILike(c.Name, $"%{trimmed}%"));
        }

        if (cursor is not null && DateTimeOffset.TryParse(cursor, out var before))
        {
            circlesQuery = circlesQuery.Where(c => c.CreatedAt < before);
        }

        var rows = await circlesQuery
            .OrderByDescending(c => c.CreatedAt)
            .Take(pageSize + 1)
            .Select(c => new
            {
                Circle = c,
                PhotoCount = c.Photos.Count,
                ParticipantCount = c.GuestSessions.Select(g => g.Id).Distinct().Count() + 1,
            })
            .ToListAsync(ct);

        var hasMore = rows.Count > pageSize;
        var page = rows.Take(pageSize).ToList();

        var items = page.Select(r => new PublicCircleSummaryDto(
            Id: r.Circle.Id,
            Name: r.Circle.Name,
            EventDate: r.Circle.EventDate,
            HostDisplayName: r.Circle.Owner?.DisplayName ?? "",
            PhotoCount: r.PhotoCount,
            ParticipantCount: r.ParticipantCount,
            CoverUrl: r.Circle.CoverPhotoKey is null ? null : storage.GetPresignedUrl(r.Circle.CoverPhotoKey, TimeSpan.FromHours(PresignedUrlHours)),
            Description: r.Circle.Description,
            Brand: ToBrandDto(r.Circle.BrandProfile)
        )).ToList();

        var nextCursor = hasMore ? page[^1].Circle.CreatedAt.ToString("o") : null;
        return new DiscoverCirclesPageDto(items, nextCursor);
    }

    public async Task<CirclePreviewPhotosDto> GetPreviewPhotosAsync(Guid circleId, int limit, CancellationToken ct = default)
    {
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        if (!circle.IsOpenJoin || circle.IsArchived)
        {
            throw new ForbiddenAppException("Bu çemberin önizlemesi görüntülenemez.");
        }

        if (circle.IsDeveloping(DateTimeOffset.UtcNow))
        {
            return new CirclePreviewPhotosDto([]);
        }

        var thumbnailKeys = await db.Photos
            .Where(p => p.CircleId == circleId && p.IsPublished)
            .OrderByDescending(p => p.CreatedAt)
            .Take(limit)
            .Select(p => p.ThumbnailKey)
            .ToListAsync(ct);

        var urls = thumbnailKeys.Select(key => storage.GetPresignedUrl(key, TimeSpan.FromHours(PresignedUrlHours))).ToList();
        return new CirclePreviewPhotosDto(urls);
    }

    public async Task<CircleDetailDto> GetDetailAsync(Guid circleId, CurrentActor actor, CancellationToken ct = default)
    {
        var circle = await db.Circles.Include(c => c.Owner).Include(c => c.BrandProfile).Include(c => c.ChallengeTemplate)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        EnsureActorCanAccess(circle, actor);

        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circleId).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circleId && p.IsPublished, ct);
        var viewerIsHost = actor.IsHost && circle.OwnerUserId == actor.Id;
        var viewerUploadCount = circle.IsDeveloping(DateTimeOffset.UtcNow)
            ? await db.Photos.CountAsync(p => p.CircleId == circleId &&
                (actor.IsHost ? p.UploadedByUserId == actor.Id : p.UploadedByGuestSessionId == actor.Id), ct)
            : 0;

        return ToDetail(circle, viewerIsHost, participantCount, memoryCount, viewerUploadCount);
    }

    public async Task<CircleDetailDto> RequestRecapAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        if (circle.IsDeveloping(DateTimeOffset.UtcNow))
        {
            throw new ValidationAppException("Fotoğraflar banyodan çıkınca özet video hazırlanabilir.");
        }
        if (circle.RecapStatus is RecapStatus.Pending or RecapStatus.Processing)
        {
            throw new ValidationAppException("Özet video zaten hazırlanıyor.");
        }

        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circleId && p.IsPublished, ct);
        if (memoryCount < RecapLimits.MinPhotoCount)
        {
            throw new ValidationAppException($"Özet video için en az {RecapLimits.MinPhotoCount} fotoğraf gerekli.");
        }

        circle.RecapStatus = RecapStatus.Pending;
        circle.RecapError = null;
        await db.SaveChangesAsync(ct);

        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circleId).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        return ToDetail(circle, viewerIsHost: true, participantCount, memoryCount);
    }

    private static void EnsureValidRevealTime(DateTimeOffset revealAt, DateTimeOffset now)
    {
        if (revealAt <= now)
        {
            throw new ValidationAppException("Açılış zamanı ileride olmalı.");
        }
        if (revealAt - now > RecapLimits.MaxRevealDelay)
        {
            throw new ValidationAppException("Açılış zamanı en fazla 30 gün sonrası olabilir.");
        }
    }

    public async Task<CircleDetailDto> UpdateAsync(Guid circleId, Guid ownerUserId, UpdateCircleRequest request, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        if (request.Name is { } name && !string.IsNullOrWhiteSpace(name))
        {
            circle.Name = name.Trim();
        }
        if (request.Description is { } description)
        {
            circle.Description = string.IsNullOrWhiteSpace(description) ? null : description.Trim();
        }
        if (request.EventDate is { } eventDate)
        {
            circle.EventDate = eventDate;
        }
        if (request.IsArchived is { } archived)
        {
            circle.IsArchived = archived;
        }
        if (request.AutoPublish is { } autoPublish)
        {
            circle.AutoPublish = autoPublish;
        }
        if (request.AllowGuestDownloads is { } allowDownloads)
        {
            circle.AllowGuestDownloads = allowDownloads;
        }
        if (request.IsOpenJoin is { } isOpenJoin)
        {
            circle.IsOpenJoin = isOpenJoin;
        }
        if (request.Rules is { } rules)
        {
            circle.Rules = CircleRules.Normalize(rules);
        }

        var now = DateTimeOffset.UtcNow;
        if (request.RevealNow == true)
        {
            if (!circle.IsDeveloping(now))
            {
                throw new ValidationAppException("Bu çemberde banyoda bekleyen fotoğraf yok.");
            }
            // The background worker sees RevealAt <= now and sends the "anılar açıldı" notification.
            circle.RevealAt = now;
        }
        else if (request.RevealAt is { } revealAt)
        {
            EnsureValidRevealTime(revealAt, now);
            // Photos that everyone has already seen can't be put back in the darkroom.
            var hasVisiblePhotos = !circle.IsDeveloping(now) && await db.Photos.AnyAsync(p => p.CircleId == circleId, ct);
            if (hasVisiblePhotos)
            {
                throw new ValidationAppException("Fotoğraflar zaten görünür olduğu için banyo modu açılamaz.");
            }
            circle.RevealAt = revealAt.ToUniversalTime();
            circle.RevealNotifiedAt = null;
        }

        await db.SaveChangesAsync(ct);

        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circleId).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circleId && p.IsPublished, ct);
        return ToDetail(circle, viewerIsHost: true, participantCount, memoryCount);
    }

    public async Task<CircleDetailDto> SetCoverPhotoAsync(Guid circleId, Guid ownerUserId, UploadedFile file, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        if (!ImageContentTypes.Allowed.Contains(file.ContentType))
        {
            throw new ValidationAppException("Desteklenmeyen dosya türü.");
        }

        var processed = await imaging.ProcessAsync(file.Content, ct);
        var ext = ImageContentTypes.ExtensionFor(file.ContentType);
        var key = $"circles/{circleId}/cover/{Guid.NewGuid()}{ext}";
        await storage.PutObjectAsync(key, new MemoryStream(processed.Original), file.ContentType, ct);

        var previousKey = circle.CoverPhotoKey;
        circle.CoverPhotoKey = key;
        await db.SaveChangesAsync(ct);

        if (previousKey is not null)
        {
            await TryDeleteObjectAsync(previousKey, ct);
        }

        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circleId).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circleId && p.IsPublished, ct);
        return ToDetail(circle, viewerIsHost: true, participantCount, memoryCount);
    }

    public async Task<DeletionRequestStatusDto> RequestDeletionAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        var (eligibleUserIds, eligibleGuestIds) = await ComputeEligibleVotersAsync(circleId, ownerUserId, ct);
        var eligibleCount = eligibleUserIds.Count + eligibleGuestIds.Count;

        if (eligibleCount == 0)
        {
            await DeleteCircleAsync(circle, ct);
            return new DeletionRequestStatusDto(
                IsPending: false,
                RequestedByDisplayName: null,
                EligibleVoterCount: 0,
                RequiredApprovals: 0,
                CurrentApprovals: 0,
                ViewerIsEligible: false,
                ViewerVote: null,
                Deleted: true);
        }

        db.CircleDeletionVotes.RemoveRange(db.CircleDeletionVotes.Where(v => v.CircleId == circleId));
        circle.DeletionRequestedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        foreach (var voterId in eligibleUserIds)
        {
            await notifications.NotifyAsync(
                voterId,
                NotificationType.DeletionVoteNeeded,
                circleId,
                actorDisplayName: circle.Owner?.DisplayName ?? "",
                ct: ct);
        }

        return new DeletionRequestStatusDto(
            IsPending: true,
            RequestedByDisplayName: circle.Owner?.DisplayName,
            EligibleVoterCount: eligibleCount,
            RequiredApprovals: RequiredApprovals(eligibleCount),
            CurrentApprovals: 0,
            ViewerIsEligible: false,
            ViewerVote: null,
            Deleted: false);
    }

    public async Task<DeletionRequestStatusDto> GetDeletionStatusAsync(Guid circleId, CurrentActor actor, CancellationToken ct = default)
    {
        var circle = await db.Circles.Include(c => c.Owner)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        EnsureActorCanAccess(circle, actor);

        if (circle.DeletionRequestedAt is null)
        {
            return new DeletionRequestStatusDto(
                IsPending: false,
                RequestedByDisplayName: null,
                EligibleVoterCount: 0,
                RequiredApprovals: 0,
                CurrentApprovals: 0,
                ViewerIsEligible: false,
                ViewerVote: null,
                Deleted: false);
        }

        var (eligibleUserIds, eligibleGuestIds) = await ComputeEligibleVotersAsync(circleId, circle.OwnerUserId, ct);
        var eligibleCount = eligibleUserIds.Count + eligibleGuestIds.Count;
        var currentApprovals = await db.CircleDeletionVotes.CountAsync(v => v.CircleId == circleId && v.Approved, ct);
        var viewerIsEligible = actor.IsHost ? eligibleUserIds.Contains(actor.Id) : eligibleGuestIds.Contains(actor.Id);
        var viewerVote = await db.CircleDeletionVotes
            .Where(v => v.CircleId == circleId && (actor.IsHost ? v.VoterUserId == actor.Id : v.VoterGuestSessionId == actor.Id))
            .Select(v => (bool?)v.Approved)
            .FirstOrDefaultAsync(ct);

        return new DeletionRequestStatusDto(
            IsPending: true,
            RequestedByDisplayName: circle.Owner?.DisplayName,
            EligibleVoterCount: eligibleCount,
            RequiredApprovals: RequiredApprovals(eligibleCount),
            CurrentApprovals: currentApprovals,
            ViewerIsEligible: viewerIsEligible,
            ViewerVote: viewerVote,
            Deleted: false);
    }

    public async Task<DeletionRequestStatusDto> VoteOnDeletionAsync(Guid circleId, CurrentActor actor, bool approve, CancellationToken ct = default)
    {
        var circle = await db.Circles.Include(c => c.Owner)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        EnsureActorCanAccess(circle, actor);

        if (circle.DeletionRequestedAt is null)
        {
            throw new ValidationAppException("Bekleyen bir silme talebi yok.");
        }

        var (eligibleUserIds, eligibleGuestIds) = await ComputeEligibleVotersAsync(circleId, circle.OwnerUserId, ct);
        var viewerIsEligible = actor.IsHost ? eligibleUserIds.Contains(actor.Id) : eligibleGuestIds.Contains(actor.Id);
        if (!viewerIsEligible)
        {
            throw new ForbiddenAppException("Bu çemberde oy kullanma yetkiniz yok.");
        }

        var existing = await db.CircleDeletionVotes.FirstOrDefaultAsync(v =>
            v.CircleId == circleId &&
            (actor.IsHost ? v.VoterUserId == actor.Id : v.VoterGuestSessionId == actor.Id), ct);

        if (existing is not null)
        {
            existing.Approved = approve;
            existing.CreatedAt = DateTimeOffset.UtcNow;
        }
        else
        {
            db.CircleDeletionVotes.Add(new CircleDeletionVote
            {
                Id = Guid.NewGuid(),
                CircleId = circleId,
                VoterUserId = actor.IsHost ? actor.Id : null,
                VoterGuestSessionId = actor.IsGuest ? actor.Id : null,
                Approved = approve,
                CreatedAt = DateTimeOffset.UtcNow,
            });
        }
        await db.SaveChangesAsync(ct);

        var eligibleCount = eligibleUserIds.Count + eligibleGuestIds.Count;
        var requiredApprovals = RequiredApprovals(eligibleCount);
        var currentApprovals = await db.CircleDeletionVotes.CountAsync(v => v.CircleId == circleId && v.Approved, ct);

        if (currentApprovals >= requiredApprovals)
        {
            await DeleteCircleAsync(circle, ct);
            return new DeletionRequestStatusDto(
                IsPending: false,
                RequestedByDisplayName: null,
                EligibleVoterCount: eligibleCount,
                RequiredApprovals: requiredApprovals,
                CurrentApprovals: currentApprovals,
                ViewerIsEligible: true,
                ViewerVote: approve,
                Deleted: true);
        }

        return new DeletionRequestStatusDto(
            IsPending: true,
            RequestedByDisplayName: circle.Owner?.DisplayName,
            EligibleVoterCount: eligibleCount,
            RequiredApprovals: requiredApprovals,
            CurrentApprovals: currentApprovals,
            ViewerIsEligible: true,
            ViewerVote: approve,
            Deleted: false);
    }

    public async Task CancelDeletionRequestAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);
        circle.DeletionRequestedAt = null;
        db.CircleDeletionVotes.RemoveRange(db.CircleDeletionVotes.Where(v => v.CircleId == circleId));
        await db.SaveChangesAsync(ct);
    }

    internal static void EnsureActorCanAccess(Circle circle, CurrentActor actor)
    {
        var allowed = actor.IsHost && circle.OwnerUserId == actor.Id;
        allowed |= actor.IsGuest && actor.GuestCircleId == circle.Id;
        allowed |= actor.IsAdmin;
        if (!allowed)
        {
            throw new ForbiddenAppException("Bu çembere erişiminiz yok.");
        }
    }

    private static int RequiredApprovals(int eligibleVoterCount) => eligibleVoterCount == 0 ? 0 : (eligibleVoterCount / 2) + 1;

    private async Task<(HashSet<Guid> UserIds, HashSet<Guid> GuestIds)> ComputeEligibleVotersAsync(Guid circleId, Guid ownerUserId, CancellationToken ct)
    {
        var interactorUserIds = await db.Photos.Where(p => p.CircleId == circleId && p.UploadedByUserId != null).Select(p => p.UploadedByUserId!.Value)
            .Union(db.Comments.Where(c => c.Photo!.CircleId == circleId && c.UserId != null).Select(c => c.UserId!.Value))
            .Union(db.PhotoReactions.Where(r => r.Photo!.CircleId == circleId && r.UserId != null).Select(r => r.UserId!.Value))
            .Distinct()
            .ToListAsync(ct);

        var interactorGuestIds = await db.Photos.Where(p => p.CircleId == circleId && p.UploadedByGuestSessionId != null).Select(p => p.UploadedByGuestSessionId!.Value)
            .Union(db.Comments.Where(c => c.Photo!.CircleId == circleId && c.GuestSessionId != null).Select(c => c.GuestSessionId!.Value))
            .Union(db.PhotoReactions.Where(r => r.Photo!.CircleId == circleId && r.GuestSessionId != null).Select(r => r.GuestSessionId!.Value))
            .Distinct()
            .ToListAsync(ct);

        var userIds = interactorUserIds.Where(id => id != ownerUserId).ToHashSet();
        var guestIds = interactorGuestIds.ToHashSet();
        return (userIds, guestIds);
    }

    private async Task DeleteCircleAsync(Circle circle, CancellationToken ct)
    {
        var keys = await db.Photos.Where(p => p.CircleId == circle.Id)
            .Select(p => new { p.OriginalKey, p.ThumbnailKey })
            .ToListAsync(ct);
        var coverKey = circle.CoverPhotoKey;
        var recapKey = circle.RecapKey;

        db.Circles.Remove(circle);
        await db.SaveChangesAsync(ct);

        foreach (var key in keys)
        {
            await TryDeleteObjectAsync(key.OriginalKey, ct);
            await TryDeleteObjectAsync(key.ThumbnailKey, ct);
        }
        if (coverKey is not null)
        {
            await TryDeleteObjectAsync(coverKey, ct);
        }
        if (recapKey is not null)
        {
            await TryDeleteObjectAsync(recapKey, ct);
        }
    }

    private async Task TryDeleteObjectAsync(string key, CancellationToken ct)
    {
        try
        {
            await storage.DeleteObjectAsync(key, ct);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Çember silinirken depolama nesnesi silinemedi: {Key}", key);
        }
    }

    private async Task<Circle> GetOwnedCircleAsync(Guid circleId, Guid ownerUserId, CancellationToken ct)
    {
        var circle = await db.Circles.Include(c => c.Owner).Include(c => c.BrandProfile).Include(c => c.ChallengeTemplate)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        if (circle.OwnerUserId != ownerUserId)
        {
            throw new ForbiddenAppException("Bu çemberin sahibi değilsiniz.");
        }
        return circle;
    }

    public async Task<CircleDetailDto> AssignBrandAsync(Guid circleId, Guid? brandProfileId, CancellationToken ct = default)
    {
        var circle = await db.Circles.Include(c => c.Owner).Include(c => c.BrandProfile)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        if (brandProfileId is { } id)
        {
            var brand = await db.BrandProfiles.FirstOrDefaultAsync(b => b.Id == id, ct)
                ?? throw new NotFoundAppException("Marka profili bulunamadı.");
            circle.BrandProfileId = brand.Id;
            circle.BrandProfile = brand;
        }
        else
        {
            circle.BrandProfileId = null;
            circle.BrandProfile = null;
        }

        await db.SaveChangesAsync(ct);

        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circleId).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circleId && p.IsPublished, ct);
        return ToDetail(circle, viewerIsHost: false, participantCount, memoryCount);
    }

    public async Task<IReadOnlyList<AdminCircleSummaryDto>> ListAllForAdminAsync(CancellationToken ct = default)
    {
        var circles = await db.Circles.Include(c => c.Owner).Include(c => c.BrandProfile)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(ct);

        return circles.Select(c => new AdminCircleSummaryDto(
            Id: c.Id,
            Name: c.Name,
            EventDate: c.EventDate,
            HostDisplayName: c.Owner?.DisplayName ?? "",
            IsArchived: c.IsArchived,
            Brand: ToBrandDto(c.BrandProfile)
        )).ToList();
    }

    private CircleSummaryDto ToSummary(Circle circle, int photoCount, int participantCount) => new(
        Id: circle.Id,
        Name: circle.Name,
        EventDate: circle.EventDate,
        IsArchived: circle.IsArchived,
        IsOpenJoin: circle.IsOpenJoin,
        PhotoCount: photoCount,
        ParticipantCount: participantCount,
        CoverUrl: circle.CoverPhotoKey is null ? null : storage.GetPresignedUrl(circle.CoverPhotoKey, TimeSpan.FromHours(PresignedUrlHours)),
        Description: circle.Description,
        UploadMode: circle.UploadMode,
        Brand: ToBrandDto(circle.BrandProfile),
        RevealAt: circle.RevealAt,
        IsDeveloping: circle.IsDeveloping(DateTimeOffset.UtcNow)
    );

    private CircleDetailDto ToDetail(Circle circle, bool viewerIsHost, int participantCount, int memoryCount, int viewerUploadCount = 0) => new(
        Id: circle.Id,
        Name: circle.Name,
        EventDate: circle.EventDate,
        ParticipantCount: participantCount,
        MemoryCount: memoryCount,
        IsOpenJoin: circle.IsOpenJoin,
        AutoPublish: circle.AutoPublish,
        AllowGuestDownloads: circle.AllowGuestDownloads,
        ViewerIsHost: viewerIsHost,
        HostDisplayName: circle.Owner?.DisplayName ?? "",
        CoverUrl: circle.CoverPhotoKey is null ? null : storage.GetPresignedUrl(circle.CoverPhotoKey, TimeSpan.FromHours(PresignedUrlHours)),
        Description: circle.Description,
        UploadMode: circle.UploadMode,
        Brand: ToBrandDto(circle.BrandProfile),
        RevealAt: circle.RevealAt,
        IsDeveloping: circle.IsDeveloping(DateTimeOffset.UtcNow),
        ViewerUploadCount: viewerUploadCount,
        RecapStatus: circle.RecapStatus,
        RecapUrl: circle.RecapStatus == RecapStatus.Ready && circle.RecapKey is not null
            ? storage.GetPresignedUrl(circle.RecapKey, TimeSpan.FromHours(PresignedUrlHours))
            : null,
        RecapError: circle.RecapStatus == RecapStatus.Failed ? circle.RecapError : null,
        Challenge: circle.ChallengeTemplate is { } t
            ? new CircleChallengeDto(t.Id, t.Title, t.Emoji, t.Prompts, t.CreatorName, t.CreatorHandle, t.CreatorVerified)
            : null,
        Rules: circle.Rules
    );

    private BrandProfileDto? ToBrandDto(BrandProfile? brand) => brand is null ? null : new BrandProfileDto(
        Id: brand.Id,
        Name: brand.Name,
        LogoUrl: brand.LogoKey is null ? null : storage.GetPresignedUrl(brand.LogoKey, TimeSpan.FromHours(PresignedUrlHours)),
        PrimaryColorHex: brand.PrimaryColorHex,
        SecondaryColorHex: brand.SecondaryColorHex
    );
}

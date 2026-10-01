using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Cember.Infrastructure.Services;

public class InviteService(
    CemberDbContext db,
    IObjectStorageService storage,
    INotificationService notifications,
    IConfiguration configuration) : IInviteService
{
    private string BaseUrl => configuration["App:InviteBaseUrl"] ?? "https://cember.app/join";

    public async Task<InviteDto> RotateAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        var existing = await db.InviteTokens.Where(i => i.CircleId == circleId && i.RevokedAt == null).ToListAsync(ct);
        foreach (var old in existing)
        {
            old.RevokedAt = DateTimeOffset.UtcNow;
        }

        var invite = new InviteToken
        {
            Id = Guid.NewGuid(),
            CircleId = circleId,
            Token = SecretTokens.GenerateOpaqueToken(),
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.InviteTokens.Add(invite);
        await db.SaveChangesAsync(ct);

        return await BuildInviteDtoAsync(circle, invite, ct);
    }

    public async Task<InviteDto> GetCurrentAsync(Guid circleId, Guid ownerUserId, CancellationToken ct = default)
    {
        var circle = await GetOwnedCircleAsync(circleId, ownerUserId, ct);

        var invite = await db.InviteTokens
            .Where(i => i.CircleId == circleId && i.RevokedAt == null)
            .OrderByDescending(i => i.CreatedAt)
            .FirstOrDefaultAsync(ct);

        invite ??= await CreateFirstInviteAsync(circleId, ct);

        return await BuildInviteDtoAsync(circle, invite, ct);
    }

    public async Task<InvitePreviewDto> GetPreviewAsync(string token, CancellationToken ct = default)
    {
        var invite = await db.InviteTokens.Include(i => i.Circle).ThenInclude(c => c!.Owner)
            .FirstOrDefaultAsync(i => i.Token == token && i.RevokedAt == null, ct)
            ?? throw new NotFoundAppException("Davet linki geçersiz veya iptal edilmiş.");

        var circle = invite.Circle!;
        return new InvitePreviewDto(
            CircleName: circle.Name,
            EventDate: circle.EventDate,
            CoverUrl: circle.CoverPhotoKey is null ? null : storage.GetPresignedUrl(circle.CoverPhotoKey, TimeSpan.FromHours(1)),
            HostDisplayName: circle.Owner?.DisplayName ?? ""
        );
    }

    public async Task<JoinInviteResponse> JoinAsync(string token, JoinInviteRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            throw new ValidationAppException("displayName gerekli.");
        }

        var invite = await db.InviteTokens.Include(i => i.Circle).ThenInclude(c => c!.Owner)
            .FirstOrDefaultAsync(i => i.Token == token && i.RevokedAt == null, ct)
            ?? throw new NotFoundAppException("Davet linki geçersiz veya iptal edilmiş.");

        return await CreateGuestSessionAsync(invite, request.DisplayName.Trim(), ct);
    }

    public async Task<JoinInviteResponse> JoinOpenCircleAsync(Guid circleId, CurrentActor hostActor, CancellationToken ct = default)
    {
        var circle = await db.Circles.Include(c => c.Owner)
            .FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");

        if (circle.OwnerUserId == hostActor.Id)
        {
            throw new ValidationAppException("Kendi çemberinize bu şekilde katılamazsınız.");
        }
        if (!circle.IsOpenJoin || circle.IsArchived)
        {
            throw new ForbiddenAppException("Bu çember katılıma açık değil.");
        }

        var invite = await db.InviteTokens.Where(i => i.CircleId == circleId && i.RevokedAt == null)
            .OrderByDescending(i => i.CreatedAt)
            .FirstOrDefaultAsync(ct);
        if (invite is null)
        {
            invite = new InviteToken
            {
                Id = Guid.NewGuid(),
                CircleId = circleId,
                Token = SecretTokens.GenerateOpaqueToken(),
                CreatedAt = DateTimeOffset.UtcNow,
            };
            db.InviteTokens.Add(invite);
            await db.SaveChangesAsync(ct);
        }
        invite.Circle = circle;

        return await CreateGuestSessionAsync(invite, hostActor.DisplayName, ct);
    }

    private async Task<JoinInviteResponse> CreateGuestSessionAsync(InviteToken invite, string displayName, CancellationToken ct)
    {
        var sessionToken = SecretTokens.GenerateOpaqueToken();
        var session = new GuestSession
        {
            Id = Guid.NewGuid(),
            CircleId = invite.CircleId,
            InviteTokenId = invite.Id,
            DisplayName = displayName,
            SessionTokenHash = SecretTokens.Hash(sessionToken),
            CreatedAt = DateTimeOffset.UtcNow,
            LastSeenAt = DateTimeOffset.UtcNow,
        };
        db.GuestSessions.Add(session);
        await db.SaveChangesAsync(ct);

        var circle = invite.Circle!;
        var participantCount = await db.GuestSessions.Where(g => g.CircleId == circle.Id).Select(g => g.Id).Distinct().CountAsync(ct) + 1;
        var memoryCount = await db.Photos.CountAsync(p => p.CircleId == circle.Id && p.IsPublished, ct);

        var detail = new CircleDetailDto(
            Id: circle.Id,
            Name: circle.Name,
            EventDate: circle.EventDate,
            ParticipantCount: participantCount,
            MemoryCount: memoryCount,
            IsOpenJoin: circle.IsOpenJoin,
            AutoPublish: circle.AutoPublish,
            AllowGuestDownloads: circle.AllowGuestDownloads,
            ViewerIsHost: false,
            HostDisplayName: circle.Owner?.DisplayName ?? "",
            CoverUrl: circle.CoverPhotoKey is null ? null : storage.GetPresignedUrl(circle.CoverPhotoKey, TimeSpan.FromHours(1)),
            Description: circle.Description,
            UploadMode: circle.UploadMode
        );

        await notifications.NotifyAsync(circle.OwnerUserId, NotificationType.GuestJoined, circle.Id, displayName, ct: ct);

        return new JoinInviteResponse(sessionToken, detail);
    }

    private async Task<Circle> GetOwnedCircleAsync(Guid circleId, Guid ownerUserId, CancellationToken ct)
    {
        var circle = await db.Circles.FirstOrDefaultAsync(c => c.Id == circleId, ct)
            ?? throw new NotFoundAppException("Çember bulunamadı.");
        if (circle.OwnerUserId != ownerUserId)
        {
            throw new ForbiddenAppException("Bu çemberin sahibi değilsiniz.");
        }
        return circle;
    }

    private async Task<InviteToken> CreateFirstInviteAsync(Guid circleId, CancellationToken ct)
    {
        var invite = new InviteToken
        {
            Id = Guid.NewGuid(),
            CircleId = circleId,
            Token = SecretTokens.GenerateOpaqueToken(),
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.InviteTokens.Add(invite);
        await db.SaveChangesAsync(ct);
        return invite;
    }

    private async Task<InviteDto> BuildInviteDtoAsync(Circle circle, InviteToken invite, CancellationToken ct)
    {
        var connectedGuestCount = await db.GuestSessions.Where(g => g.InviteTokenId == invite.Id).Select(g => g.Id).Distinct().CountAsync(ct);
        var sharedMemoryCount = await db.Photos.CountAsync(p => p.CircleId == circle.Id, ct);

        return new InviteDto(
            Token: invite.Token,
            InviteUrl: $"{BaseUrl}/{invite.Token}",
            ConnectedGuestCount: connectedGuestCount,
            SharedMemoryCount: sharedMemoryCount,
            AutoPublish: circle.AutoPublish,
            AllowGuestDownloads: circle.AllowGuestDownloads
        );
    }
}

using Cember.Application.Common;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Media;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Push;
using Microsoft.EntityFrameworkCore;

namespace Cember.Api.Workers;

/// <summary>
/// Two periodic jobs: announces Banyo circles whose reveal time has come (and queues their recap video),
/// then renders queued recap videos one at a time so a burst of requests can't overload the server.
/// </summary>
public class RevealAndRecapWorker(IServiceScopeFactory scopes, ILogger<RevealAndRecapWorker> logger) : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(15);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await RequeueInterruptedRendersAsync(stoppingToken);

        using var timer = new PeriodicTimer(PollInterval);
        do
        {
            try
            {
                await AnnounceRevealsAsync(stoppingToken);
                await RenderNextRecapAsync(stoppingToken);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogError(ex, "Banyo/özet video işçisi bir turda hata verdi.");
            }
        } while (await timer.WaitForNextTickAsync(stoppingToken));
    }

    /// A render cut off by a restart would otherwise sit in Processing forever.
    private async Task RequeueInterruptedRendersAsync(CancellationToken ct)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<CemberDbContext>();
        await db.Circles
            .Where(c => c.RecapStatus == RecapStatus.Processing)
            .ExecuteUpdateAsync(s => s.SetProperty(c => c.RecapStatus, RecapStatus.Pending), ct);
    }

    private async Task AnnounceRevealsAsync(CancellationToken ct)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<CemberDbContext>();
        var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var push = scope.ServiceProvider.GetRequiredService<IPushService>();

        var now = DateTimeOffset.UtcNow;
        var due = await db.Circles
            .Where(c => c.RevealAt != null && c.RevealAt <= now && c.RevealNotifiedAt == null)
            .ToListAsync(ct);

        foreach (var circle in due)
        {
            circle.RevealNotifiedAt = now;
            var photoCount = await db.Photos.CountAsync(p => p.CircleId == circle.Id && p.IsPublished, ct);
            if (photoCount >= RecapLimits.MinPhotoCount && circle.RecapStatus == RecapStatus.None)
            {
                circle.RecapStatus = RecapStatus.Pending;
            }
            await db.SaveChangesAsync(ct);

            if (photoCount > 0)
            {
                await notifications.NotifyAsync(circle.OwnerUserId, NotificationType.PhotosRevealed, circle.Id, "Çember",
                    preview: $"{photoCount} kare banyodan çıktı", ct: ct);
                // The owner is pushed via their in-app notification above; this reaches the guests.
                push.QueueToCircle(circle.Id, PushMessages.PhotosRevealed(circle.Id, circle.Name, photoCount), includeOwner: false);
            }
        }
    }

    private async Task RenderNextRecapAsync(CancellationToken ct)
    {
        using var scope = scopes.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<CemberDbContext>();

        var circle = await db.Circles
            .Where(c => c.RecapStatus == RecapStatus.Pending)
            .OrderBy(c => c.CreatedAt)
            .FirstOrDefaultAsync(ct);
        if (circle is null) return;

        circle.RecapStatus = RecapStatus.Processing;
        await db.SaveChangesAsync(ct);

        var renderer = scope.ServiceProvider.GetRequiredService<RecapVideoRenderer>();
        var storage = scope.ServiceProvider.GetRequiredService<IObjectStorageService>();
        var notifications = scope.ServiceProvider.GetRequiredService<INotificationService>();
        var push = scope.ServiceProvider.GetRequiredService<IPushService>();

        try
        {
            var key = await renderer.RenderAsync(circle, ct);
            var previousKey = circle.RecapKey;

            circle.RecapKey = key;
            circle.RecapStatus = RecapStatus.Ready;
            circle.RecapError = null;
            circle.RecapGeneratedAt = DateTimeOffset.UtcNow;
            await db.SaveChangesAsync(ct);

            if (previousKey is not null)
            {
                try
                {
                    await storage.DeleteObjectAsync(previousKey, ct);
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Eski özet video silinemedi: {Key}", previousKey);
                }
            }

            await notifications.NotifyAsync(circle.OwnerUserId, NotificationType.RecapReady, circle.Id, "Çember",
                preview: "Özet videon hazır", ct: ct);
            push.QueueToCircle(circle.Id, PushMessages.RecapReadyForCircle(circle.Id, circle.Name), includeOwner: false);
        }
        catch (Exception ex) when (!ct.IsCancellationRequested)
        {
            logger.LogError(ex, "Özet video hazırlanamadı: {CircleId}", circle.Id);
            circle.RecapStatus = RecapStatus.Failed;
            circle.RecapError = ex is RecapRenderException ? ex.Message : "Özet video hazırlanırken bir hata oluştu.";
            await db.SaveChangesAsync(CancellationToken.None);
        }
    }
}

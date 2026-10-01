using Cember.Infrastructure.Push;

namespace Cember.Api.Workers;

/// <summary>Drains the push queue in the background so sending never slows down an API request.</summary>
public class PushDispatchWorker(PushQueue queue, IServiceScopeFactory scopes, ILogger<PushDispatchWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await foreach (var push in queue.ReadAllAsync(stoppingToken))
        {
            try
            {
                using var scope = scopes.CreateScope();
                await scope.ServiceProvider.GetRequiredService<PushDispatcher>().DispatchAsync(push, stoppingToken);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogWarning(ex, "Push bildirimi gönderilemedi.");
            }
        }
    }
}

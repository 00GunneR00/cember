using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Cember.Application.Interfaces;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Cember.Infrastructure.Push;

public enum PushSendResult
{
    Sent,
    /// <summary>The token no longer belongs to an installed app — it should be forgotten.</summary>
    InvalidToken,
    Failed,
}

/// <summary>
/// Firebase project + service-account credential, loaded once (singleton) so the OAuth access token it
/// caches is reused across pushes. Without <c>Firebase:ProjectId</c> and <c>Firebase:ServiceAccountPath</c>
/// configured, push stays disabled.
/// </summary>
public class FcmConfig
{
    public FcmConfig(IConfiguration configuration, ILogger<FcmConfig> logger)
    {
        ProjectId = configuration["Firebase:ProjectId"];
        var serviceAccountPath = configuration["Firebase:ServiceAccountPath"];

        if (string.IsNullOrWhiteSpace(ProjectId) || string.IsNullOrWhiteSpace(serviceAccountPath))
        {
            logger.LogInformation("Firebase ayarlanmadı; push bildirimleri kapalı.");
            return;
        }
        if (!File.Exists(serviceAccountPath))
        {
            logger.LogWarning("Firebase servis hesabı dosyası bulunamadı: {Path}; push bildirimleri kapalı.", serviceAccountPath);
            return;
        }

#pragma warning disable CS0618 // FromFile is flagged for untrusted input; this path comes from our own server config.
        Credential = GoogleCredential.FromFile(serviceAccountPath)
            .CreateScoped("https://www.googleapis.com/auth/firebase.messaging");
#pragma warning restore CS0618
    }

    public string? ProjectId { get; }

    public ITokenAccess? Credential { get; }

    public bool IsEnabled => Credential is not null;
}

/// <summary>Delivers one push to one device. The seam that lets the dispatcher be tested without FCM.</summary>
public interface IPushTransport
{
    bool IsEnabled { get; }

    Task<PushSendResult> SendAsync(string deviceToken, PushContent content, CancellationToken ct);
}

/// <summary>Sends through Firebase Cloud Messaging's HTTP v1 API.</summary>
public class FcmSender(HttpClient http, FcmConfig config, ILogger<FcmSender> logger) : IPushTransport
{
    public bool IsEnabled => config.IsEnabled;

    public async Task<PushSendResult> SendAsync(string deviceToken, PushContent content, CancellationToken ct)
    {
        if (config.Credential is null) return PushSendResult.Failed;

        var accessToken = await config.Credential.GetAccessTokenForRequestAsync(cancellationToken: ct);
        using var request = new HttpRequestMessage(HttpMethod.Post, $"https://fcm.googleapis.com/v1/projects/{config.ProjectId}/messages:send")
        {
            Content = JsonContent.Create(new
            {
                message = new
                {
                    token = deviceToken,
                    notification = new { title = content.Title, body = content.Body },
                    data = content.Data,
                    android = new { priority = "high" },
                },
            }),
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

        using var response = await http.SendAsync(request, ct);
        if (response.IsSuccessStatusCode) return PushSendResult.Sent;

        var body = await response.Content.ReadAsStringAsync(ct);
        // FCM answers 404 UNREGISTERED for uninstalled apps, 400 INVALID_ARGUMENT for malformed tokens.
        if (response.StatusCode == HttpStatusCode.NotFound || body.Contains("UNREGISTERED") ||
            (response.StatusCode == HttpStatusCode.BadRequest && body.Contains("registration token")))
        {
            return PushSendResult.InvalidToken;
        }

        logger.LogWarning("FCM gönderimi başarısız ({Status}): {Body}", (int)response.StatusCode, body);
        return PushSendResult.Failed;
    }
}

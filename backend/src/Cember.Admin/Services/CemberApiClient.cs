using System.Net.Http.Headers;
using System.Text.Json;

namespace Cember.Admin.Services;

/// <summary>
/// The only class in this project that talks to Cember.Api. Every admin page goes through here
/// instead of holding its own HttpClient, so the API contract lives in one place.
/// </summary>
public sealed class CemberApiClient(IHttpClientFactory httpClientFactory)
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private HttpClient Client => httpClientFactory.CreateClient("CemberApi");

    public async Task<GoogleSignInResult?> SignInWithGoogleAsync(string idToken, CancellationToken ct)
    {
        var response = await Client.PostAsJsonAsync("api/v1/auth/google", new { idToken }, JsonOptions, ct);
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        return await response.Content.ReadFromJsonAsync<GoogleSignInResult>(JsonOptions, ct);
    }

    public async Task<IReadOnlyList<BrandProfile>> ListBrandProfilesAsync(string token, CancellationToken ct)
    {
        using var request = Authorized(HttpMethod.Get, "api/v1/admin/brand-profiles", token);
        var response = await Client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<BrandProfile>>(JsonOptions, ct) ?? [];
    }

    public async Task<BrandProfile?> CreateBrandProfileAsync(
        string token,
        string name,
        string primaryColorHex,
        string? secondaryColorHex,
        IFormFile? logo,
        CancellationToken ct)
    {
        using var content = new MultipartFormDataContent
        {
            { new StringContent(name), "name" },
            { new StringContent(primaryColorHex), "primaryColorHex" },
        };

        if (!string.IsNullOrWhiteSpace(secondaryColorHex))
        {
            content.Add(new StringContent(secondaryColorHex), "secondaryColorHex");
        }

        if (logo is { Length: > 0 })
        {
            var streamContent = new StreamContent(logo.OpenReadStream());
            streamContent.Headers.ContentType = new MediaTypeHeaderValue(logo.ContentType);
            content.Add(streamContent, "logo", logo.FileName);
        }

        using var request = Authorized(HttpMethod.Post, "api/v1/admin/brand-profiles", token);
        request.Content = content;
        var response = await Client.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        return await response.Content.ReadFromJsonAsync<BrandProfile>(JsonOptions, ct);
    }

    public async Task<bool> AssignBrandAsync(string token, Guid circleId, Guid? brandProfileId, CancellationToken ct)
    {
        using var request = Authorized(HttpMethod.Patch, $"api/v1/admin/circles/{circleId}/brand", token);
        request.Content = JsonContent.Create(new { brandProfileId }, options: JsonOptions);
        var response = await Client.SendAsync(request, ct);
        return response.IsSuccessStatusCode;
    }

    public async Task<IReadOnlyList<AdminCircleSummary>> ListCirclesAsync(string token, CancellationToken ct)
    {
        using var request = Authorized(HttpMethod.Get, "api/v1/admin/circles", token);
        var response = await Client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<AdminCircleSummary>>(JsonOptions, ct) ?? [];
    }

    public async Task<IReadOnlyList<ReportedPhoto>> ListOpenReportsAsync(string token, CancellationToken ct)
    {
        using var request = Authorized(HttpMethod.Get, "api/v1/admin/reports", token);
        var response = await Client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<List<ReportedPhoto>>(JsonOptions, ct) ?? [];
    }

    public async Task<bool> ResolveReportsAsync(string token, Guid photoId, bool removePhoto, CancellationToken ct)
    {
        using var request = Authorized(HttpMethod.Post, $"api/v1/admin/reports/{photoId}/resolve", token);
        request.Content = JsonContent.Create(new { removePhoto }, options: JsonOptions);
        var response = await Client.SendAsync(request, ct);
        return response.IsSuccessStatusCode;
    }

    /// <summary>
    /// Opens the upstream export.zip response so the caller can stream it straight back to the
    /// browser — the admin's bearer token never has to leave the server.
    /// </summary>
    public Task<HttpResponseMessage> OpenExportStreamAsync(string token, Guid circleId, CancellationToken ct)
    {
        var request = Authorized(HttpMethod.Get, $"api/v1/circles/{circleId}/export.zip", token);
        return Client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
    }

    private static HttpRequestMessage Authorized(HttpMethod method, string url, string token)
    {
        var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return request;
    }
}

public sealed record GoogleSignInResult(Guid UserId, string ApiKey, bool IsAdmin);

public sealed record BrandProfile(Guid Id, string Name, string? LogoUrl, string PrimaryColorHex, string? SecondaryColorHex);

public sealed record AdminCircleSummary(Guid Id, string Name, DateOnly? EventDate, string HostDisplayName, bool IsArchived, BrandProfile? Brand);

public sealed record ReportedPhoto(
    Guid PhotoId,
    Guid CircleId,
    string CircleName,
    string UploaderDisplayName,
    string ThumbnailUrl,
    int ReportCount,
    List<string> Reasons,
    List<string> Notes,
    bool IsHidden,
    DateTimeOffset FirstReportedAt);

using Cember.Admin.Services;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Login";
        options.AccessDeniedPath = "/Login";
        options.ExpireTimeSpan = TimeSpan.FromHours(12);
        options.SlidingExpiration = true;
    });

builder.Services.AddAuthorization();

builder.Services.AddHttpClient("CemberApi", client =>
{
    var baseUrl = builder.Configuration["CemberApi:BaseUrl"] ?? "http://localhost:5080";
    client.BaseAddress = new Uri(baseUrl);
});

builder.Services.AddScoped<CemberApiClient>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseStaticFiles();
app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapRazorPages();

// Proxies the zip export through the admin's own session so the bearer token never reaches the browser.
app.MapGet("/circles/{id:guid}/export", async (Guid id, HttpContext http, CemberApiClient api, CancellationToken ct) =>
{
    var token = http.User.FindFirst("cember_token")?.Value;
    if (string.IsNullOrEmpty(token))
    {
        return Results.Unauthorized();
    }

    var upstream = await api.OpenExportStreamAsync(token, id, ct);
    if (!upstream.IsSuccessStatusCode)
    {
        return Results.StatusCode((int)upstream.StatusCode);
    }

    var stream = await upstream.Content.ReadAsStreamAsync(ct);
    return Results.File(stream, "application/zip", $"cember-{id}.zip");
}).RequireAuthorization();

app.Run();

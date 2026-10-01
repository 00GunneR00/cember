using System.Text.Json.Serialization;
using Cember.Api.Auth;
using Cember.Api.Middleware;
using Cember.Api.Workers;
using Cember.Infrastructure;
using Cember.Infrastructure.Challenges;
using Cember.Infrastructure.Imaging;
using Cember.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddOpenApi();

builder.Services.AddCemberInfrastructure(builder.Configuration);
builder.Services.AddHostedService<RevealAndRecapWorker>();
builder.Services.AddHostedService<PushDispatchWorker>();

builder.Services.AddAuthentication(BearerActorAuthenticationHandler.SchemeName)
    .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, BearerActorAuthenticationHandler>(
        BearerActorAuthenticationHandler.SchemeName, _ => { });

builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("Dev", policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    if (app.Configuration.GetValue<bool>("Database:AutoMigrate"))
    {
        using var scope = app.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<CemberDbContext>();
        db.Database.Migrate();
    }
}

// The starter Keşfet challenges — inserted only when missing, so later edits are kept.
using (var scope = app.Services.CreateScope())
{
    await ChallengeCatalog.SeedAsync(scope.ServiceProvider.GetRequiredService<CemberDbContext>());
}

// One-off maintenance: `dotnet run --project backend/src/Cember.Api -- strip-exif` removes location & other
// metadata from files stored before uploads were cleaned, then exits instead of starting the server.
if (args.Contains("strip-exif"))
{
    using var scope = app.Services.CreateScope();
    var backfill = scope.ServiceProvider.GetRequiredService<MetadataBackfill>();
    var result = await backfill.RunAsync(CancellationToken.None);
    app.Logger.LogInformation("Meta veri temizliği bitti: {Checked} dosya kontrol edildi, {Cleaned} temizlendi, {Failed} hata.",
        result.Checked, result.Cleaned, result.Failed);
    return;
}

app.UseMiddleware<AppExceptionMiddleware>();

app.UseCors("Dev");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Android App Links: lets https://cember.app/join/{token} open the app directly (no "open with" prompt)
// once this API is served at cember.app. The fingerprints are the app's signing certificates.
app.MapGet("/.well-known/assetlinks.json", (IConfiguration configuration) =>
{
    var packageName = configuration["AndroidAppLinks:PackageName"] ?? "com.cember.cember";
    var fingerprints = configuration.GetSection("AndroidAppLinks:Sha256CertFingerprints").Get<string[]>() ?? [];
    return Results.Json(new[]
    {
        new
        {
            relation = new[] { "delegate_permission/common.handle_all_urls" },
            target = new { @namespace = "android_app", package_name = packageName, sha256_cert_fingerprints = fingerprints },
        },
    });
}).AllowAnonymous();

app.Run();

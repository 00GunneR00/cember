using Cember.Application.Common;
using Cember.Application.Dtos;
using Cember.Application.Interfaces;
using Cember.Domain.Entities;
using Cember.Infrastructure.Persistence;
using Cember.Infrastructure.Security;
using Google.Apis.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace Cember.Infrastructure.Services;

public class AuthService(CemberDbContext db, IConfiguration configuration) : IAuthService
{
    public async Task<RegisterHostResponse> RegisterHostAsync(RegisterHostRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            throw new ValidationAppException("displayName gerekli.");
        }

        var apiKey = SecretTokens.GenerateOpaqueToken();
        var user = new User
        {
            Id = Guid.NewGuid(),
            DisplayName = request.DisplayName.Trim(),
            ApiKeyHash = SecretTokens.Hash(apiKey),
            OnlyUploadOnWifi = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        return new RegisterHostResponse(user.Id, apiKey);
    }

    public async Task<RegisterHostResponse> GoogleSignInAsync(GoogleSignInRequest request, CancellationToken ct = default)
    {
        var payload = await ValidateGoogleIdTokenAsync(request.IdToken);

        var link = await db.GoogleLinks.FirstOrDefaultAsync(g => g.GoogleSub == payload.Subject, ct);
        if (link is not null)
        {
            var linkedUser = await db.Users.FirstAsync(u => u.Id == link.UserId, ct);
            return new RegisterHostResponse(link.UserId, await IssueApiKeyAsync(link.UserId, ct), linkedUser.IsAdmin);
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            DisplayName = string.IsNullOrWhiteSpace(payload.Name) ? payload.Email.Split('@')[0] : payload.Name,
            ApiKeyHash = SecretTokens.Hash(SecretTokens.GenerateOpaqueToken()),
            OnlyUploadOnWifi = false,
            CreatedAt = DateTimeOffset.UtcNow,
        };
        db.Users.Add(user);
        db.GoogleLinks.Add(new GoogleLink
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            GoogleSub = payload.Subject,
            Email = payload.Email,
            CreatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync(ct);

        return new RegisterHostResponse(user.Id, await IssueApiKeyAsync(user.Id, ct));
    }

    public async Task LinkGoogleAsync(Guid hostId, LinkGoogleRequest request, CancellationToken ct = default)
    {
        var payload = await ValidateGoogleIdTokenAsync(request.IdToken);

        var existing = await db.GoogleLinks.FirstOrDefaultAsync(g => g.GoogleSub == payload.Subject, ct);
        if (existing is not null)
        {
            if (existing.UserId != hostId)
            {
                throw new ValidationAppException("Bu Google hesabı başka bir Çember hesabına bağlı.");
            }
            return;
        }

        db.GoogleLinks.Add(new GoogleLink
        {
            Id = Guid.NewGuid(),
            UserId = hostId,
            GoogleSub = payload.Subject,
            Email = payload.Email,
            CreatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync(ct);
    }

    private async Task<GoogleJsonWebSignature.Payload> ValidateGoogleIdTokenAsync(string idToken)
    {
        var webClientId = configuration["Google:WebClientId"]
            ?? throw new InvalidOperationException("Google:WebClientId yapılandırılmamış.");
        try
        {
            return await GoogleJsonWebSignature.ValidateAsync(idToken, new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = [webClientId],
            });
        }
        catch (InvalidJwtException)
        {
            throw new ValidationAppException("Google kimlik doğrulaması geçersiz.");
        }
    }

    private async Task<string> IssueApiKeyAsync(Guid userId, CancellationToken ct)
    {
        var apiKey = SecretTokens.GenerateOpaqueToken();
        db.ApiKeys.Add(new ApiKey
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ApiKeyHash = SecretTokens.Hash(apiKey),
            CreatedAt = DateTimeOffset.UtcNow,
        });
        await db.SaveChangesAsync(ct);
        return apiKey;
    }
}

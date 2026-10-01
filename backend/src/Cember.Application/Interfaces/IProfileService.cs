using Cember.Application.Dtos;

namespace Cember.Application.Interfaces;

public interface IProfileService
{
    Task<ProfileDto> GetProfileAsync(Guid userId, CancellationToken ct = default);

    Task UpdateSettingsAsync(Guid userId, UpdateSettingsRequest request, CancellationToken ct = default);

    Task<PhotoPageDto> GetFavoritesAsync(Guid userId, string? cursor, int pageSize, CancellationToken ct = default);

    /// <summary>
    /// Permanently deletes a host account: their circles (with every photo in them), the photos they
    /// posted in other people's circles, and all their comments, reactions, notifications and sign-in keys.
    /// </summary>
    Task DeleteAccountAsync(Guid userId, CancellationToken ct = default);

    /// <summary>Deletes a guest identity (one joined circle) together with its photos, comments and reactions.</summary>
    Task DeleteGuestSessionAsync(Guid guestSessionId, CancellationToken ct = default);
}

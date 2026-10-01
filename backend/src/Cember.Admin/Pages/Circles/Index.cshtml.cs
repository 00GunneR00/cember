using Cember.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Admin.Pages.Circles;

public class IndexModel(CemberApiClient api) : AdminPageModel
{
    public IReadOnlyList<AdminCircleSummary> Circles { get; private set; } = [];

    public IReadOnlyList<BrandProfile> Brands { get; private set; } = [];

    public string? Error { get; private set; }

    public string? Message { get; private set; }

    public async Task OnGetAsync(CancellationToken ct)
    {
        await LoadAsync(ct);
    }

    public async Task<IActionResult> OnPostAssignAsync(Guid circleId, Guid? brandProfileId, CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return RedirectToPage("/Login");
        }

        if (circleId == Guid.Empty)
        {
            Error = "Geçerli bir çember ID'si girin.";
            await LoadAsync(ct);
            return Page();
        }

        var ok = await api.AssignBrandAsync(BearerToken, circleId, brandProfileId, ct);
        if (ok)
        {
            Message = "Marka ataması güncellendi.";
        }
        else
        {
            Error = "Marka ataması başarısız oldu.";
        }

        await LoadAsync(ct);
        return Page();
    }

    private async Task LoadAsync(CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return;
        }

        try
        {
            Circles = await api.ListCirclesAsync(BearerToken, ct);
            Brands = await api.ListBrandProfilesAsync(BearerToken, ct);
        }
        catch (HttpRequestException)
        {
            Error = "Çember listesi alınamadı.";
        }
    }
}

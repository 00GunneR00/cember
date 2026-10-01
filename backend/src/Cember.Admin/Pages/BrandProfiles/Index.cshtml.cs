using Cember.Admin.Services;

namespace Cember.Admin.Pages.BrandProfiles;

public class IndexModel(CemberApiClient api) : AdminPageModel
{
    public IReadOnlyList<BrandProfile> Brands { get; private set; } = [];

    public string? Error { get; private set; }

    public async Task OnGetAsync(CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return;
        }

        try
        {
            Brands = await api.ListBrandProfilesAsync(BearerToken, ct);
        }
        catch (HttpRequestException)
        {
            Error = "Marka listesi alınamadı.";
        }
    }
}

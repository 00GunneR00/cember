using Cember.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Admin.Pages.BrandProfiles;

public class CreateModel(CemberApiClient api) : AdminPageModel
{
    [BindProperty]
    public string Name { get; set; } = string.Empty;

    [BindProperty]
    public string PrimaryColorHex { get; set; } = "#ff0000";

    [BindProperty]
    public string? SecondaryColorHex { get; set; }

    [BindProperty]
    public IFormFile? Logo { get; set; }

    public string? Error { get; private set; }

    public void OnGet()
    {
    }

    public async Task<IActionResult> OnPostAsync(CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return RedirectToPage("/Login");
        }

        if (string.IsNullOrWhiteSpace(Name))
        {
            Error = "Marka adı zorunlu.";
            return Page();
        }

        var created = await api.CreateBrandProfileAsync(BearerToken, Name, PrimaryColorHex, SecondaryColorHex, Logo, ct);
        if (created is null)
        {
            Error = "Marka oluşturulamadı.";
            return Page();
        }

        return RedirectToPage("/BrandProfiles/Index");
    }
}

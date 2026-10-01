using Cember.Admin.Services;
using Microsoft.AspNetCore.Mvc;

namespace Cember.Admin.Pages.Reports;

public class IndexModel(CemberApiClient api) : AdminPageModel
{
    public IReadOnlyList<ReportedPhoto> Reports { get; private set; } = [];

    public string? Error { get; private set; }

    public string? Message { get; private set; }

    public async Task OnGetAsync(CancellationToken ct)
    {
        await LoadAsync(ct);
    }

    public async Task<IActionResult> OnPostResolveAsync(Guid photoId, bool removePhoto, CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return RedirectToPage("/Login");
        }

        var ok = await api.ResolveReportsAsync(BearerToken, photoId, removePhoto, ct);
        if (ok)
        {
            Message = removePhoto ? "Fotoğraf kaldırıldı." : "Şikayetler kapatıldı, fotoğraf yeniden görünür.";
        }
        else
        {
            Error = "İşlem başarısız oldu.";
        }

        await LoadAsync(ct);
        return Page();
    }

    public static string ReasonLabel(string reason) => reason switch
    {
        "Inappropriate" => "Müstehcen / uygunsuz",
        "Violence" => "Şiddet, nefret, taciz",
        "Privacy" => "İzinsiz paylaşım",
        "Spam" => "Spam",
        _ => "Diğer",
    };

    private async Task LoadAsync(CancellationToken ct)
    {
        if (BearerToken is null)
        {
            return;
        }

        try
        {
            Reports = await api.ListOpenReportsAsync(BearerToken, ct);
        }
        catch (HttpRequestException)
        {
            Error = "Şikayet listesi alınamadı.";
        }
    }
}

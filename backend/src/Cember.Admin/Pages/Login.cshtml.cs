using System.Security.Claims;
using Cember.Admin.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Cember.Admin.Pages;

[AllowAnonymous]
public class LoginModel(CemberApiClient api, IConfiguration configuration) : PageModel
{
    public string GoogleClientId => configuration["Google:WebClientId"] ?? string.Empty;

    public void OnGet()
    {
    }

    public sealed class SignInBody
    {
        public string Credential { get; set; } = string.Empty;
    }

    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> OnPostSignInAsync([FromBody] SignInBody body, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(body.Credential))
        {
            return new JsonResult(new { ok = false, message = "Google kimlik bilgisi eksik." }) { StatusCode = 400 };
        }

        var result = await api.SignInWithGoogleAsync(body.Credential, ct);
        if (result is null)
        {
            return new JsonResult(new { ok = false, message = "Giriş başarısız." }) { StatusCode = 401 };
        }

        if (!result.IsAdmin)
        {
            return new JsonResult(new { ok = false, message = "Bu hesabın admin yetkisi yok." }) { StatusCode = 403 };
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, result.UserId.ToString()),
            new("cember_token", result.ApiKey),
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity));

        return new JsonResult(new { ok = true, redirectUrl = Url.Content("~/BrandProfiles") });
    }

    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> OnPostSignOutAsync()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToPage("/Login");
    }
}

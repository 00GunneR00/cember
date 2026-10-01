using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Cember.Admin.Pages;

/// <summary>Base for every page except Login — requires the admin cookie and exposes the API bearer token it carries.</summary>
[Authorize]
public abstract class AdminPageModel : PageModel
{
    protected string? BearerToken => User.FindFirst("cember_token")?.Value;
}

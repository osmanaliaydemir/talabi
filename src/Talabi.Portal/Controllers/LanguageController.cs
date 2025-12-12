using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Mvc;

namespace Talabi.Portal.Controllers;

public class LanguageController : Controller
{
    [HttpGet]
    public IActionResult SetLanguage(string culture, string returnUrl)
    {
        if (string.IsNullOrEmpty(culture))
        {
            culture = "tr-TR";
        }

        Response.Cookies.Append(
            "Talabi.Portal.Culture",
            CookieRequestCultureProvider.MakeCookieValue(new RequestCulture(culture)),
            new CookieOptions { Expires = DateTimeOffset.UtcNow.AddYears(1), IsEssential = true }
        );

        if (string.IsNullOrEmpty(returnUrl))
        {
            return RedirectToAction("Index", "Home");
        }

        return LocalRedirect(returnUrl);
    }
}

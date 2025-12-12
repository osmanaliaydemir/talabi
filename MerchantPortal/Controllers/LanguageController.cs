using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

/// <summary>
/// Dil ve kültür yönetimi controller'ı
/// </summary>
public class LanguageController : Controller
{
    /// <summary>
    /// Kullanıcı dil tercihini ayarla
    /// </summary>
    /// <param name="culture">Kültür kodu</param>
    /// <param name="returnUrl">Dönüş URL'i</param>
    /// <returns>Belirtilen sayfaya yönlendirme</returns>
    [HttpGet]
    public IActionResult SetLanguage(string culture, string? returnUrl = null)
    {
        // Validate culture
        var supportedCultures = new[] { "tr-TR", "en-US", "ar-SA" };
        if (!supportedCultures.Contains(culture))
        {
            culture = "tr-TR"; // Fallback to Turkish
        }

        // Set culture cookie
        Response.Cookies.Append(
            "MerchantPortal.Culture", // Use same cookie name as configured in Program.cs
            CookieRequestCultureProvider.MakeCookieValue(new RequestCulture(culture)),
            new CookieOptions
            {
                Expires = DateTimeOffset.UtcNow.AddYears(1),
                HttpOnly = true,
                Secure = false, // HTTP için false olmalı
                SameSite = SameSiteMode.Lax,
                IsEssential = true
            }
        );

        // Redirect to return URL or homepage
        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction("Index", "Dashboard");
    }

    /// <summary>
    /// Mevcut kültür bilgisini getir
    /// </summary>
    /// <returns>JSON kültür bilgileri</returns>
    [HttpGet]
    public IActionResult GetCurrentCulture()
    {
        var currentCulture = System.Globalization.CultureInfo.CurrentUICulture.Name;
        var isRtl = currentCulture.StartsWith("ar");

        return Json(new
        {
            culture = currentCulture,
            isRtl = isRtl,
            displayName = System.Globalization.CultureInfo.CurrentUICulture.DisplayName
        });
    }
}


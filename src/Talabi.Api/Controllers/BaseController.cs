using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Tüm controller'lar için temel sınıf
/// Ortak metodları ve servisleri sağlar
/// </summary>
public abstract class BaseController : ControllerBase
{
    protected readonly IUnitOfWork UnitOfWork;
    protected readonly ILogger Logger;
    protected readonly ILocalizationService LocalizationService;
    protected readonly IUserContextService UserContext;

    /// <summary>
    /// BaseController constructor
    /// </summary>
    protected BaseController(
        IUnitOfWork unitOfWork,
        ILogger logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
    {
        UnitOfWork = unitOfWork;
        Logger = logger;
        LocalizationService = localizationService;
        UserContext = userContext;
    }

    /// <summary>
    /// Request'ten gelen dile göre CultureInfo döner
    /// </summary>
    protected CultureInfo CurrentCulture => GetCultureInfo(GetLanguageFromRequest());

    /// <summary>
    /// Request'ten dil bilgisini alır
    /// Öncelik: 1. Query parametresi, 2. Accept-Language header, 3. Default (tr)
    /// </summary>
    protected string GetLanguageFromRequest(string? language = null)
    {
        // Priority: 1. Query parameter, 2. Accept-Language header, 3. Default (tr)
        if (!string.IsNullOrWhiteSpace(language))
        {
            return NormalizeLanguageCode(language);
        }

        // Check Accept-Language header
        if (Request.Headers.TryGetValue("Accept-Language", out var acceptLanguage))
        {
            var languages = acceptLanguage.ToString().Split(',');
            if (languages.Length > 0)
            {
                var primaryLanguage = languages[0].Split(';')[0].Trim().ToLowerInvariant();
                return NormalizeLanguageCode(primaryLanguage);
            }
        }

        return "tr"; // Default
    }

    /// <summary>
    /// Dil kodunu normalize eder (tr, en, ar)
    /// </summary>
    protected static string NormalizeLanguageCode(string? languageCode)
    {
        if (string.IsNullOrWhiteSpace(languageCode))
        {
            return "tr";
        }

        var normalized = languageCode.ToLowerInvariant().Trim();

        return normalized switch
        {
            "tr" or "turkish" or "tr-tr" or "tr-TR" => "tr",
            "en" or "english" or "en-us" or "en-US" or "en-gb" or "en-GB" => "en",
            "ar" or "arabic" or "ar-sa" or "ar-SA" => "ar",
            _ => "tr" // Default fallback
        };
    }

    /// <summary>
    /// Language code'dan CultureInfo nesnesi oluşturur
    /// </summary>
    protected CultureInfo GetCultureInfo(string languageCode)
    {
        try
        {
            return new CultureInfo(languageCode);
        }
        catch
        {
            return new CultureInfo("tr"); // Fallback to Turkish
        }
    }
}


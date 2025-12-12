using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin")]
public class LocalizationAdminController : Controller
{
    private readonly IInternationalizationService _internationalizationService;
    private readonly ILocalizationService _localizationService;

    public LocalizationAdminController(
        IInternationalizationService internationalizationService,
        ILocalizationService localizationService)
    {
        _internationalizationService = internationalizationService;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? searchKey, int page = 1, int pageSize = 20)
    {
        var languages = await _internationalizationService.GetLanguagesAsync();
        var statistics = await _internationalizationService.GetLanguageStatisticsAsync();

        TranslationSearchResponseModel? translations = null;
        if (!string.IsNullOrWhiteSpace(searchKey))
        {
            var request = new TranslationSearchRequestModel
            {
                Key = searchKey,
                Page = page,
                PageSize = pageSize
            };
            translations = await _internationalizationService.SearchTranslationsAsync(request);
        }

        var viewModel = new LocalizationAdminViewModel
        {
            Languages = languages,
            Statistics = statistics,
            TranslationSearch = translations,
            SearchKey = searchKey,
            Page = page,
            PageSize = pageSize
        };

        ViewBag.Title = _localizationService.GetString("LocalizationAdmin");

        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetDefault(Guid languageId)
    {
        if (languageId == Guid.Empty)
        {
            TempData["Error"] = _localizationService.GetString("LocalizationInvalidLanguage");
            return RedirectToAction(nameof(Index));
        }

        var result = await _internationalizationService.SetDefaultLanguageAsync(languageId);
        TempData[result ? "Success" : "Error"] = result
            ? _localizationService.GetString("LocalizationDefaultUpdated")
            : _localizationService.GetString("LocalizationDefaultUpdateFailed");

        return RedirectToAction(nameof(Index));
    }
}


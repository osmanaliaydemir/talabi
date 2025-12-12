using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class HomeController : Controller
{
    private readonly IHomeService _homeService;
    private readonly ILocalizationService _localizationService;

    public HomeController(IHomeService homeService, ILocalizationService localizationService)
    {
        _homeService = homeService;
        _localizationService = localizationService;
    }

    public async Task<IActionResult> Index()
    {
        // İstatistikleri servisten çek (Enriched Summary dahil)
        var viewModel = await _homeService.GetDashboardStatsAsync();
        
        // Profil bilgilerini çek
        var profile = await _homeService.GetProfileAsync();
        if (profile != null)
        {
            viewModel.Profile = profile;
        }

        return View(viewModel);
    }
}

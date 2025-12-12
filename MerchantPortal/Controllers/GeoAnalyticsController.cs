using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin")]
public class GeoAnalyticsController : Controller
{
    private readonly IGeoAnalyticsPortalService _geoAnalyticsService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<GeoAnalyticsController> _logger;

    public GeoAnalyticsController(
        IGeoAnalyticsPortalService geoAnalyticsService,
        ILocalizationService localizationService,
        ILogger<GeoAnalyticsController> logger)
    {
        _geoAnalyticsService = geoAnalyticsService;
        _localizationService = localizationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index(DateTime? startDate = null, DateTime? endDate = null, double? latitude = null, double? longitude = null, double radiusKm = 5, int? categoryType = null)
    {
        var analyticsTask = _geoAnalyticsService.GetLocationAnalyticsAsync(startDate, endDate);
        var coverageTask = _geoAnalyticsService.GetDeliveryZoneCoverageAsync();

        Task<List<NearbyMerchantResponse>> nearbyTask;
        if (latitude.HasValue && longitude.HasValue)
        {
            nearbyTask = _geoAnalyticsService.GetNearbyMerchantsAsync(latitude.Value, longitude.Value, radiusKm, categoryType);
        }
        else
        {
            nearbyTask = Task.FromResult(new List<NearbyMerchantResponse>());
        }

        var historyTask = _geoAnalyticsService.GetLocationHistoryAsync(new PaginationQueryRequest
        {
            Page = 1,
            PageSize = 15
        });

        await Task.WhenAll(analyticsTask, coverageTask, nearbyTask, historyTask);

        var viewModel = new GeoAnalyticsViewModel
        {
            Analytics = analyticsTask.Result,
            Coverage = coverageTask.Result,
            NearbyMerchants = nearbyTask.Result,
            LocationHistory = historyTask.Result,
            Filter = new GeoAnalyticsFilterViewModel
            {
                StartDate = startDate,
                EndDate = endDate,
                Latitude = latitude,
                Longitude = longitude,
                RadiusKm = radiusKm,
                CategoryType = categoryType
            }
        };

        ViewData["Title"] = _localizationService.GetString("GeoAnalytics");

        return View(viewModel);
    }
}



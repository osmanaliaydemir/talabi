using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin")]
public class PlatformAdminController : Controller
{
    private readonly IPlatformAdminPortalService _platformAdminService;
    private readonly ILocalizationService _localizationService;

    public PlatformAdminController(
        IPlatformAdminPortalService platformAdminService,
        ILocalizationService localizationService)
    {
        _platformAdminService = platformAdminService;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index(int page = 1, int pageSize = 10)
    {
        var pagination = new PaginationQueryRequest
        {
            Page = page < 1 ? 1 : page,
            PageSize = pageSize < 1 ? 10 : pageSize
        };

        var viewModel = new PlatformAdminDashboardViewModel
        {
            Dashboard = await _platformAdminService.GetDashboardAsync(),
            SystemStatistics = await _platformAdminService.GetSystemStatisticsAsync(),
            MerchantApplications = await _platformAdminService.GetMerchantApplicationsAsync(pagination),
            Notifications = await _platformAdminService.GetSystemNotificationsAsync(),
            Pagination = pagination
        };

        ViewData["Title"] = _localizationService.GetString("PlatformAdminCenter");
        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> MarkNotification(Guid notificationId)
    {
        var success = await _platformAdminService.MarkNotificationAsReadAsync(notificationId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("PlatformNotificationMarkedRead")
            : _localizationService.GetString("PlatformNotificationMarkReadFailed");

        return RedirectToAction(nameof(Index));
    }
}



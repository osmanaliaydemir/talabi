using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin")]
public class AuditLoggingAdminController : Controller
{
    private readonly IAuditLoggingPortalService _auditLoggingService;
    private readonly ILocalizationService _localizationService;

    public AuditLoggingAdminController(
        IAuditLoggingPortalService auditLoggingService,
        ILocalizationService localizationService)
    {
        _auditLoggingService = auditLoggingService;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index([FromQuery] AuditLoggingFilterViewModel filter)
    {
        var defaultEnd = DateTime.UtcNow;
        var defaultStart = defaultEnd.AddDays(-7);

        filter.StartDate ??= defaultStart;
        filter.EndDate ??= defaultEnd;

        var userActivityRequest = new UserActivityQueryRequestModel
        {
            StartDate = filter.StartDate,
            EndDate = filter.EndDate,
            UserName = filter.UserName,
            ActivityType = filter.ActivityType,
            EntityType = filter.EntityType,
            PageSize = filter.PageSize
        };

        var systemChangeRequest = new SystemChangeQueryRequestModel
        {
            StartDate = filter.StartDate,
            EndDate = filter.EndDate,
            EntityType = filter.EntityType,
            Severity = filter.Severity,
            PageSize = filter.PageSize
        };

        var securityEventRequest = new SecurityEventQueryRequestModel
        {
            StartDate = filter.StartDate,
            EndDate = filter.EndDate,
            Severity = filter.Severity,
            RiskLevel = filter.RiskLevel,
            PageSize = filter.PageSize
        };

        var analyticsRequest = new AuditLogAnalyticsRequestModel
        {
            StartDate = filter.StartDate ?? defaultStart,
            EndDate = filter.EndDate ?? defaultEnd,
            EntityType = filter.EntityType,
            Action = filter.ActivityType,
            GroupBy = "DAY"
        };

        var viewModel = new AuditLoggingDashboardViewModel
        {
            DefaultStartDate = defaultStart,
            DefaultEndDate = defaultEnd,
            Filter = filter,
            UserActivities = await _auditLoggingService.GetUserActivityLogsAsync(userActivityRequest),
            SystemChanges = await _auditLoggingService.GetSystemChangeLogsAsync(systemChangeRequest),
            SecurityEvents = await _auditLoggingService.GetSecurityEventLogsAsync(securityEventRequest),
            Analytics = await _auditLoggingService.GetAuditAnalyticsAsync(analyticsRequest),
            Reports = await _auditLoggingService.GetLogAnalysisReportsAsync()
        };

        ViewData["Title"] = _localizationService.GetString("AuditLoggingCenter");
        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CleanupUserActivity(DateTime cutoffDate)
    {
        var success = await _auditLoggingService.CleanupUserActivitiesAsync(cutoffDate);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AuditCleanupUserActivitySuccess")
            : _localizationService.GetString("AuditCleanupUserActivityFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CleanupSystemChanges(DateTime cutoffDate)
    {
        var success = await _auditLoggingService.CleanupSystemChangesAsync(cutoffDate);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AuditCleanupSystemChangeSuccess")
            : _localizationService.GetString("AuditCleanupSystemChangeFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CleanupSecurityEvents(DateTime cutoffDate)
    {
        var success = await _auditLoggingService.CleanupSecurityEventsAsync(cutoffDate);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AuditCleanupSecurityEventSuccess")
            : _localizationService.GetString("AuditCleanupSecurityEventFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CleanupReports()
    {
        var success = await _auditLoggingService.CleanupAnalysisReportsAsync();
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AuditCleanupReportsSuccess")
            : _localizationService.GetString("AuditCleanupReportsFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RegenerateReport(Guid reportId)
    {
        var report = await _auditLoggingService.RegenerateReportAsync(reportId);
        TempData[report != null ? "Success" : "Error"] = report != null
            ? _localizationService.GetString("AuditReportRegenerated")
            : _localizationService.GetString("AuditReportRegenerateFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> ExportReport(Guid reportId, string format = "PDF")
    {
        var bytes = await _auditLoggingService.ExportReportAsync(reportId, format);
        if (bytes == null || bytes.Length == 0)
        {
            TempData["Error"] = _localizationService.GetString("AuditReportExportFailed");
            return RedirectToAction(nameof(Index));
        }

        var fileName = $"audit-report-{reportId}.{format.ToLowerInvariant()}";
        return File(bytes, "application/octet-stream", fileName);
    }
}



using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class ReportsController : Controller
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportsController> _logger;

    /// <summary>
    /// ReportsController constructor
    /// </summary>
    /// <param name="reportService">Rapor servisi</param>
    /// <param name="logger">Logger instance</param>
    public ReportsController(
        IReportService reportService,
        ILogger<ReportsController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    /// <summary>
    /// Satış dashboard sayfasını göster
    /// </summary>
    /// <returns>Satış dashboard sayfası</returns>
    public IActionResult Dashboard()
    {
        ViewData["Title"] = "SalesDashboard";
        return View();
    }

    /// <summary>
    /// Gelir analitikleri sayfasını göster
    /// </summary>
    /// <returns>Gelir analitikleri sayfası</returns>
    public IActionResult Revenue()
    {
        ViewData["Title"] = "RevenueAnalytics";
        return View();
    }

    /// <summary>
    /// Müşteri analitikleri sayfasını göster
    /// </summary>
    /// <returns>Müşteri analitikleri sayfası</returns>
    public IActionResult Customers()
    {
        ViewData["Title"] = "CustomerAnalytics";
        return View();
    }

    /// <summary>
    /// Ürün performansı sayfasını göster
    /// </summary>
    /// <returns>Ürün performansı sayfası</returns>
    public IActionResult Products()
    {
        ViewData["Title"] = "ProductPerformance";
        return View();
    }

    /// <summary>
    /// Satış dashboard verilerini getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON dashboard verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetSalesDashboard(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var dashboard = await _reportService.GetSalesDashboardAsync(merchantId, startDate, endDate);

            return Json(new { success = true, data = dashboard });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting sales dashboard");
            return Json(new { success = false, message = "Error loading dashboard data" });
        }
    }

    /// <summary>
    /// Gelir analitik verilerini getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON analitik verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetRevenueAnalytics(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var analytics = await _reportService.GetRevenueAnalyticsAsync(merchantId, startDate, endDate);

            return Json(new { success = true, data = analytics });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting revenue analytics");
            return Json(new { success = false, message = "Error loading analytics data" });
        }
    }

    /// <summary>
    /// Müşteri analitik verilerini getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON müşteri verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetCustomerAnalytics(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var analytics = await _reportService.GetCustomerAnalyticsAsync(merchantId, startDate, endDate);

            return Json(new { success = true, data = analytics });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customer analytics");
            return Json(new { success = false, message = "Error loading customer data" });
        }
    }

    /// <summary>
    /// Ürün performans verilerini getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON ürün performans verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetProductPerformance(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var performance = await _reportService.GetProductPerformanceAsync(merchantId, startDate, endDate);

            return Json(new { success = true, data = performance });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product performance");
            return Json(new { success = false, message = "Error loading product data" });
        }
    }

    /// <summary>
    /// Chart verilerini getir
    /// </summary>
    /// <param name="chartType">Chart türü</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON chart verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetChartData(string chartType, DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var chartData = await _reportService.GetChartDataAsync(merchantId, chartType, startDate, endDate);

            return Json(new { success = true, data = chartData });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting chart data for type {ChartType}", chartType);
            return Json(new { success = false, message = "Error loading chart data" });
        }
    }

    /// <summary>
    /// Raporu Excel'e aktar
    /// </summary>
    /// <param name="request">Aktarım parametreleri</param>
    /// <returns>Excel dosyası</returns>
    [HttpPost]
    public async Task<IActionResult> ExportToExcel([FromBody] ReportExportRequest request)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var fileBytes = await _reportService.ExportReportToExcelAsync(merchantId, request);

            return File(fileBytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", 
                $"report_{request.ReportType}_{DateTime.Now:yyyyMMdd}.xlsx");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting report to Excel");
            return Json(new { success = false, message = "Error generating Excel report" });
        }
    }

    /// <summary>
    /// Raporu PDF'e aktar
    /// </summary>
    /// <param name="request">Aktarım parametreleri</param>
    /// <returns>PDF dosyası</returns>
    [HttpPost]
    public async Task<IActionResult> ExportToPdf([FromBody] ReportExportRequest request)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var fileBytes = await _reportService.ExportReportToPdfAsync(merchantId, request);

            return File(fileBytes, "application/pdf", 
                $"report_{request.ReportType}_{DateTime.Now:yyyyMMdd}.pdf");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting report to PDF");
            return Json(new { success = false, message = "Error generating PDF report" });
        }
    }
}

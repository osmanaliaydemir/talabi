using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Threading;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class PaymentsController : Controller
{
    private readonly IPaymentService _paymentService;
    private readonly ILogger<PaymentsController> _logger;

    /// <summary>
    /// PaymentsController constructor
    /// </summary>
    /// <param name="paymentService">Ödeme servisi</param>
    /// <param name="logger">Logger instance</param>
    public PaymentsController(
        IPaymentService paymentService,
        ILogger<PaymentsController> logger)
    {
        _paymentService = paymentService;
        _logger = logger;
    }

    /// <summary>
    /// Ödeme geçmişi sayfasını göster
    /// </summary>
    /// <returns>Ödeme geçmişi sayfası</returns>
    public IActionResult Index()
    {
        ViewData["Title"] = "PaymentHistory";
        return View();
    }

    /// <summary>
    /// Raporlar sayfasını göster
    /// </summary>
    /// <returns>Raporlar sayfası</returns>
    public IActionResult Reports()
    {
        ViewData["Title"] = "PaymentReports";
        return View();
    }

    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CashCollections(string? status = null, int page = 1, CancellationToken ct = default)
    {
        var viewModel = await BuildCashCollectionsViewModel(status, page, ct);
        return View(viewModel);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ProcessSettlement(ProcessSettlementInput input, CancellationToken ct = default)
    {
        input.ReturnPage = input.ReturnPage <= 0 ? 1 : input.ReturnPage;

        if (!ModelState.IsValid)
        {
            var viewModel = await BuildCashCollectionsViewModel(input.ReturnStatus, input.ReturnPage, ct);
            viewModel.Settlement = input;
            return View("CashCollections", viewModel);
        }

        var request = new ProcessSettlementRequest
        {
            CommissionRate = input.CommissionRate,
            Notes = input.Notes,
            BankTransferReference = input.BankTransferReference
        };

        var success = await _paymentService.ProcessSettlementAsync(input.MerchantId, request, ct);
        TempData[success ? "SuccessMessage" : "ErrorMessage"] = success
            ? "Mutabakat işlemi tamamlandı."
            : "Mutabakat işlemi sırasında bir hata oluştu.";

        return RedirectToAction(nameof(CashCollections), new { status = input.ReturnStatus, page = input.ReturnPage });
    }

    /// <summary>
    /// Mutabakat sayfasını göster
    /// </summary>
    /// <returns>Mutabakat sayfası</returns>
    public IActionResult Settlements()
    {
        ViewData["Title"] = "SettlementReports";
        return View();
    }

    /// <summary>
    /// Ödeme geçmişi verilerini getir
    /// </summary>
    /// <param name="filter">Filtre parametreleri</param>
    /// <returns>JSON ödeme verileri</returns>
    [HttpPost]
    public async Task<IActionResult> GetPaymentHistoryData([FromBody] PaymentFilterModel filter)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var payments = await _paymentService.GetPaymentHistoryAsync(merchantId, filter);

            return Json(new
            {
                success = true,
                data = payments,
                recordsTotal = payments.Count,
                recordsFiltered = payments.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment history data");
            return Json(new { success = false, message = "Error loading payment data" });
        }
    }

    /// <summary>
    /// Ödeme yöntemi dağılımını getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON chart verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetPaymentMethodBreakdown(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var breakdown = await _paymentService.GetPaymentMethodBreakdownAsync(merchantId, startDate, endDate);

            return Json(new
            {
                success = true,
                data = new
                {
                    labels = breakdown.Select(b => b.DisplayName).ToArray(),
                    datasets = new[]
                    {
                        new
                        {
                            label = "Ciro (₺)",
                            data = breakdown.Select(b => b.TotalAmount).ToArray(),
                            backgroundColor = breakdown.Select(b => b.Color).ToArray(),
                            borderWidth = 0
                        }
                    }
                },
                breakdown
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment method breakdown");
            return Json(new { success = false, message = "Error loading breakdown data" });
        }
    }

    /// <summary>
    /// Gelir analitiklerini getir
    /// </summary>
    /// <returns>JSON analitik verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetRevenueAnalytics()
    {
        try
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var analytics = await _paymentService.GetRevenueAnalyticsAsync(merchantId);

            return Json(new { success = true, data = analytics });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting revenue analytics");
            return Json(new { success = false, message = "Error loading analytics" });
        }
    }

    /// <summary>
    /// Mutabakat raporunu getir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>JSON mutabakat raporu</returns>
    [HttpGet]
    public async Task<IActionResult> GetSettlementReport(DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var start = startDate ?? DateTime.Now.AddMonths(-1).Date;
            var end = endDate ?? DateTime.Now.Date;

            var report = await _paymentService.GetSettlementReportAsync(merchantId, start, end);

            return Json(new { success = true, data = report });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting settlement report");
            return Json(new { success = false, message = "Error loading settlement report" });
        }
    }

    /// <summary>
    /// Ödemeleri Excel'e aktar
    /// </summary>
    /// <param name="request">Aktarım parametreleri</param>
    /// <returns>Excel dosyası</returns>
    [HttpPost]
    public async Task<IActionResult> ExportToExcel([FromBody] PaymentExportRequest request)
    {
        try
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return BadRequest("Merchant not found");
            }

            var fileContent = await _paymentService.ExportToExcelAsync(merchantId, request);
            var fileName = $"Payments_{DateTime.Now:yyyyMMdd_HHmmss}.csv";

            return File(fileContent, "text/csv", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting to Excel");
            return StatusCode(500, "Error exporting data");
        }
    }

    /// <summary>
    /// Ödemeleri PDF'e aktar
    /// </summary>
    /// <param name="request">Aktarım parametreleri</param>
    /// <returns>PDF dosyası</returns>
    [HttpPost]
    public async Task<IActionResult> ExportToPdf([FromBody] PaymentExportRequest request)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return BadRequest("Merchant not found");
            }

            var fileContent = await _paymentService.ExportToPdfAsync(merchantId, request);
            var fileName = $"Payments_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";

            return File(fileContent, "application/pdf", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting to PDF");
            return StatusCode(500, "Error exporting data");
        }
    }

    private async Task<CashCollectionsViewModel> BuildCashCollectionsViewModel(string? status, int page, CancellationToken ct)
    {
        var collections = await _paymentService.GetAdminCashCollectionsAsync(page, 20, status, ct)
                          ?? new PagedResult<PaymentResponse>();
        return new CashCollectionsViewModel
        {
            Collections = collections,
            Status = status,
            Page = page,
            Settlement = new ProcessSettlementInput
            {
                CommissionRate = 0.1m,
                ReturnPage = page,
                ReturnStatus = status
            }
        };
    }
}

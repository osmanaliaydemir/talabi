using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class StockController : Controller
{
    private readonly IStockService _stockService;
    private readonly IProductService _productService;
    private readonly ILogger<StockController> _logger;

    /// <summary>
    /// StockController constructor
    /// </summary>
    /// <param name="stockService">Stok servisi</param>
    /// <param name="productService">Ürün servisi</param>
    /// <param name="logger">Logger instance</param>
    public StockController(IStockService stockService, IProductService productService, ILogger<StockController> logger)
    {
        _stockService = stockService;
        _productService = productService;
        _logger = logger;
    }

    /// <summary>
    /// Stok yönetimi sayfasını göster
    /// </summary>
    /// <returns>Stok yönetimi sayfası veya ana sayfaya yönlendirme</returns>
    public async Task<IActionResult> Index()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            TempData["Error"] = "Merchant not found";
            return RedirectToAction("Index", "Home");
        }

        var products = await _productService.GetProductsByMerchantAsync(merchantId);
        var stockAlerts = await _stockService.GetStockAlertsAsync();
        
        ViewBag.StockAlerts = stockAlerts ?? new List<StockAlertResponse>();
        
        return View(products ?? new List<ProductResponse>());
    }

    /// <summary>
    /// Stok uyarıları sayfasını göster
    /// </summary>
    /// <returns>Stok uyarıları sayfası</returns>
    public async Task<IActionResult> Alerts()
    {
        var alerts = await _stockService.GetStockAlertsAsync();
        return View(alerts ?? new List<StockAlertResponse>());
    }

    /// <summary>
    /// Ürün stok geçmişi sayfasını göster
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="fromDate">Başlangıç tarihi</param>
    /// <param name="toDate">Bitiş tarihi</param>
    /// <returns>Stok geçmişi sayfası veya ürünler sayfasına yönlendirme</returns>
    public async Task<IActionResult> History(Guid productId, DateTime? fromDate = null, DateTime? toDate = null)
    {
        var product = await _productService.GetProductByIdAsync(productId);
        if (product == null)
        {
            TempData["Error"] = "Ürün bulunamadı";
            return RedirectToAction("Index", "Products");
        }

        var history = await _stockService.GetStockHistoryAsync(productId, fromDate, toDate);

        ViewBag.Product = product;
        ViewBag.FromDate = fromDate;
        ViewBag.ToDate = toDate;

        return View(history ?? new List<StockHistoryResponse>());
    }

    /// <summary>
    /// Toplu stok güncelleme
    /// </summary>
    /// <param name="request">Toplu güncelleme verileri</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> BulkUpdate([FromBody] BulkUpdateStockRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Geçersiz veri" });
            }

            var success = await _stockService.BulkUpdateStockLevelsAsync(request);

            if (success)
            {
                return Json(new { success = true, message = "Stok seviyeleri başarıyla güncellendi" });
            }

            return Json(new { success = false, message = "Stok güncellemesi başarısız oldu" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error bulk updating stock");
            return Json(new { success = false, message = "Bir hata oluştu" });
        }
    }

    /// <summary>
    /// Tek ürün stok güncelleme
    /// </summary>
    /// <param name="request">Stok güncelleme verileri</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStock([FromBody] UpdateStockRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Geçersiz veri" });
            }

            var success = await _stockService.UpdateStockLevelAsync(request);

            if (success)
            {
                return Json(new { success = true, message = "Stok seviyesi başarıyla güncellendi" });
            }

            return Json(new { success = false, message = "Stok güncellemesi başarısız oldu" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating stock for product {ProductId}", request.ProductId);
            return Json(new { success = false, message = "Bir hata oluştu" });
        }
    }

    /// <summary>
    /// Stok uyarısını çöz
    /// </summary>
    /// <param name="alertId">Uyarı ID</param>
    /// <param name="resolutionNotes">Çözüm notları</param>
    /// <returns>Uyarılar sayfasına yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResolveAlert(Guid alertId, string resolutionNotes)
    {
        try
        {
            var success = await _stockService.ResolveStockAlertAsync(alertId, resolutionNotes);

            if (success)
            {
                TempData["Success"] = "Uyarı başarıyla çözüldü";
                return RedirectToAction(nameof(Alerts));
            }

            TempData["Error"] = "Uyarı çözümlenemedi";
            return RedirectToAction(nameof(Alerts));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resolving alert {AlertId}", alertId);
            TempData["Error"] = "Bir hata oluştu";
            return RedirectToAction(nameof(Alerts));
        }
    }

    /// <summary>
    /// Stok seviyelerini kontrol et
    /// </summary>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CheckLevels()
    {
        try
        {
            var success = await _stockService.CheckStockLevelsAsync();

            if (success)
            {
                return Json(new { success = true, message = "Stok seviyeleri kontrol edildi" });
            }

            return Json(new { success = false, message = "Kontrol başarısız oldu" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking stock levels");
            return Json(new { success = false, message = "Bir hata oluştu" });
        }
    }

    /// <summary>
    /// Stok verilerini CSV'ye aktar
    /// </summary>
    /// <returns>CSV dosyası</returns>
    [HttpGet]
    public async Task<IActionResult> ExportToCSV()
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return BadRequest("Merchant not found");
            }

            var csvData = await _stockService.ExportStockToCsvAsync(merchantId);
            var fileName = $"Stock_Export_{DateTime.Now:yyyyMMdd_HHmmss}.csv";

            return File(csvData, "text/csv", fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting stock to CSV");
            return StatusCode(500, "Export error");
        }
    }

    /// <summary>
    /// CSV'den stok verilerini içe aktar
    /// </summary>
    /// <param name="file">CSV dosyası</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    public async Task<IActionResult> ImportFromCSV(IFormFile file)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            if (file == null || file.Length == 0)
            {
                return Json(new { success = false, message = "Dosya seçilmedi" });
            }

            using var stream = file.OpenReadStream();
            var result = await _stockService.ImportStockFromCsvAsync(merchantId, stream);

            return Json(new
            {
                success = result.SuccessCount > 0,
                totalRows = result.TotalRows,
                successCount = result.SuccessCount,
                errorCount = result.ErrorCount,
                errors = result.Errors,
                message = $"{result.SuccessCount}/{result.TotalRows} ürün güncellendi"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error importing stock from CSV");
            return Json(new { success = false, message = "Import error" });
        }
    }

    /// <summary>
    /// Düşük stoklu ürünleri getir
    /// </summary>
    /// <param name="threshold">Eşik değeri</param>
    /// <returns>JSON düşük stoklu ürünler</returns>
    [HttpGet]
    public async Task<IActionResult> GetLowStockProducts(int threshold = 10)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            var products = await _stockService.GetLowStockProductsAsync(merchantId, threshold);

            return Json(new { success = true, data = products });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting low stock products");
            return Json(new { success = false, message = "Error loading data" });
        }
    }
}


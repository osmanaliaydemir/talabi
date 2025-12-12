using System.Collections.Generic;
using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class DashboardController : Controller
{
    private readonly IMerchantService _merchantService;
    private readonly IStockService _stockService;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(
        IMerchantService merchantService,
        IStockService stockService,
        ILogger<DashboardController> logger)
    {
        _merchantService = merchantService;
        _stockService = stockService;
        _logger = logger;
    }

    /// <summary>
    /// Dashboard sayfasını göster
    /// </summary>
    /// <returns>Dashboard sayfası veya giriş sayfasına yönlendirme</returns>
    public async Task<IActionResult> Index()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId) || merchantId == Guid.Empty)
        {
            // Try to resolve merchant from API and cache it into session
            _logger.LogWarning("MerchantId missing or empty in session. Attempting to resolve from API.");
            var myMerchant = await _merchantService.GetMyMerchantAsync();
            if (myMerchant != null && myMerchant.Id != Guid.Empty)
            {
                HttpContext.Session.SetString("MerchantId", myMerchant.Id.ToString());
                merchantId = myMerchant.Id;
                _logger.LogInformation("MerchantId resolved and stored in session: {MerchantId}", merchantId);
            }
            else
            {
                _logger.LogWarning("Unable to resolve MerchantId. Redirecting to login or onboarding.");
                return RedirectToAction("Login", "Auth");
            }
        }

        var dashboard = await _merchantService.GetDashboardAsync(merchantId);
        var stockSummary = await _stockService.GetStockSummaryAsync();

        var recentOrders = dashboard?.RecentOrders?.Any() == true
            ? dashboard!.RecentOrders
            : await _merchantService.GetRecentOrdersAsync(merchantId, 5) ?? new List<RecentOrderResponse>();

        var topProducts = dashboard?.TopProducts?.Any() == true
            ? dashboard!.TopProducts
            : await _merchantService.GetTopProductsAsync(merchantId, 5) ?? new List<TopProductResponse>();

        var performance = dashboard?.Performance ?? await _merchantService.GetPerformanceMetricsAsync(merchantId);

        var model = new DashboardViewModel
        {
            Stats = dashboard?.Stats,
            Performance = performance,
            RecentOrders = recentOrders,
            TopProducts = topProducts,
            StockSummary = stockSummary
        };

        return View(model);
    }

    /// <summary>
    /// Stok uyarılarını getir
    /// </summary>
    /// <returns>JSON stok uyarıları</returns>
    [HttpGet]
    public async Task<IActionResult> GetStockAlerts()
    {
        try
        {
            var alerts = await _stockService.GetStockAlertsAsync();
            return Json(new { success = true, data = alerts ?? new List<StockAlertResponse>() });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting stock alerts");
            return Json(new { success = false, message = "Error loading stock alerts" });
        }
    }

    /// <summary>
    /// Satış trendi verilerini getir
    /// </summary>
    /// <param name="days">Gün sayısı</param>
    /// <returns>JSON chart verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetSalesChartData(int days = 30)
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            // Limit days to reasonable range
            if (days > 90) days = 90;
            if (days < 7) days = 7;

            // Fetch REAL sales data from merchant service
            var salesTrend = await _merchantService.GetSalesTrendDataAsync(merchantId, days);
            
            if (salesTrend == null || !salesTrend.Any())
            {
                // Return empty data instead of fake data
                return Json(new
                {
                    success = true,
                    data = new
                    {
                        labels = new List<string>(),
                        datasets = new object[] { }
                    }
                });
            }

            var labels = salesTrend.Select(s => s.Date.ToString("dd MMM")).ToList();
            var revenueData = salesTrend.Select(s => s.Revenue).ToList();
            var orderData = salesTrend.Select(s => s.OrderCount).ToList();

            return Json(new
            {
                success = true,
                data = new
                {
                    labels,
                    datasets = new object[]
                    {
                        new
                        {
                            label = "Ciro (₺)",
                            data = revenueData,
                            borderColor = "#5D3EBC",
                            backgroundColor = "rgba(93, 62, 188, 0.1)",
                            tension = 0.4,
                            fill = true
                        },
                        new
                        {
                            label = "Sipariş Sayısı",
                            data = orderData,
                            borderColor = "#FFD300",
                            backgroundColor = "rgba(255, 211, 0, 0.1)",
                            tension = 0.4,
                            fill = true,
                            yAxisID = "y1"
                        }
                    }
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting sales chart data");
            return Json(new { success = false, message = "Error loading chart data" });
        }
    }

    /// <summary>
    /// Sipariş durumu dağılımını getir
    /// </summary>
    /// <returns>JSON chart verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetOrdersChartData()
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            // Fetch REAL order status distribution
            var orderStatusDistribution = await _merchantService.GetOrderStatusDistributionAsync(merchantId);

            if (orderStatusDistribution == null)
            {
                return Json(new { success = false, message = "No order data available" });
            }

            return Json(new
            {
                success = true,
                data = new
                {
                    labels = new[] { "Bekleyen", "Hazırlanıyor", "Hazır", "Yolda", "Teslim Edildi", "İptal" },
                    datasets = new[]
                    {
                        new
                        {
                            label = "Siparişler",
                            data = new[]
                            {
                                orderStatusDistribution.PendingCount,
                                orderStatusDistribution.PreparingCount,
                                orderStatusDistribution.ReadyCount,
                                orderStatusDistribution.OnWayCount,
                                orderStatusDistribution.DeliveredCount,
                                orderStatusDistribution.CancelledCount
                            },
                            backgroundColor = new[]
                            {
                                "rgba(255, 193, 7, 0.8)",   // Warning - Pending
                                "rgba(13, 110, 253, 0.8)",  // Primary - Preparing
                                "rgba(25, 135, 84, 0.8)",   // Success - Ready
                                "rgba(23, 162, 184, 0.8)",  // Info - On Way
                                "rgba(40, 167, 69, 0.8)",   // Success - Delivered
                                "rgba(220, 53, 69, 0.8)"    // Danger - Cancelled
                            },
                            borderWidth = 0
                        }
                    }
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting orders chart data");
            return Json(new { success = false, message = "Error loading chart data" });
        }
    }

    /// <summary>
    /// Kategori dağılımını getir
    /// </summary>
    /// <returns>JSON chart verileri</returns>
    [HttpGet]
    public async Task<IActionResult> GetCategoryChartData()
    {
        try
        {
            var merchantIdStr = HttpContext.Session.GetString("MerchantId");
            if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
            {
                return Json(new { success = false, message = "Merchant not found" });
            }

            // Fetch REAL category performance data
            var categoryPerformance = await _merchantService.GetCategoryPerformanceAsync(merchantId);

            if (categoryPerformance == null || !categoryPerformance.Any())
            {
                return Json(new { success = false, message = "No category data available" });
            }

            // Predefined colors for categories
            var colorPalette = new[]
            {
                "#FF6384", "#36A2EB", "#FFCE56", "#4BC0C0", "#9966FF",
                "#FF9F40", "#FF6384", "#C9CBCF", "#4BC0C0", "#FF9F40"
            };

            var labels = categoryPerformance.Select(c => c.CategoryName).ToArray();
            var revenues = categoryPerformance.Select(c => c.TotalRevenue).ToArray();
            var colors = categoryPerformance.Select((c, index) => colorPalette[index % colorPalette.Length]).ToArray();

            return Json(new
            {
                success = true,
                data = new
                {
                    labels,
                    datasets = new[]
                    {
                        new
                        {
                            label = "Ciro (₺)",
                            data = revenues,
                            backgroundColor = colors,
                            borderWidth = 2,
                            borderColor = "#fff"
                        }
                    }
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting category chart data");
            return Json(new { success = false, message = "Error loading chart data" });
        }
    }
}


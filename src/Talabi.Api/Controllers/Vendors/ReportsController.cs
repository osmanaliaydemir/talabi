using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers.Vendors;

/// <summary>
/// Vendor Dashboard - Raporlar ve istatistikler için controller
/// </summary>
[Route("api/vendors/dashboard/reports")]
[ApiController]
[Authorize]
public class ReportsController : BaseController
{
    private const string ResourceName = "VendorReportResources";

    /// <summary>
    /// ReportsController constructor
    /// </summary>
    public ReportsController(
        IUnitOfWork unitOfWork,
        ILogger<ReportsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    private async Task<Guid?> GetVendorIdAsync()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return null;
        }

        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    /// <summary>
    /// Satış raporunu getirir
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi (opsiyonel)</param>
    /// <param name="endDate">Bitiş tarihi (opsiyonel)</param>
    /// <param name="period">Periyot (day, week, month) - varsayılan: week</param>
    /// <returns>Satış raporu</returns>
    [HttpGet("sales")]
    public async Task<ActionResult<ApiResponse<SalesReportDto>>> GetSalesReport(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string period = "week")
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<SalesReportDto>(
                LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture),
                "NOT_A_VENDOR"));
        }

        // Set default date range based on period
        var now = DateTime.UtcNow;
        if (!startDate.HasValue || !endDate.HasValue)
        {
            endDate = now;
            startDate = period.ToLower() switch
            {
                "day" => now.Date,
                "week" => now.Date.AddDays(-7),
                "month" => now.Date.AddMonths(-1),
                _ => now.Date.AddDays(-7)
            };
        }

        var ordersQuery = UnitOfWork.Orders.Query()
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Where(o => o.VendorId == vendorId);

        ordersQuery = ordersQuery.WhereDateRange(o => o.CreatedAt, startDate, endDate);

        var orders = await ordersQuery.ToListAsync();

        var completedOrders = orders.Where(o => o.Status == OrderStatus.Delivered).ToList();
        var cancelledOrders = orders.Where(o => o.Status == OrderStatus.Cancelled).ToList();

        // Daily sales breakdown
        var dailySales = orders
            .GroupBy(o => o.CreatedAt.Date)
            .Select(g => new DailySalesDto
            {
                Date = g.Key,
                OrderCount = g.Count(),
                Revenue = g.Where(o => o.Status == OrderStatus.Delivered).Sum(o => o.TotalAmount)
            })
            .OrderBy(d => d.Date)
            .ToList();

        // Top products
        var topProducts = orders
            .Where(o => o.Status == OrderStatus.Delivered)
            .SelectMany(o => o.OrderItems)
            .GroupBy(oi => new { oi.ProductId, oi.Product!.Name })
            .Select(g => new ProductSalesDto
            {
                ProductId = g.Key.ProductId,
                ProductName = g.Key.Name,
                QuantitySold = g.Sum(oi => oi.Quantity),
                TotalRevenue = g.Sum(oi => oi.Quantity * oi.UnitPrice)
            })
            .OrderByDescending(p => p.TotalRevenue)
            .Take(10)
            .ToList();

        var report = new SalesReportDto
        {
            StartDate = startDate.Value,
            EndDate = endDate.Value,
            TotalOrders = orders.Count,
            TotalRevenue = completedOrders.Sum(o => o.TotalAmount),
            CompletedOrders = completedOrders.Count,
            CancelledOrders = cancelledOrders.Count,
            DailySales = dailySales,
            TopProducts = topProducts
        };

        return Ok(new ApiResponse<SalesReportDto>(
            report,
            LocalizationService.GetLocalizedString(ResourceName, "SalesReportRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı özet istatistiklerini getirir
    /// </summary>
    /// <returns>Satıcı özet istatistikleri</returns>
    [HttpGet("summary")]
    public async Task<ActionResult<ApiResponse<object>>> GetSummary()
    {
        Logger.LogInformation("GetSummary endpoint called");

        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            Logger.LogWarning("User ID is null or empty");
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        Logger.LogInformation("User ID retrieved: {UserId}", userId);

        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null)
        {
            Logger.LogWarning("Vendor not found for user ID: {UserId}", userId);
            return StatusCode(403, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture),
                "NOT_A_VENDOR"));
        }

        Logger.LogInformation("Vendor found: {VendorId}", vendor.Id);

        var vendorId = vendor.Id;
        var today = DateTime.UtcNow.Date;
        var thisWeek = today.AddDays(-7);
        var thisMonth = today.AddMonths(-1);

        Logger.LogInformation("Calculating summary for vendor {VendorId}. Today: {Today}, Week: {Week}, Month: {Month}",
            vendorId, today, thisWeek, thisMonth);

        var todayStart = DateTime.SpecifyKind(today, DateTimeKind.Utc);
        var todayEnd = todayStart.AddDays(1).AddTicks(-1);
        var weekStart = DateTime.SpecifyKind(thisWeek, DateTimeKind.Utc);
        var monthStart = DateTime.SpecifyKind(thisMonth, DateTimeKind.Utc);

        Logger.LogInformation("Date ranges - Today: {TodayStart} to {TodayEnd}, Week: {Week}, Month: {Month}",
            todayStart, todayEnd, weekStart, monthStart);

        // Today's orders
        var todayOrdersQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId);
        todayOrdersQuery = todayOrdersQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
        var todayOrders = await todayOrdersQuery.CountAsync();

        Logger.LogInformation("Today orders count: {Count}", todayOrders);

        // Today's revenue
        var todayRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        todayRevenueQuery = todayRevenueQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
        var todayRevenue = await todayRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Today revenue: {Revenue}", todayRevenue);

        // Pending orders
        var pendingOrders = await UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Pending)
            .CountAsync();

        Logger.LogInformation("Pending orders count: {Count}", pendingOrders);

        // Week revenue
        var weekRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        weekRevenueQuery = weekRevenueQuery.WhereDateRange(o => o.CreatedAt, weekStart, null);
        var weekRevenue = await weekRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Week revenue: {Revenue}", weekRevenue);

        // Month revenue
        var monthRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        monthRevenueQuery = monthRevenueQuery.WhereDateRange(o => o.CreatedAt, monthStart, null);
        var monthRevenue = await monthRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Month revenue: {Revenue}", monthRevenue);

        var result = new
        {
            todayOrders,
            todayRevenue,
            pendingOrders,
            weekRevenue,
            monthRevenue
        };

        Logger.LogInformation("Summary calculated successfully");
        return Ok(new ApiResponse<object>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "SummaryRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Saatlik satış raporunu getirir (Bugün için)
    /// </summary>
    /// <returns>Saatlik satış raporu ve büyüme oranları</returns>
    [HttpGet("hourly-sales")]
    public async Task<ActionResult<ApiResponse<List<HourlySalesDto>>>> GetHourlySales()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<List<HourlySalesDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture),
                "NOT_A_VENDOR"));
        }

        var today = DateTime.UtcNow.Date;
        var lastWeekSameDay = today.AddDays(-7);

        // Today's orders
        var todayOrders = await UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.CreatedAt >= today && o.CreatedAt < today.AddDays(1) &&
                        o.Status != OrderStatus.Cancelled)
            .Select(o => new { o.CreatedAt, o.TotalAmount })
            .ToListAsync();

        // Last week's orders
        var lastWeekOrders = await UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.CreatedAt >= lastWeekSameDay &&
                        o.CreatedAt < lastWeekSameDay.AddDays(1) && o.Status != OrderStatus.Cancelled)
            .Select(o => new { o.CreatedAt, o.TotalAmount })
            .ToListAsync();

        var result = new List<HourlySalesDto>();

        for (int i = 0; i < 24; i++)
        {
            var todayHourOrders = todayOrders.Where(o => o.CreatedAt.Hour == i).ToList();
            var lastWeekHourOrders = lastWeekOrders.Where(o => o.CreatedAt.Hour == i).ToList();

            var todayRevenue = todayHourOrders.Sum(o => o.TotalAmount);
            var lastWeekRevenue = lastWeekHourOrders.Sum(o => o.TotalAmount);

            double growthRate = 0;
            if (lastWeekRevenue > 0)
            {
                growthRate = (double)((todayRevenue - lastWeekRevenue) / lastWeekRevenue) * 100;
            }
            else if (todayRevenue > 0)
            {
                growthRate = 100;
            }

            result.Add(new HourlySalesDto
            {
                Hour = i,
                TotalRevenue = todayRevenue,
                OrderCount = todayHourOrders.Count,
                GrowthRate = growthRate
            });
        }

        return Ok(new ApiResponse<List<HourlySalesDto>>(result, "Success"));
    }

    /// <summary>
    /// Dashboard aksiyon kartlarını ve uyarılarını getirir
    /// </summary>
    /// <returns>Dashboard uyarıları</returns>
    [HttpGet("alerts")]
    public async Task<ActionResult<ApiResponse<DashboardAlertsDto>>> GetDashboardAlerts()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<DashboardAlertsDto>(
                LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture),
                "NOT_A_VENDOR"));
        }

        // 1. Critical Stock
        var lowStockThreshold = 10;
        var criticalProducts = await UnitOfWork.Products.Query()
            .Where(p => p.VendorId == vendorId && (p.Stock ?? 0) <= lowStockThreshold && p.IsAvailable)
            .Select(p => new ProductStockDto
            {
                Id = p.Id,
                Name = p.Name,
                Stock = p.Stock ?? 0
            })
            .ToListAsync();

        // 2. Delayed Orders
        var now = DateTime.UtcNow;
        var delayedOrdersQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status != OrderStatus.Delivered &&
                        o.Status != OrderStatus.Cancelled && o.Status != OrderStatus.Ready);

        var activeOrders = await delayedOrdersQuery
            .Include(o => o.OrderItems).ThenInclude(i => i.Product)
            .ToListAsync();

        var delayedOrders = activeOrders.Where(o =>
        {
            if (o.Status == OrderStatus.Pending) return (now - o.CreatedAt).TotalMinutes > 15;

            if (o.Status == OrderStatus.Preparing)
            {
                var maxPrep = o.OrderItems.Max(i => i.Product?.PreparationTime) ?? 30;
                return (now - o.CreatedAt).TotalMinutes > (maxPrep + 15);
            }

            return false;
        }).Select(o => new VendorOrderDto
        {
            Id = o.Id,
            CustomerOrderId = o.Id.ToString().Substring(0, 8).ToUpper(),
            TotalAmount = o.TotalAmount,
            Status = o.Status.ToString(),
            CreatedAt = o.CreatedAt,
            Items = o.OrderItems.Select(i => new VendorOrderItemDto
            {
                ProductId = i.ProductId,
                ProductName = i.Product.Name,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                TotalPrice = i.UnitPrice * i.Quantity,
                ProductImageUrl = i.Product.ImageUrl
            }).ToList()
        }).ToList();

        // 3. Unanswered Reviews
        var unansweredReviewsCount = await UnitOfWork.Reviews.Query()
            .Where(r => r.Product!.VendorId == vendorId && string.IsNullOrEmpty(r.Reply))
            .CountAsync();

        var alerts = new DashboardAlertsDto
        {
            CriticalStockCount = criticalProducts.Count,
            CriticalStockProducts = criticalProducts.Take(5).ToList(),
            DelayedOrdersCount = delayedOrders.Count,
            DelayedOrders = delayedOrders.Take(5).ToList(),
            UnansweredReviewsCount = unansweredReviewsCount
        };

        return Ok(new ApiResponse<DashboardAlertsDto>(alerts, "Success"));
    }
}

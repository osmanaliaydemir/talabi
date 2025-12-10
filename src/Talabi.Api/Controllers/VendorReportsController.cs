using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı rapor işlemleri için controller
/// </summary>
[Route("api/vendor/reports")]
[ApiController]
[Authorize]
public class VendorReportsController : BaseController
{
    private const string ResourceName = "VendorReportResources";

    /// <summary>
    /// VendorReportsController constructor
    /// </summary>
    public VendorReportsController(
        IUnitOfWork unitOfWork,
        ILogger<VendorReportsController> logger,
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

        // Tarih aralığı filtresi - Gelişmiş query helper kullanımı
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

        // Calculate date ranges with proper UTC handling
        var todayStart = DateTime.SpecifyKind(today, DateTimeKind.Utc);
        var todayEnd = todayStart.AddDays(1).AddTicks(-1);
        var weekStart = DateTime.SpecifyKind(thisWeek, DateTimeKind.Utc);
        var monthStart = DateTime.SpecifyKind(thisMonth, DateTimeKind.Utc);

        Logger.LogInformation("Date ranges - Today: {TodayStart} to {TodayEnd}, Week: {Week}, Month: {Month}",
            todayStart, todayEnd, weekStart, monthStart);

        // Today's orders (from start of today to end of today) - Tarih aralığı helper kullanımı
        var todayOrdersQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId);
        todayOrdersQuery = todayOrdersQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
        var todayOrders = await todayOrdersQuery.CountAsync();

        Logger.LogInformation("Today orders count: {Count}", todayOrders);

        // Today's revenue (only delivered orders) - Tarih aralığı helper kullanımı
        var todayRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        todayRevenueQuery = todayRevenueQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
        var todayRevenue = await todayRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Today revenue: {Revenue}", todayRevenue);

        // Pending orders (all time, not filtered by date)
        var pendingOrders = await UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Pending)
            .CountAsync();

        Logger.LogInformation("Pending orders count: {Count}", pendingOrders);

        // Week revenue (last 7 days, only delivered orders) - Tarih aralığı helper kullanımı
        var weekRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        weekRevenueQuery = weekRevenueQuery.WhereDateRange(o => o.CreatedAt, weekStart, null);
        var weekRevenue = await weekRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Week revenue: {Revenue}", weekRevenue);

        // Month revenue (last 30 days, only delivered orders) - Tarih aralığı helper kullanımı
        var monthRevenueQuery = UnitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
        monthRevenueQuery = monthRevenueQuery.WhereDateRange(o => o.CreatedAt, monthStart, null);
        var monthRevenue = await monthRevenueQuery
            .Select(o => (decimal?)o.TotalAmount)
            .SumAsync() ?? 0;

        Logger.LogInformation("Month revenue: {Revenue}", monthRevenue);

        var result = new
        {
            todayOrders = todayOrders,
            todayRevenue = todayRevenue,
            pendingOrders = pendingOrders,
            weekRevenue = weekRevenue,
            monthRevenue = monthRevenue
        };

        Logger.LogInformation("Summary calculated successfully");
        return Ok(new ApiResponse<object>(
            result, 
            LocalizationService.GetLocalizedString(ResourceName, "SummaryRetrievedSuccessfully", CurrentCulture)));
    }
}


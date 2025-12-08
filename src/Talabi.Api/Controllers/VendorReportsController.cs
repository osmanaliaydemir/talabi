using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
public class VendorReportsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<VendorReportsController> _logger;

    /// <summary>
    /// VendorReportsController constructor
    /// </summary>
    public VendorReportsController(IUnitOfWork unitOfWork, ILogger<VendorReportsController> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? throw new UnauthorizedAccessException();

    private async Task<Guid?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _unitOfWork.Vendors.Query()
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
    public async Task<ActionResult<ApiResponse<SalesReportDto>>> GetSalesReport([FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null,
        [FromQuery] string period = "week") // day, week, month
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<SalesReportDto>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
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
        var ordersQuery = _unitOfWork.Orders.Query()
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

        return Ok(new ApiResponse<SalesReportDto>(report, "Satış raporu başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcı özet istatistiklerini getirir
    /// </summary>
    /// <returns>Satıcı özet istatistikleri</returns>
    [HttpGet("summary")]
    public async Task<ActionResult<ApiResponse<object>>> GetSummary()
    {
        try
        {
            _logger.LogInformation("GetSummary endpoint called");

            string? userId;
            try
            {
                userId = GetUserId();
                _logger.LogInformation("User ID retrieved: {UserId}", userId);
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning(ex, "User is not authenticated");
                return Unauthorized(new ApiResponse<object>("Kullanıcı kimlik doğrulaması yapılmamış", "UNAUTHORIZED"));
            }

            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("User ID is null or empty");
                return Unauthorized(new ApiResponse<object>("Kullanıcı kimlik doğrulaması yapılmamış", "UNAUTHORIZED"));
            }

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId);

            if (vendor == null)
            {
                _logger.LogWarning("Vendor not found for user ID: {UserId}", userId);
                return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
            }

            _logger.LogInformation("Vendor found: {VendorId}", vendor.Id);

            var vendorId = vendor.Id;
            var today = DateTime.UtcNow.Date;
            var thisWeek = today.AddDays(-7);
            var thisMonth = today.AddMonths(-1);

            _logger.LogInformation("Calculating summary for vendor {VendorId}. Today: {Today}, Week: {Week}, Month: {Month}",
                vendorId, today, thisWeek, thisMonth);

            try
            {
                // Calculate date ranges with proper UTC handling
                var todayStart = DateTime.SpecifyKind(today, DateTimeKind.Utc);
                var todayEnd = todayStart.AddDays(1).AddTicks(-1);
                var weekStart = DateTime.SpecifyKind(thisWeek, DateTimeKind.Utc);
                var monthStart = DateTime.SpecifyKind(thisMonth, DateTimeKind.Utc);

                _logger.LogInformation("Date ranges - Today: {TodayStart} to {TodayEnd}, Week: {Week}, Month: {Month}",
                    todayStart, todayEnd, weekStart, monthStart);

                // Today's orders (from start of today to end of today) - Tarih aralığı helper kullanımı
                var todayOrdersQuery = _unitOfWork.Orders.Query()
                    .Where(o => o.VendorId == vendorId);
                todayOrdersQuery = todayOrdersQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
                var todayOrders = await todayOrdersQuery.CountAsync();

                _logger.LogInformation("Today orders count: {Count}", todayOrders);

                // Today's revenue (only delivered orders) - Tarih aralığı helper kullanımı
                var todayRevenueQuery = _unitOfWork.Orders.Query()
                    .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
                todayRevenueQuery = todayRevenueQuery.WhereDateRange(o => o.CreatedAt, todayStart, todayEnd);
                var todayRevenue = await todayRevenueQuery
                    .Select(o => (decimal?)o.TotalAmount)
                    .SumAsync() ?? 0;

                _logger.LogInformation("Today revenue: {Revenue}", todayRevenue);

                // Pending orders (all time, not filtered by date)
                var pendingOrders = await _unitOfWork.Orders.Query()
                    .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Pending)
                    .CountAsync();

                _logger.LogInformation("Pending orders count: {Count}", pendingOrders);

                // Week revenue (last 7 days, only delivered orders) - Tarih aralığı helper kullanımı
                var weekRevenueQuery = _unitOfWork.Orders.Query()
                    .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
                weekRevenueQuery = weekRevenueQuery.WhereDateRange(o => o.CreatedAt, weekStart, null);
                var weekRevenue = await weekRevenueQuery
                    .Select(o => (decimal?)o.TotalAmount)
                    .SumAsync() ?? 0;

                _logger.LogInformation("Week revenue: {Revenue}", weekRevenue);

                // Month revenue (last 30 days, only delivered orders) - Tarih aralığı helper kullanımı
                var monthRevenueQuery = _unitOfWork.Orders.Query()
                    .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);
                monthRevenueQuery = monthRevenueQuery.WhereDateRange(o => o.CreatedAt, monthStart, null);
                var monthRevenue = await monthRevenueQuery
                    .Select(o => (decimal?)o.TotalAmount)
                    .SumAsync() ?? 0;

                _logger.LogInformation("Month revenue: {Revenue}", monthRevenue);

                var result = new
                {
                    todayOrders = todayOrders,
                    todayRevenue = todayRevenue,
                    pendingOrders = pendingOrders,
                    weekRevenue = weekRevenue,
                    monthRevenue = monthRevenue
                };

                _logger.LogInformation("Summary calculated successfully");
                return Ok(new ApiResponse<object>(result, "Satıcı özet istatistikleri başarıyla getirildi"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating summary for vendor {VendorId}", vendorId);
                return StatusCode(500, new ApiResponse<object>(
                    "Satıcı özet istatistikleri hesaplanırken bir hata oluştu",
                    "CALCULATION_ERROR",
                    new List<string> { ex.Message, ex.InnerException?.Message ?? string.Empty }));
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error in GetSummary endpoint");
            return StatusCode(500, new ApiResponse<object>(
                "Satıcı özet istatistikleri getirilirken bir hata oluştu",
                "UNEXPECTED_ERROR",
                new List<string> { ex.Message, ex.InnerException?.Message ?? string.Empty }));
        }
    }
}


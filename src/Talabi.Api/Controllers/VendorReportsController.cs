using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/reports")]
[ApiController]
[Authorize]
public class VendorReportsController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<VendorReportsController> _logger;

    public VendorReportsController(TalabiDbContext context, ILogger<VendorReportsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? throw new UnauthorizedAccessException();

    private async Task<Guid?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    [HttpGet("sales")]
    public async Task<ActionResult<SalesReportDto>> GetSalesReport(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string period = "week") // day, week, month
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
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

        var orders = await _context.Orders
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Where(o => o.VendorId == vendorId &&
                       o.CreatedAt >= startDate.Value &&
                       o.CreatedAt <= endDate.Value)
            .ToListAsync();

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

        return Ok(report);
    }

    [HttpGet("summary")]
    public async Task<ActionResult> GetSummary()
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
                return Unauthorized(new { error = "User is not authenticated" });
            }

            if (string.IsNullOrEmpty(userId))
            {
                _logger.LogWarning("User ID is null or empty");
                return Unauthorized(new { error = "User is not authenticated" });
            }

            var vendor = await _context.Vendors
                .FirstOrDefaultAsync(v => v.OwnerId == userId);

            if (vendor == null)
            {
                _logger.LogWarning("Vendor not found for user ID: {UserId}", userId);
                return Forbid("User is not a vendor");
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

                // Today's orders (from start of today to end of today)
                var todayOrders = await _context.Orders
                    .Where(o => o.VendorId == vendorId &&
                               o.CreatedAt >= todayStart &&
                               o.CreatedAt <= todayEnd)
                    .CountAsync();

                _logger.LogInformation("Today orders count: {Count}", todayOrders);

                // Today's revenue (only delivered orders)
                var todayRevenue = await _context.Orders
                    .Where(o => o.VendorId == vendorId &&
                               o.CreatedAt >= todayStart &&
                               o.CreatedAt <= todayEnd &&
                               o.Status == OrderStatus.Delivered)
                    .Select(o => (decimal?)o.TotalAmount)
                    .SumAsync() ?? 0;

                _logger.LogInformation("Today revenue: {Revenue}", todayRevenue);

                // Pending orders (all time, not filtered by date)
                var pendingOrders = await _context.Orders
                    .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Pending)
                    .CountAsync();

                _logger.LogInformation("Pending orders count: {Count}", pendingOrders);

                // Week revenue (last 7 days, only delivered orders)
                var weekRevenue = await _context.Orders
                    .Where(o => o.VendorId == vendorId &&
                               o.CreatedAt >= weekStart &&
                               o.Status == OrderStatus.Delivered)
                    .Select(o => (decimal?)o.TotalAmount)
                    .SumAsync() ?? 0;

                _logger.LogInformation("Week revenue: {Revenue}", weekRevenue);

                // Month revenue (last 30 days, only delivered orders)
                var monthRevenue = await _context.Orders
                    .Where(o => o.VendorId == vendorId &&
                               o.CreatedAt >= monthStart &&
                               o.Status == OrderStatus.Delivered)
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
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating summary for vendor {VendorId}", vendorId);
                return StatusCode(500, new
                {
                    error = "An error occurred while calculating vendor summary",
                    message = ex.Message,
                    innerException = ex.InnerException?.Message
                });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error in GetSummary endpoint");
            return StatusCode(500, new
            {
                error = "An error occurred while fetching vendor summary",
                message = ex.Message,
                innerException = ex.InnerException?.Message,
                stackTrace = ex.StackTrace
            });
        }
    }
}


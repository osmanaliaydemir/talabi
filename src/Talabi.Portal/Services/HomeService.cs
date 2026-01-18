using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Portal.Services;

public class HomeService : IHomeService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<HomeService> _logger;

    public HomeService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<HomeService> logger)
    {
        _unitOfWork = unitOfWork;
        _userContextService = userContextService;
        _logger = logger;
    }

    public async Task<VendorProfileDto?> GetProfileAsync(CancellationToken ct = default)
    {
        try
        {
            var userId = _userContextService.GetUserId();
            if (string.IsNullOrEmpty(userId)) return null;

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

            if (vendor == null) return null;

            return new VendorProfileDto
            {
                Id = vendor.Id,
                Name = vendor.Name,
                ImageUrl = vendor.ImageUrl,
                Address = vendor.Address,
                City = vendor.City,
                Latitude = vendor.Latitude ?? 0,
                Longitude = vendor.Longitude ?? 0,
                PhoneNumber = vendor.PhoneNumber,
                Description = vendor.Description,
                Rating = (double)(vendor.Rating ?? 0),
                RatingCount = vendor.RatingCount
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vendor profile");
            return null;
        }
    }
    public async Task<HomeViewModel> GetDashboardStatsAsync(CancellationToken ct = default)
    {
        var viewModel = new HomeViewModel();
        try
        {
            var userId = _userContextService.GetUserId();
            if (string.IsNullOrEmpty(userId)) return viewModel;

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

            if (vendor == null) return viewModel;

            var today = DateTime.UtcNow.Date;
            var todayStart = DateTime.SpecifyKind(today, DateTimeKind.Utc);
            var todayEnd = todayStart.AddDays(1).AddTicks(-1);

            // 1. Dashboard Stats (Today)
            viewModel.PendingOrdersCount = await _unitOfWork.Orders.Query()
                .CountAsync(o => o.VendorId == vendor.Id && o.Status == Talabi.Core.Enums.OrderStatus.Pending, ct);

            viewModel.CompletedOrdersToday = await _unitOfWork.Orders.Query()
                .CountAsync(o => o.VendorId == vendor.Id &&
                               o.Status == Talabi.Core.Enums.OrderStatus.Delivered &&
                               o.CreatedAt >= todayStart &&
                               o.CreatedAt <= todayEnd, ct);

            viewModel.TotalRevenueToday = await _unitOfWork.Orders.Query()
                .Where(o => o.VendorId == vendor.Id &&
                            o.Status == Talabi.Core.Enums.OrderStatus.Delivered &&
                            o.CreatedAt >= todayStart &&
                            o.CreatedAt <= todayEnd)
                .SumAsync(o => o.TotalAmount, ct);

            // 2. Enriched Summary Stats (All Time)
            var stats = await _unitOfWork.Orders.Query()
                .Where(o => o.VendorId == vendor.Id)
                .GroupBy(o => 1)
                .Select(g => new
                {
                    TotalCount = g.Count(),
                    CancelledCount = g.Count(o => o.Status == Talabi.Core.Enums.OrderStatus.Cancelled),
                    CompletedCount = g.Count(o => o.Status == Talabi.Core.Enums.OrderStatus.Delivered),
                    TotalRevenue = g.Where(o => o.Status == Talabi.Core.Enums.OrderStatus.Delivered).Sum(o => o.TotalAmount)
                })
                .FirstOrDefaultAsync(ct);

            var totalOrders = stats?.TotalCount ?? 0;
            var cancelledOrders = stats?.CancelledCount ?? 0;
            var completedOrders = stats?.CompletedCount ?? 0;
            var totalAllTimeRevenue = stats?.TotalRevenue ?? 0;

            viewModel.AverageOrderValue = completedOrders > 0 ? Math.Round(totalAllTimeRevenue / completedOrders, 2) : 0;
            viewModel.CancellationRate = totalOrders > 0 ? Math.Round((double)cancelledOrders / totalOrders, 4) : 0;

            // 3. Active Products
            viewModel.ActiveProductsCount = await _unitOfWork.Products.Query()
                .CountAsync(p => p.VendorId == vendor.Id && p.IsAvailable, ct);

            // 4. Recent Activities
            var notifications = await _unitOfWork.VendorNotifications.Query()
                .Where(n => n.VendorId == vendor.Id)
                .OrderByDescending(n => n.CreatedAt)
                .Take(10)
                .ToListAsync(ct);

            viewModel.RecentActivities = notifications.Select(n => new DashboardActivity
            {
                Title = n.Title,
                Message = n.Message,
                CreatedAt = n.CreatedAt,
                Type = n.Type
            }).ToList();

            // 5. Sales Trend (Last 30 Days)
            var last30Days = todayEnd.AddDays(-30);
            var salesTrendData = await _unitOfWork.Orders.Query()
                .Where(o => o.VendorId == vendor.Id &&
                            o.Status == Talabi.Core.Enums.OrderStatus.Delivered &&
                            o.CreatedAt >= last30Days)
                .GroupBy(o => o.CreatedAt.Date)
                .Select(g => new
                {
                    Date = g.Key,
                    Amount = g.Sum(o => o.TotalAmount),
                    Count = g.Count()
                })
                .OrderBy(x => x.Date)
                .ToListAsync(ct);

            viewModel.SalesTrend = salesTrendData.Select(x => new SalesTrendItem
            {
                Date = x.Date.ToString("dd MMM", new System.Globalization.CultureInfo("tr-TR")),
                Amount = x.Amount,
                Count = x.Count
            }).ToList();

            // 6. Order Status Distribution
            var statusData = await _unitOfWork.Orders.Query()
                .Where(o => o.VendorId == vendor.Id)
                .GroupBy(o => o.Status)
                .Select(g => new
                {
                    Status = g.Key,
                    Count = g.Count()
                })
                .ToListAsync(ct);

            viewModel.OrderStatusDistribution = statusData.Select(x => new OrderStatusItem
            {
                Status = x.Status.ToString(),
                Count = x.Count
            }).ToList();

            // 7. Category Revenue (Based on delivered orders)
            // Note: This requires joining OrderItems -> Product -> Category
            // Since we use IRepository, we might need direct access or Include.
            // Assuming we can access OrderItems directly via UnitOfWork.
            var categoryData = await _unitOfWork.OrderItems.Query()
                .Include(oi => oi.Product)
                .ThenInclude(p => p!.ProductCategory)
                .Include(oi => oi.Order)
                .Where(oi => oi.Order != null &&
                             oi.Order.VendorId == vendor.Id &&
                             oi.Order.Status == Talabi.Core.Enums.OrderStatus.Delivered)
                .GroupBy(oi =>
                    oi.Product != null && oi.Product.ProductCategory != null
                        ? oi.Product.ProductCategory.Name
                        : "Uncategorized")
                .Select(g => new
                {
                    CategoryName = g.Key,
                    Revenue = g.Sum(oi => oi.Quantity * oi.UnitPrice),
                    Count = g.Count()
                })
                .OrderByDescending(x => x.Revenue)
                .Take(5)
                .ToListAsync(ct);

            viewModel.Categoryrevenue = categoryData.Select(x => new CategoryRevenueItem
            {
                CategoryName = x.CategoryName,
                Revenue = x.Revenue,
                OrderCount = x.Count
            }).ToList();

            // 8. Top Products
            var topProductsData = await _unitOfWork.OrderItems.Query()
                .Include(oi => oi.Product)
                .Include(oi => oi.Order)
                .Where(oi => oi.Order != null &&
                             oi.Order.VendorId == vendor.Id &&
                             oi.Order.Status == Talabi.Core.Enums.OrderStatus.Delivered &&
                             oi.Product != null)
                .GroupBy(oi => new { oi.Product!.Name, oi.Product.ImageUrl })
                .Select(g => new
                {
                    ProductName = g.Key.Name,
                    ImageUrl = g.Key.ImageUrl,
                    Quantity = g.Sum(oi => oi.Quantity),
                    Revenue = g.Sum(oi => oi.Quantity * oi.UnitPrice)
                })
                .OrderByDescending(x => x.Quantity)
                .Take(5)
                .ToListAsync(ct);

            viewModel.TopProducts = topProductsData.Select(x => new TopProductItem
            {
                ProductName = x.ProductName,
                ImageUrl = x.ImageUrl,
                QuantitySold = x.Quantity,
                TotalRevenue = x.Revenue
            }).ToList();

            return viewModel;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating dashboard stats");
            return viewModel;
        }
    }
}

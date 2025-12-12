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

            return viewModel;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating dashboard stats");
            return viewModel;
        }
    }
}

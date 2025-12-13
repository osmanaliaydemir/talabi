using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class DashboardNotificationService : IDashboardNotificationService
{
    private readonly TalabiDbContext _dbContext;

    public DashboardNotificationService(TalabiDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<List<VendorNotification>> GetRecentNotificationsAsync(Guid vendorId, int count = 5)
    {
        return await _dbContext.VendorNotifications
            .Where(n => n.VendorId == vendorId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(count)
            .ToListAsync();
    }

    public async Task<List<VendorNotification>> GetAllNotificationsAsync(Guid vendorId, int page = 1, int pageSize = 20)
    {
        return await _dbContext.VendorNotifications
            .Where(n => n.VendorId == vendorId)
            .OrderByDescending(n => n.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }

    public async Task<int> GetUnreadCountAsync(Guid vendorId)
    {
        return await _dbContext.VendorNotifications
            .CountAsync(n => n.VendorId == vendorId && !n.IsRead);
    }

    public async Task MarkAsReadAsync(Guid notificationId, Guid vendorId)
    {
        var notification = await _dbContext.VendorNotifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.VendorId == vendorId);

        if (notification != null && !notification.IsRead)
        {
            notification.IsRead = true;
            await _dbContext.SaveChangesAsync();
        }
    }

    public async Task MarkAllAsReadAsync(Guid vendorId)
    {
        var notifications = await _dbContext.VendorNotifications
            .Where(n => n.VendorId == vendorId && !n.IsRead)
            .ToListAsync();

        if (notifications.Any())
        {
            foreach (var notification in notifications)
            {
                notification.IsRead = true;
            }
            await _dbContext.SaveChangesAsync();
        }
    }
}

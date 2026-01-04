using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

public interface IDashboardNotificationService
{
    Task<List<VendorNotification>> GetRecentNotificationsAsync(Guid vendorId, int count = 5);
    Task<List<VendorNotification>> GetAllNotificationsAsync(Guid vendorId, int page = 1, int pageSize = 20);
    Task<int> GetUnreadCountAsync(Guid vendorId);
    Task MarkAsReadAsync(Guid notificationId, Guid vendorId);
    Task MarkAllAsReadAsync(Guid vendorId);

    Task CreateNotificationAsync(Guid vendorId, string title, string message, string type,
        Guid? relatedEntityId = null);
}

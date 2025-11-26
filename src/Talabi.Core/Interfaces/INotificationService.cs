namespace Talabi.Core.Interfaces;

public interface INotificationService
{
    Task SendOrderAssignmentNotificationAsync(string userId, int orderId);
    Task SendOrderStatusUpdateNotificationAsync(string userId, int orderId, string status);
}

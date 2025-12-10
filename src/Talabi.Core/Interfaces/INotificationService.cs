using System.Threading.Tasks;

namespace Talabi.Core.Interfaces
{
    public interface INotificationService
    {
        Task SendNotificationAsync(string token, string title, string body, object? data = null);
        Task SendMulticastNotificationAsync(List<string> tokens, string title, string body, object? data = null);
        Task RegisterDeviceTokenAsync(string userId, string token, string deviceType);
        Task SendOrderAssignmentNotificationAsync(string userId, Guid orderId, string? languageCode = null);
        Task SendOrderStatusUpdateNotificationAsync(string userId, Guid orderId, string status, string? languageCode = null);
    }
}

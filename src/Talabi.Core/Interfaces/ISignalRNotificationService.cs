using System.Threading.Tasks;

namespace Talabi.Core.Interfaces
{
    public interface ISignalRNotificationService : INotificationService
    {
        Task SendOrderAssignmentNotificationAsync(string userId, Guid orderId, string? languageCode = null);
    }
}

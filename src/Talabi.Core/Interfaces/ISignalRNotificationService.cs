using System.Threading.Tasks;

namespace Talabi.Core.Interfaces
{
    public interface ISignalRNotificationService : INotificationService
    {
        /// <summary>
        /// Kuryeye sipariş atama bildirimi gönderir (Grup tabanlı - courierId ile)
        /// </summary>
        Task SendOrderAssignmentNotificationToCourierAsync(Guid courierId, Guid orderId, string? languageCode = null);
    }
}

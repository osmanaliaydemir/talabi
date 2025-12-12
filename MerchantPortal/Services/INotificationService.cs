using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface INotificationService
{
	Task<PagedResult<NotificationResponse>?> GetMyNotificationsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<bool> MarkAsReadAsync(List<Guid> notificationIds, CancellationToken ct = default);
	Task<NotificationPreferencesResponse?> GetPreferencesAsync(CancellationToken ct = default);
	Task<bool> UpdatePreferencesAsync(UpdateNotificationPreferencesRequest request, CancellationToken ct = default);
}



using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IPlatformAdminPortalService
{
    Task<AdminDashboardResponse?> GetDashboardAsync(CancellationToken ct = default);
    Task<SystemStatisticsResponse?> GetSystemStatisticsAsync(CancellationToken ct = default);
    Task<PagedResult<RecentMerchantApplicationResponse>?> GetMerchantApplicationsAsync(PaginationQueryRequest request, CancellationToken ct = default);
    Task<List<AdminNotificationResponse>> GetSystemNotificationsAsync(CancellationToken ct = default);
    Task<bool> MarkNotificationAsReadAsync(Guid notificationId, CancellationToken ct = default);
}



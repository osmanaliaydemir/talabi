namespace Getir.MerchantPortal.Models;

public class PlatformAdminDashboardViewModel
{
    public AdminDashboardResponse? Dashboard { get; set; }
    public SystemStatisticsResponse? SystemStatistics { get; set; }
    public PagedResult<RecentMerchantApplicationResponse>? MerchantApplications { get; set; }
    public List<AdminNotificationResponse> Notifications { get; set; } = new();
    public PaginationQueryRequest Pagination { get; set; } = new();
}



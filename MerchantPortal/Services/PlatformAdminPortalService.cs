using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.WebUtilities;

namespace Getir.MerchantPortal.Services;

public class PlatformAdminPortalService : IPlatformAdminPortalService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<PlatformAdminPortalService> _logger;

    public PlatformAdminPortalService(IApiClient apiClient, ILogger<PlatformAdminPortalService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<AdminDashboardResponse?> GetDashboardAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<AdminDashboardResponse>>("api/v1/Admin/dashboard", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch admin dashboard");
            return null;
        }
    }

    public async Task<SystemStatisticsResponse?> GetSystemStatisticsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<SystemStatisticsResponse>>("api/v1/Admin/statistics", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch system statistics");
            return null;
        }
    }

    public async Task<PagedResult<RecentMerchantApplicationResponse>?> GetMerchantApplicationsAsync(PaginationQueryRequest request, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["page"] = request.Page.ToString(),
                ["pageSize"] = request.PageSize.ToString()
            };

            var url = QueryHelpers.AddQueryString("api/v1/Admin/merchants/applications", query);
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<RecentMerchantApplicationResponse>>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch merchant applications");
            return null;
        }
    }

    public async Task<List<AdminNotificationResponse>> GetSystemNotificationsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<AdminNotificationResponse>>>("api/v1/Admin/notifications", ct);
            return response?.Data ?? new List<AdminNotificationResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch system notifications");
            return new List<AdminNotificationResponse>();
        }
    }

    public async Task<bool> MarkNotificationAsReadAsync(Guid notificationId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<object>>($"api/v1/Admin/notifications/{notificationId}/read", new { }, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to mark notification {NotificationId} as read", notificationId);
            return false;
        }
    }
}



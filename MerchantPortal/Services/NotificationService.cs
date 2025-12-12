using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class NotificationService : INotificationService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<NotificationService> _logger;

	public NotificationService(IApiClient apiClient, ILogger<NotificationService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<NotificationResponse>?> GetMyNotificationsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<PagedResult<NotificationResponse>>>($"api/v1/notification?page={page}&pageSize={pageSize}", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting notifications");
			return null;
		}
	}

	public async Task<bool> MarkAsReadAsync(List<Guid> notificationIds, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<object>>("api/v1/notification/mark-as-read", new { NotificationIds = notificationIds }, ct);
			return res?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error marking notifications as read");
			return false;
		}
	}

	public async Task<NotificationPreferencesResponse?> GetPreferencesAsync(CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<NotificationPreferencesResponse>>("api/v1/notification/preferences", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting notification preferences");
			return null;
		}
	}

	public async Task<bool> UpdatePreferencesAsync(UpdateNotificationPreferencesRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PutAsync<ApiResponse<object>>("api/v1/notification/preferences", request, ct);
			return res?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating notification preferences");
			return false;
		}
	}
}



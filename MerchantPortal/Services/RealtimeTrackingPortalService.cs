using System;
using System.Collections.Generic;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class RealtimeTrackingPortalService : IRealtimeTrackingPortalService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<RealtimeTrackingPortalService> _logger;

    public RealtimeTrackingPortalService(IApiClient apiClient, ILogger<RealtimeTrackingPortalService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<OrderTrackingResponse>> GetActiveTrackingsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<OrderTrackingResponse>>>("api/realtimetracking/active", ct);
            return response?.Data ?? new List<OrderTrackingResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch active trackings");
            return new List<OrderTrackingResponse>();
        }
    }

    public async Task<OrderTrackingResponse?> GetTrackingByIdAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<OrderTrackingResponse>>($"api/realtimetracking/{trackingId}", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch tracking by id {TrackingId}", trackingId);
            return null;
        }
    }

    public async Task<OrderTrackingResponse?> GetTrackingByOrderIdAsync(Guid orderId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<OrderTrackingResponse>>($"api/realtimetracking/order/{orderId}", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch tracking by order {OrderId}", orderId);
            return null;
        }
    }

    public async Task<bool> UpdateStatusAsync(StatusUpdateRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<StatusUpdateResponse>>("api/realtimetracking/status/update", request, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update tracking status for {TrackingId}", request.OrderTrackingId);
            return false;
        }
    }

    public async Task<bool> UpdateLocationAsync(LocationUpdateRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<LocationUpdateResponse>>("api/realtimetracking/location/update", request, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update tracking location for {TrackingId}", request.OrderTrackingId);
            return false;
        }
    }

    public async Task<List<TrackingNotificationResponse>> GetNotificationsAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<TrackingNotificationResponse>>>($"api/realtimetracking/{trackingId}/notifications", ct);
            return response?.Data ?? new List<TrackingNotificationResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch tracking notifications for {TrackingId}", trackingId);
            return new List<TrackingNotificationResponse>();
        }
    }

    public async Task<TrackingEtaResponse?> GetCurrentEtaAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.GetAsync<TrackingEtaResponse>($"api/realtimetracking/{trackingId}/eta", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch current ETA for tracking {TrackingId}", trackingId);
            return null;
        }
    }

    public async Task<List<TrackingEtaResponse>> GetEtaHistoryAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<List<TrackingEtaResponse>>($"api/realtimetracking/{trackingId}/eta/history", ct);
            return response ?? new List<TrackingEtaResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch ETA history for tracking {TrackingId}", trackingId);
            return new List<TrackingEtaResponse>();
        }
    }

    public async Task<Dictionary<string, object>> GetTrackingMetricsAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<Dictionary<string, object>>($"api/realtimetracking/{trackingId}/metrics", ct);
            return response != null
                ? new Dictionary<string, object>(response, StringComparer.OrdinalIgnoreCase)
                : new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch metrics for tracking {TrackingId}", trackingId);
            return new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
        }
    }

    public async Task<List<LocationHistoryResponse>> GetLocationHistoryAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<List<LocationHistoryResponse>>($"api/realtimetracking/{trackingId}/history", ct);
            return response ?? new List<LocationHistoryResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch location history for tracking {TrackingId}", trackingId);
            return new List<LocationHistoryResponse>();
        }
    }

    public async Task<bool> IsTrackingActiveAsync(Guid trackingId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<TrackingActiveResponse>($"api/realtimetracking/{trackingId}/active", ct);
            return response?.IsActive ?? false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to check if tracking {TrackingId} is active", trackingId);
            return false;
        }
    }

    public async Task<bool> MarkNotificationAsReadAsync(Guid notificationId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.PutAsync($"api/realtimetracking/notifications/{notificationId}/read", new { }, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to mark notification {NotificationId} as read", notificationId);
            return false;
        }
    }

    public async Task<bool> DeleteNotificationAsync(Guid notificationId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.DeleteAsync($"api/realtimetracking/notifications/{notificationId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete notification {NotificationId}", notificationId);
            return false;
        }
    }

    public async Task<TrackingSettingsResponse?> GetMerchantSettingsAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.GetAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/merchant/{merchantId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch merchant tracking settings for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    public async Task<TrackingSettingsResponse?> SaveMerchantSettingsAsync(Guid merchantId, UpdateTrackingSettingsRequestModel request, bool isUpdate, CancellationToken ct = default)
    {
        try
        {
            TrackingSettingsResponse? response;
            if (isUpdate)
            {
                response = await _apiClient.PutAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/merchant/{merchantId}", request, ct);
            }
            else
            {
                response = await _apiClient.PostAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/merchant/{merchantId}", request, ct);
            }

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save merchant tracking settings for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    public async Task<bool> DeleteMerchantSettingsAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.DeleteAsync($"api/realtimetracking/settings/merchant/{merchantId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete merchant tracking settings for merchant {MerchantId}", merchantId);
            return false;
        }
    }

    public async Task<TrackingSettingsResponse?> GetUserSettingsAsync(Guid userId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.GetAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/user/{userId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch user tracking settings for user {UserId}", userId);
            return null;
        }
    }

    public async Task<TrackingSettingsResponse?> SaveUserSettingsAsync(Guid userId, UpdateTrackingSettingsRequestModel request, bool isUpdate, CancellationToken ct = default)
    {
        try
        {
            TrackingSettingsResponse? response;
            if (isUpdate)
            {
                response = await _apiClient.PutAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/user/{userId}", request, ct);
            }
            else
            {
                response = await _apiClient.PostAsync<TrackingSettingsResponse>($"api/realtimetracking/settings/user/{userId}", request, ct);
            }

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save user tracking settings for user {UserId}", userId);
            return null;
        }
    }

    public async Task<bool> DeleteUserSettingsAsync(Guid userId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.DeleteAsync($"api/realtimetracking/settings/user/{userId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete user tracking settings for user {UserId}", userId);
            return false;
        }
    }
}


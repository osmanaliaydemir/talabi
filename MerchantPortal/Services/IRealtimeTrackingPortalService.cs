using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IRealtimeTrackingPortalService
{
    Task<List<OrderTrackingResponse>> GetActiveTrackingsAsync(CancellationToken ct = default);
    Task<OrderTrackingResponse?> GetTrackingByIdAsync(Guid trackingId, CancellationToken ct = default);
    Task<OrderTrackingResponse?> GetTrackingByOrderIdAsync(Guid orderId, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(StatusUpdateRequestModel request, CancellationToken ct = default);
    Task<bool> UpdateLocationAsync(LocationUpdateRequestModel request, CancellationToken ct = default);
    Task<List<TrackingNotificationResponse>> GetNotificationsAsync(Guid trackingId, CancellationToken ct = default);
    Task<TrackingEtaResponse?> GetCurrentEtaAsync(Guid trackingId, CancellationToken ct = default);
    Task<List<TrackingEtaResponse>> GetEtaHistoryAsync(Guid trackingId, CancellationToken ct = default);
    Task<Dictionary<string, object>> GetTrackingMetricsAsync(Guid trackingId, CancellationToken ct = default);
    Task<List<LocationHistoryResponse>> GetLocationHistoryAsync(Guid trackingId, CancellationToken ct = default);
    Task<bool> IsTrackingActiveAsync(Guid trackingId, CancellationToken ct = default);
    Task<bool> MarkNotificationAsReadAsync(Guid notificationId, CancellationToken ct = default);
    Task<bool> DeleteNotificationAsync(Guid notificationId, CancellationToken ct = default);
    Task<TrackingSettingsResponse?> GetMerchantSettingsAsync(Guid merchantId, CancellationToken ct = default);
    Task<TrackingSettingsResponse?> SaveMerchantSettingsAsync(Guid merchantId, UpdateTrackingSettingsRequestModel request, bool isUpdate, CancellationToken ct = default);
    Task<bool> DeleteMerchantSettingsAsync(Guid merchantId, CancellationToken ct = default);
    Task<TrackingSettingsResponse?> GetUserSettingsAsync(Guid userId, CancellationToken ct = default);
    Task<TrackingSettingsResponse?> SaveUserSettingsAsync(Guid userId, UpdateTrackingSettingsRequestModel request, bool isUpdate, CancellationToken ct = default);
    Task<bool> DeleteUserSettingsAsync(Guid userId, CancellationToken ct = default);
}


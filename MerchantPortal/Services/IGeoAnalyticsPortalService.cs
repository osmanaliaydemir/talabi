using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IGeoAnalyticsPortalService
{
    Task<LocationAnalyticsResponseModel?> GetLocationAnalyticsAsync(DateTime? startDate = null, DateTime? endDate = null, CancellationToken ct = default);
    Task<DeliveryZoneCoverageResponseModel?> GetDeliveryZoneCoverageAsync(CancellationToken ct = default);
    Task<List<UserLocationResponseModel>> GetLocationHistoryAsync(PaginationQueryRequest request, CancellationToken ct = default);
    Task<List<NearbyMerchantResponse>> GetNearbyMerchantsAsync(double latitude, double longitude, double radiusKm = 5, int? categoryType = null, CancellationToken ct = default);
    Task<List<LocationSuggestionResponse>> GetSuggestionsAsync(string query, CancellationToken ct = default);
}



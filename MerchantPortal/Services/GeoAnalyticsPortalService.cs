using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.WebUtilities;

namespace Getir.MerchantPortal.Services;

public class GeoAnalyticsPortalService : IGeoAnalyticsPortalService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<GeoAnalyticsPortalService> _logger;

    public GeoAnalyticsPortalService(IApiClient apiClient, ILogger<GeoAnalyticsPortalService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<LocationAnalyticsResponseModel?> GetLocationAnalyticsAsync(DateTime? startDate = null, DateTime? endDate = null, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>();
            if (startDate.HasValue)
            {
                query["startDate"] = startDate.Value.ToString("O");
            }
            if (endDate.HasValue)
            {
                query["endDate"] = endDate.Value.ToString("O");
            }

            var url = QueryHelpers.AddQueryString("api/v1/geo/analytics", query);
            var response = await _apiClient.GetAsync<ApiResponse<LocationAnalyticsResponseModel>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch location analytics");
            return null;
        }
    }

    public async Task<DeliveryZoneCoverageResponseModel?> GetDeliveryZoneCoverageAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<DeliveryZoneCoverageResponseModel>>("api/v1/geo/delivery-zones/coverage", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch delivery zone coverage");
            return null;
        }
    }

    public async Task<List<UserLocationResponseModel>> GetLocationHistoryAsync(PaginationQueryRequest request, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["page"] = request.Page.ToString(),
                ["pageSize"] = request.PageSize.ToString()
            };
            var url = QueryHelpers.AddQueryString("api/v1/geo/location/history", query);
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<UserLocationResponseModel>>>(url, ct);
            return response?.Data?.Items ?? new List<UserLocationResponseModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch location history");
            return new List<UserLocationResponseModel>();
        }
    }

    public async Task<List<NearbyMerchantResponse>> GetNearbyMerchantsAsync(double latitude, double longitude, double radiusKm = 5, int? categoryType = null, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["latitude"] = latitude.ToString(System.Globalization.CultureInfo.InvariantCulture),
                ["longitude"] = longitude.ToString(System.Globalization.CultureInfo.InvariantCulture),
                ["radius"] = radiusKm.ToString(System.Globalization.CultureInfo.InvariantCulture)
            };
            if (categoryType.HasValue)
            {
                query["categoryType"] = categoryType.Value.ToString();
            }

            var url = QueryHelpers.AddQueryString("api/v1/geo/merchants/nearby", query);
            var response = await _apiClient.GetAsync<ApiResponse<List<NearbyMerchantResponse>>>(url, ct);
            return response?.Data ?? new List<NearbyMerchantResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch nearby merchants");
            return new List<NearbyMerchantResponse>();
        }
    }

    public async Task<List<LocationSuggestionResponse>> GetSuggestionsAsync(string queryText, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["query"] = queryText
            };
            var url = QueryHelpers.AddQueryString("api/v1/geo/suggestions", query);
            var response = await _apiClient.GetAsync<ApiResponse<List<LocationSuggestionResponse>>>(url, ct);
            return response?.Data ?? new List<LocationSuggestionResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch location suggestions");
            return new List<LocationSuggestionResponse>();
        }
    }
}



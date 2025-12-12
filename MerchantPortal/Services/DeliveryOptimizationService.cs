using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class DeliveryOptimizationService : IDeliveryOptimizationService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<DeliveryOptimizationService> _logger;

	public DeliveryOptimizationService(IApiClient apiClient, ILogger<DeliveryOptimizationService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<DeliveryCapacityResponse?> CreateCapacityAsync(DeliveryCapacityRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<DeliveryCapacityResponse>>("api/deliveryoptimization/capacity", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating capacity");
			return null;
		}
	}

	public async Task<DeliveryCapacityResponse?> UpdateCapacityAsync(Guid capacityId, DeliveryCapacityRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PutAsync<ApiResponse<DeliveryCapacityResponse>>($"api/deliveryoptimization/capacity/{capacityId}", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating capacity {CapacityId}", capacityId);
			return null;
		}
	}

	public async Task<DeliveryCapacityResponse?> GetCapacityAsync(Guid merchantId, Guid? deliveryZoneId = null, CancellationToken ct = default)
	{
		var url = $"api/deliveryoptimization/capacity/merchant/{merchantId}" + (deliveryZoneId.HasValue ? $"?deliveryZoneId={deliveryZoneId}" : string.Empty);
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<DeliveryCapacityResponse>>(url, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting capacity for merchant {MerchantId}", merchantId);
			return null;
		}
	}

	public async Task<DeliveryCapacityCheckResponse?> CheckCapacityAsync(DeliveryCapacityCheckRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<DeliveryCapacityCheckResponse>>("api/deliveryoptimization/capacity/check", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error checking capacity");
			return null;
		}
	}

	public async Task<RouteOptimizationResponse?> GetAlternativeRoutesAsync(RouteOptimizationRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<RouteOptimizationResponse>>("api/deliveryoptimization/routes/alternatives", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting alternative routes");
			return null;
		}
	}

	public async Task<DeliveryRouteResponse?> SelectBestRouteAsync(RouteOptimizationRequest request, bool? avoidTollRoads = null, string? travelMode = null, CancellationToken ct = default)
	{
		var qs = new List<string>();
		if (avoidTollRoads.HasValue) qs.Add($"avoidTollRoads={avoidTollRoads.Value.ToString().ToLower()}");
		if (!string.IsNullOrWhiteSpace(travelMode)) qs.Add($"travelMode={travelMode}");
		var url = "api/deliveryoptimization/routes/best" + (qs.Count > 0 ? ("?" + string.Join("&", qs)) : string.Empty);
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<DeliveryRouteResponse>>(url, request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error selecting best route");
			return null;
		}
	}
}



using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class DeliveryZoneService : IDeliveryZoneService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<DeliveryZoneService> _logger;

	public DeliveryZoneService(IApiClient apiClient, ILogger<DeliveryZoneService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<List<DeliveryZoneResponse>?> GetZonesByMerchantAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<List<DeliveryZoneResponse>>>(
				$"api/v1/deliveryzone/merchant/{merchantId}", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting zones for merchant {MerchantId}", merchantId);
			return null;
		}
	}

	public async Task<DeliveryZoneResponse?> GetZoneAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<DeliveryZoneResponse>>($"api/v1/deliveryzone/{id}", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting zone {Id}", id);
			return null;
		}
	}

	public async Task<DeliveryZoneResponse?> CreateZoneAsync(CreateDeliveryZoneRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<DeliveryZoneResponse>>("api/v1/deliveryzone", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating zone");
			return null;
		}
	}

	public async Task<DeliveryZoneResponse?> UpdateZoneAsync(Guid id, UpdateDeliveryZoneRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PutAsync<ApiResponse<DeliveryZoneResponse>>($"api/v1/deliveryzone/{id}", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating zone {Id}", id);
			return null;
		}
	}

	public async Task<bool> DeleteZoneAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			return await _apiClient.DeleteAsync($"api/v1/deliveryzone/{id}", ct);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting zone {Id}", id);
			return false;
		}
	}
}



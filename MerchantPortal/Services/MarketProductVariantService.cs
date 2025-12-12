using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class MarketProductVariantService : IMarketProductVariantService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<MarketProductVariantService> _logger;

	public MarketProductVariantService(IApiClient apiClient, ILogger<MarketProductVariantService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<MarketProductVariantResponse>?> GetVariantsAsync(Guid productId, int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		try
		{
			var endpoint = $"api/v1/marketproductvariant/products/{productId}?page={page}&pageSize={pageSize}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<MarketProductVariantResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product variants for product {ProductId}", productId);
			return null;
		}
	}

	public async Task<MarketProductVariantResponse?> GetVariantAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.GetAsync<ApiResponse<MarketProductVariantResponse>>($"api/v1/marketproductvariant/{id}", ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product variant {Id}", id);
			return null;
		}
	}

	public async Task<MarketProductVariantResponse?> CreateVariantAsync(CreateMarketProductVariantRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<MarketProductVariantResponse>>("api/v1/marketproductvariant", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating product variant");
			return null;
		}
	}

	public async Task<MarketProductVariantResponse?> UpdateVariantAsync(Guid id, UpdateMarketProductVariantRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<MarketProductVariantResponse>>($"api/v1/marketproductvariant/{id}", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating product variant {Id}", id);
			return null;
		}
	}

	public async Task<bool> DeleteVariantAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			return await _apiClient.DeleteAsync($"api/v1/marketproductvariant/{id}", ct);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting product variant {Id}", id);
			return false;
		}
	}

	public async Task<bool> UpdateVariantStockAsync(Guid id, int newStockQuantity, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<object>>($"api/v1/marketproductvariant/{id}/stock", newStockQuantity, ct);
			return response?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating stock for product variant {Id}", id);
			return false;
		}
	}

	public async Task<bool> BulkUpdateVariantStockAsync(List<UpdateVariantStockRequest> requests, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<object>>("api/v1/marketproductvariant/stock/bulk", requests, ct);
			return response?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error bulk updating product variant stocks");
			return false;
		}
	}
}



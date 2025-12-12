using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class ProductOptionService : IProductOptionService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<ProductOptionService> _logger;

	public ProductOptionService(IApiClient apiClient, ILogger<ProductOptionService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<ProductOptionGroupResponse>?> GetGroupsAsync(Guid productId, int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		try
		{
			var endpoint = $"api/v1/productoption/groups/{productId}?page={page}&pageSize={pageSize}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<ProductOptionGroupResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product option groups for product {ProductId}", productId);
			return null;
		}
	}

	public async Task<ProductOptionGroupResponse?> GetGroupAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.GetAsync<ApiResponse<ProductOptionGroupResponse>>($"api/v1/productoption/groups/details/{id}", ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product option group {Id}", id);
			return null;
		}
	}

	public async Task<ProductOptionGroupResponse?> CreateGroupAsync(CreateProductOptionGroupRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<ProductOptionGroupResponse>>("api/v1/productoption/groups", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating product option group");
			return null;
		}
	}

	public async Task<ProductOptionGroupResponse?> UpdateGroupAsync(Guid id, UpdateProductOptionGroupRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<ProductOptionGroupResponse>>($"api/v1/productoption/groups/{id}", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating product option group {Id}", id);
			return null;
		}
	}

	public async Task<bool> DeleteGroupAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			return await _apiClient.DeleteAsync($"api/v1/productoption/groups/{id}", ct);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting product option group {Id}", id);
			return false;
		}
	}

	public async Task<bool> ReorderGroupsAsync(Guid productId, List<Guid> orderedGroupIds, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<object>>($"api/v1/productoption/groups/{productId}/reorder", orderedGroupIds, ct);
			return response?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error reordering product option groups for product {ProductId}", productId);
			return false;
		}
	}

	public async Task<PagedResult<ProductOptionResponse>?> GetOptionsAsync(Guid productOptionGroupId, int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		try
		{
			var endpoint = $"api/v1/productoption/groups/{productOptionGroupId}/options?page={page}&pageSize={pageSize}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<ProductOptionResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product options for group {GroupId}", productOptionGroupId);
			return null;
		}
	}

	public async Task<ProductOptionResponse?> GetOptionAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.GetAsync<ApiResponse<ProductOptionResponse>>($"api/v1/productoption/options/{id}", ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting product option {Id}", id);
			return null;
		}
	}

	public async Task<ProductOptionResponse?> CreateOptionAsync(CreateProductOptionRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<ProductOptionResponse>>("api/v1/productoption/options", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating product option");
			return null;
		}
	}

	public async Task<ProductOptionResponse?> UpdateOptionAsync(Guid id, UpdateProductOptionRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<ProductOptionResponse>>($"api/v1/productoption/options/{id}", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error updating product option {Id}", id);
			return null;
		}
	}

	public async Task<bool> DeleteOptionAsync(Guid id, CancellationToken ct = default)
	{
		try
		{
			return await _apiClient.DeleteAsync($"api/v1/productoption/options/{id}", ct);
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting product option {Id}", id);
			return false;
		}
	}

	public async Task<bool> BulkCreateOptionsAsync(BulkCreateProductOptionsRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<object>>("api/v1/productoption/options/bulk", request, ct);
			return response?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error bulk creating product options");
			return false;
		}
	}

	public async Task<bool> BulkUpdateOptionsAsync(BulkUpdateProductOptionsRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PutAsync<ApiResponse<object>>("api/v1/productoption/options/bulk", request, ct);
			return response?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error bulk updating product options");
			return false;
		}
	}
}



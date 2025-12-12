using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class ServiceCategoryDirectory : IServiceCategoryDirectory
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<ServiceCategoryDirectory> _logger;

	public ServiceCategoryDirectory(IApiClient apiClient, ILogger<ServiceCategoryDirectory> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<IReadOnlyList<ServiceCategoryResponse>?> GetServiceCategoriesAsync(int page = 1, int pageSize = 100, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<ServiceCategoryResponse>>>(
				$"api/v1/servicecategory?page={page}&pageSize={pageSize}", ct);
			return response?.Data?.Items ?? new List<ServiceCategoryResponse>();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error fetching service categories");
			return null;
		}
	}

	public async Task<IReadOnlyList<ServiceCategoryResponse>?> GetActiveServiceCategoriesByTypeAsync(string categoryType, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.GetAsync<ApiResponse<List<ServiceCategoryResponse>>>(
				$"api/v1/servicecategory/active/by-type/{categoryType}", ct);
			return response?.Data ?? new List<ServiceCategoryResponse>();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error fetching active service categories for type {CategoryType}", categoryType);
			return null;
		}
	}
}


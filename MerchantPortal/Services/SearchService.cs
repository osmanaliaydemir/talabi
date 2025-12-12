using System.Web;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class SearchService : ISearchService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<SearchService> _logger;

	public SearchService(IApiClient apiClient, ILogger<SearchService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<ProductResponse>?> SearchProductsAsync(
		string? query = null,
		Guid? categoryId = null,
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default)
	{
		try
		{
			var qs = HttpUtility.ParseQueryString(string.Empty);
			if (!string.IsNullOrWhiteSpace(query)) qs["q"] = query;
			if (categoryId.HasValue) qs["categoryId"] = categoryId.Value.ToString();
			qs["page"] = page.ToString();
			qs["pageSize"] = pageSize.ToString();

			var endpoint = $"api/v1/search/products?{qs}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<ProductResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error searching products");
			return null;
		}
	}

	public async Task<PagedResult<MerchantResponse>?> SearchMerchantsAsync(
		string? query = null,
		string? location = null,
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default)
	{
		try
		{
			var qs = HttpUtility.ParseQueryString(string.Empty);
			if (!string.IsNullOrWhiteSpace(query)) qs["q"] = query;
			if (!string.IsNullOrWhiteSpace(location)) qs["location"] = location;
			qs["page"] = page.ToString();
			qs["pageSize"] = pageSize.ToString();

			var endpoint = $"api/v1/search/merchants?{qs}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<MerchantResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error searching merchants");
			return null;
		}
	}
}



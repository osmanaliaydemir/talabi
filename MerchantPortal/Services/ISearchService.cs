using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ISearchService
{
	Task<PagedResult<ProductResponse>?> SearchProductsAsync(
		string? query = null,
		Guid? categoryId = null,
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default);

	Task<PagedResult<MerchantResponse>?> SearchMerchantsAsync(
		string? query = null,
		string? location = null,
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default);
}



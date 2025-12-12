using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IServiceCategoryDirectory
{
	Task<IReadOnlyList<ServiceCategoryResponse>?> GetServiceCategoriesAsync(int page = 1, int pageSize = 100, CancellationToken ct = default);
	Task<IReadOnlyList<ServiceCategoryResponse>?> GetActiveServiceCategoriesByTypeAsync(string categoryType, CancellationToken ct = default);
}


using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IMarketProductVariantService
{
	Task<PagedResult<MarketProductVariantResponse>?> GetVariantsAsync(Guid productId, int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<MarketProductVariantResponse?> GetVariantAsync(Guid id, CancellationToken ct = default);
	Task<MarketProductVariantResponse?> CreateVariantAsync(CreateMarketProductVariantRequest request, CancellationToken ct = default);
	Task<MarketProductVariantResponse?> UpdateVariantAsync(Guid id, UpdateMarketProductVariantRequest request, CancellationToken ct = default);
	Task<bool> DeleteVariantAsync(Guid id, CancellationToken ct = default);
	Task<bool> UpdateVariantStockAsync(Guid id, int newStockQuantity, CancellationToken ct = default);
	Task<bool> BulkUpdateVariantStockAsync(List<UpdateVariantStockRequest> requests, CancellationToken ct = default);
}



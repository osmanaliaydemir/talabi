using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IMerchantService
{
    Task<MerchantResponse?> GetMyMerchantAsync(CancellationToken ct = default);
    Task<MerchantResponse?> GetMerchantByIdAsync(Guid merchantId, CancellationToken ct = default);
    Task<PagedResult<MerchantResponse>?> GetMerchantsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
    Task<PagedResult<MerchantResponse>?> GetMerchantsByCategoryTypeAsync(string categoryType, int page = 1, int pageSize = 20, CancellationToken ct = default);
    Task<List<MerchantResponse>?> GetActiveMerchantsByCategoryTypeAsync(string categoryType, CancellationToken ct = default);
    Task<MerchantResponse?> CreateMerchantAsync(CreateMerchantRequest request, CancellationToken ct = default);
    Task<bool> DeleteMerchantAsync(Guid merchantId, CancellationToken ct = default);
    Task<MerchantResponse?> UpdateMerchantAsync(Guid merchantId, UpdateMerchantRequest request, CancellationToken ct = default);
    Task<MerchantDashboardResponse?> GetDashboardAsync(Guid merchantId, CancellationToken ct = default);
    Task<List<RecentOrderResponse>?> GetRecentOrdersAsync(Guid merchantId, int limit = 10, CancellationToken ct = default);
    Task<List<TopProductResponse>?> GetTopProductsAsync(Guid merchantId, int limit = 10, CancellationToken ct = default);
    Task<List<SalesTrendDataResponse>?> GetSalesTrendDataAsync(Guid merchantId, int days = 30, CancellationToken ct = default);
    Task<OrderStatusDistributionResponse?> GetOrderStatusDistributionAsync(Guid merchantId, CancellationToken ct = default);
    Task<List<CategoryPerformanceResponse>?> GetCategoryPerformanceAsync(Guid merchantId, CancellationToken ct = default);
    Task<MerchantPerformanceMetrics?> GetPerformanceMetricsAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null, CancellationToken ct = default);
}


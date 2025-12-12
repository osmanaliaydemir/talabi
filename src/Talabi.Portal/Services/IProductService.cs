using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IProductService
{
    Task<PagedResultDto<VendorProductDto>?> GetProductsAsync(int page = 1, int pageSize = 10, string? category = null,
        bool? isAvailable = null, string? search = null, string? sortBy = null, string sortOrder = "desc",
        CancellationToken ct = default);

    Task<VendorProductDto?> GetProductAsync(Guid id, CancellationToken ct = default);
    Task<bool> CreateProductAsync(CreateProductDto dto, CancellationToken ct = default);
    Task<bool> UpdateProductAsync(Guid id, UpdateProductDto dto, CancellationToken ct = default);
    Task<bool> DeleteProductAsync(Guid id, CancellationToken ct = default);
    Task<bool> UpdateAvailabilityAsync(Guid id, bool isAvailable, CancellationToken ct = default);
    Task<List<string>> GetCategoriesAsync(CancellationToken ct = default);
}

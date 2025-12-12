using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface ICategoryService
{
    Task<PagedResultDto<VendorCategoryDto>?> GetCategoriesAsync(int page = 1, int pageSize = 10, string? search = null,
        string? sortBy = null, string sortOrder = "asc", CancellationToken ct = default);

    Task<bool> UpdateCategoryAsync(string oldName, string newName, CancellationToken ct = default);
    Task<bool> DeleteCategoryAsync(string name, CancellationToken ct = default); // Sets category to null for products
}

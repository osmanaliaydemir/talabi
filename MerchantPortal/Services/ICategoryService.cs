using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ICategoryService
{
    /// <summary>
    /// Kategorileri getirir.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Kategoriler</returns>
    Task<List<ProductCategoryResponse>?> GetCategoriesAsync(CancellationToken ct = default);
    /// <summary>
    /// Mağaza kategorilerini getirir.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Mağaza kategorileri</returns>
    Task<List<ProductCategoryResponse>?> GetMyCategoriesAsync(CancellationToken ct = default);
    /// <summary>
    /// Standart kategorileri getirir (ServiceCategory bazlı).
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Standart kategoriler</returns>
    Task<List<ProductCategoryResponse>?> GetStandardCategoriesAsync(CancellationToken ct = default);
    /// <summary>
    /// Kategori detaylarını getirir.
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Kategori detayları</returns>
    Task<ProductCategoryResponse?> GetCategoryByIdAsync(Guid categoryId, CancellationToken ct = default);
    /// <summary>
    /// Kategori oluşturur.
    /// </summary>
    /// <param name="request">Kategori oluşturma isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Kategori</returns>
    Task<ProductCategoryResponse?> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken ct = default);
    /// <summary>
    /// Kategori günceller.
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="request">Kategori güncelleme isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Kategori</returns>
    Task<ProductCategoryResponse?> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequest request, CancellationToken ct = default);
    /// <summary>
    /// Kategori siler.
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> DeleteCategoryAsync(Guid categoryId, CancellationToken ct = default);
    /// <summary>
    /// Kategori ağacını getirir.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Kategori ağacı</returns>
    Task<List<CategoryTreeNode>?> GetCategoryTreeAsync(CancellationToken ct = default);
}


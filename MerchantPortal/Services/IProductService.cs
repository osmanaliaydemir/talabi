using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IProductService
{
    /// <summary>
    /// Ürünleri getirir.
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürünler</returns>
    Task<PagedResult<ProductResponse>?> GetProductsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
    /// <summary>
    /// Merchant'a ait ürünleri getirir.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürünler</returns>
    Task<List<ProductResponse>?> GetProductsByMerchantAsync(Guid merchantId, CancellationToken ct = default);
    /// <summary>
    /// Ürün detaylarını getirir.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün detayları</returns>
    Task<ProductResponse?> GetProductByIdAsync(Guid productId, CancellationToken ct = default);
    /// <summary>
    /// Ürün oluşturur.
    /// </summary>
    /// <param name="request">Ürün oluşturma isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün</returns>
    Task<ProductResponse?> CreateProductAsync(CreateProductRequest request, CancellationToken ct = default);
    /// <summary>
    /// Ürünü günceller.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="request">Ürün güncelleme isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün</returns>
    Task<ProductResponse?> UpdateProductAsync(Guid productId, UpdateProductRequest request, CancellationToken ct = default);
    /// <summary>
    /// Ürünü siler.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> DeleteProductAsync(Guid productId, CancellationToken ct = default);
    /// <summary>
    /// Ürün kategorilerini getirir.
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün kategorileri</returns>
    Task<List<ProductCategoryResponse>?> GetCategoriesAsync(CancellationToken ct = default);
}


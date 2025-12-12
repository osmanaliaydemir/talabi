using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

/// <summary>
/// Product review servisi - Merchant'ın ürünlerine gelen yorumları yönetir
/// </summary>
public interface IProductReviewService
{
    /// <summary>
    /// Merchant'ın ürünlerine gelen yorumları getirir (paginated).
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="rating">Değerlendirme puanı</param>
    /// <param name="isApproved">Onaylı mı</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Merchant ürünlerine gelen yorumlar</returns>
    Task<PagedResult<ProductReviewResponse>?> GetMerchantProductReviewsAsync(Guid merchantId, int page = 1, int pageSize = 20, int? rating = null, bool? isApproved = null, CancellationToken ct = default);

    /// <summary>
    /// Belirli bir ürünün yorumlarını getirir.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün yorumları</returns>
    Task<PagedResult<ProductReviewResponse>?> GetProductReviewsAsync(Guid productId, int page = 1, int pageSize = 20, CancellationToken ct = default);

    /// <summary>
    /// Review detayını getirir.
    /// </summary>
    /// <param name="reviewId">Yorum ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Yorum detayları</returns>
    Task<ProductReviewResponse?> GetReviewByIdAsync(Guid reviewId, CancellationToken ct = default);

    /// <summary>
    /// Ürün review istatistiklerini getirir.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Ürün review istatistikleri</returns>
    Task<ProductReviewStatsResponse?> GetProductReviewStatsAsync(Guid productId, CancellationToken ct = default);

    /// <summary>
    /// Merchant'ın tüm ürünleri için review istatistiklerini getirir.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Merchant review istatistikleri</returns>
    Task<ProductReviewStatsResponse?> GetMerchantReviewStatsAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Review'a merchant yanıtı ekler.
    /// </summary>
    /// <param name="reviewId">Yorum ID</param>
    /// <param name="response">Yanıt</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> RespondToReviewAsync(Guid reviewId, string response, CancellationToken ct = default);

    /// <summary>
    /// Review'ı onaylar (merchant moderasyonu).
    /// </summary>
    /// <param name="reviewId">Yorum ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> ApproveReviewAsync(Guid reviewId, CancellationToken ct = default);

    /// <summary>
    /// Review'ı reddeder (merchant moderasyonu).
    /// </summary>
    /// <param name="reviewId">Yorum ID</param>
    /// <param name="reason">Red sebebi</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> RejectReviewAsync(Guid reviewId, string reason, CancellationToken ct = default);
}


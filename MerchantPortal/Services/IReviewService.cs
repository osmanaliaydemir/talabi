using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

/// <summary>
/// Merchant Portal için Review Service Interface
/// </summary>
public interface IReviewService
{
    /// <summary>
    /// Merchant değerlendirmelerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme listesi</returns>
    Task<List<ReviewResponse>> GetMerchantReviewsAsync(Guid merchantId, ReviewFilterModel filter, CancellationToken ct = default);
    
    /// <summary>
    /// Kurye değerlendirmelerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme listesi</returns>
    Task<List<ReviewResponse>> GetCourierReviewsAsync(Guid merchantId, ReviewFilterModel filter, CancellationToken ct = default);
    
    /// <summary>
    /// Merchant değerlendirme istatistiklerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme istatistikleri</returns>
    Task<ReviewStatsResponse?> GetMerchantReviewStatsAsync(Guid merchantId, CancellationToken ct = default);
    
    /// <summary>
    /// Kurye değerlendirme istatistiklerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme istatistikleri</returns>
    Task<ReviewStatsResponse?> GetCourierReviewStatsAsync(Guid merchantId, CancellationToken ct = default);
    
    /// <summary>
    /// Değerlendirmeye yanıt ver
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="response">Yanıt metni</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> RespondToReviewAsync(Guid reviewId, string response, CancellationToken ct = default);
    
    /// <summary>
    /// Değerlendirmeyi beğen/beğenme
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="isLiked">Beğenilme durumu</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> LikeReviewAsync(Guid reviewId, bool isLiked, CancellationToken ct = default);
    
    /// <summary>
    /// Değerlendirmeyi rapor et
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="reason">Rapor nedeni</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> ReportReviewAsync(Guid reviewId, string reason, CancellationToken ct = default);
    
    /// <summary>
    /// Değerlendirme dashboard verilerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Dashboard verileri</returns>
    Task<ReviewDashboardModel> GetReviewDashboardAsync(Guid merchantId, CancellationToken ct = default);
}

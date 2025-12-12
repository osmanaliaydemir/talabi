using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IStockService
{
    /// <summary>
    /// Stok uyarılarını getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Stok uyarıları</returns>
    Task<List<StockAlertResponse>?> GetStockAlertsAsync(CancellationToken ct = default);

    /// <summary>
    /// Stok özetini getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Stok özeti</returns>
    Task<StockSummaryResponse?> GetStockSummaryAsync(CancellationToken ct = default);

    /// <summary>
    /// Stok geçmişini getir
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="fromDate">Başlangıç tarihi</param>
    /// <param name="toDate">Bitiş tarihi</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Stok geçmişi</returns>
    Task<List<StockHistoryResponse>?> GetStockHistoryAsync(Guid productId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken ct = default);

    /// <summary>
    /// Stok seviyesini güncelle
    /// </summary>
    /// <param name="request">Stok güncelleme isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> UpdateStockLevelAsync(UpdateStockRequest request, CancellationToken ct = default);

    /// <summary>
    /// Stok seviyelerini toplu güncelle
    /// </summary>
    /// <param name="request">Toplu güncelleme isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> BulkUpdateStockLevelsAsync(BulkUpdateStockRequest request, CancellationToken ct = default);

    /// <summary>
    /// Stok uyarısını çözümle
    /// </summary>
    /// <param name="alertId">Uyarı ID</param>
    /// <param name="resolutionNotes">Çözüm notları</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> ResolveStockAlertAsync(Guid alertId, string resolutionNotes, CancellationToken ct = default);

    /// <summary>
    /// Stok seviyelerini kontrol et
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> CheckStockLevelsAsync(CancellationToken ct = default);

    /// <summary>
    /// Düşük stok ürünlerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="threshold">Eşik değeri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Düşük stok ürünleri</returns>
    Task<List<LowStockProductModel>> GetLowStockProductsAsync(Guid merchantId, int threshold = 10, CancellationToken ct = default);

    /// <summary>
    /// CSV'den stok aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="csvStream">CSV dosya akışı</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Aktarım sonucu</returns>
    Task<StockImportResult> ImportStockFromCsvAsync(Guid merchantId, Stream csvStream, CancellationToken ct = default);

    /// <summary>
    /// Stokları CSV'ye aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>CSV dosyası</returns>
    Task<byte[]> ExportStockToCsvAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Stok raporunu getir
    /// </summary>
    /// <param name="request">Rapor isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Stok raporu</returns>
    Task<StockReportResponse?> GetStockReportAsync(StockReportRequest request, CancellationToken ct = default);

    /// <summary>
    /// Stok senkronizasyonunu başlat
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> SynchronizeStockAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Stok uyarılarını kontrol et
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> CheckStockAlertsAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Yeniden sipariş noktası ayarlarını getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Yeniden sipariş noktası ayarları</returns>
    Task<List<ReorderPointModel>> GetReorderPointsAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Yeniden sipariş noktası ayarını kaydet
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="minStock">Minimum stok</param>
    /// <param name="maxStock">Maksimum stok</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    Task<bool> SetReorderPointAsync(Guid productId, int minStock, int maxStock, CancellationToken ct = default);
}


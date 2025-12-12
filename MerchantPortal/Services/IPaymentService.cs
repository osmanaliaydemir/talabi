using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IPaymentService
{
    /// <summary>
    /// Ödeme geçmişini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <returns>Ödeme geçmişi listesi</returns>
    Task<List<PaymentListItemModel>> GetPaymentHistoryAsync(Guid merchantId, PaymentFilterModel filter);

    /// <summary>
    /// Ödeme detaylarını getir
    /// </summary>
    /// <param name="paymentId">Ödeme ID</param>
    /// <returns>Ödeme detayları</returns>
    Task<PaymentResponse?> GetPaymentByIdAsync(Guid paymentId);

    /// <summary>
    /// Mutabakat raporunu getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Mutabakat raporu</returns>
    Task<SettlementReportModel> GetSettlementReportAsync(Guid merchantId, DateTime startDate, DateTime endDate);

    /// <summary>
    /// Gelir analizlerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Gelir analizleri</returns>
    Task<RevenueAnalyticsModel> GetRevenueAnalyticsAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Ödeme yöntemi dağılımını getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Ödeme yöntemi dağılımı</returns>
    Task<List<PaymentMethodBreakdownModel>> GetPaymentMethodBreakdownAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Ödemeleri Excel'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>Excel dosyası</returns>
    Task<byte[]> ExportToExcelAsync(Guid merchantId, PaymentExportRequest request);

    /// <summary>
    /// Ödemeleri PDF'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>PDF dosyası</returns>
    Task<byte[]> ExportToPdfAsync(Guid merchantId, PaymentExportRequest request);

    /// <summary>
    /// Merchant mutabakatlarını getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <returns>Mutabakat listesi</returns>
    Task<List<SettlementResponse>> GetMerchantSettlementsAsync(Guid merchantId, int page = 1, int pageSize = 50);

    Task<PagedResult<PaymentResponse>?> GetAdminCashCollectionsAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default);
    Task<bool> ProcessSettlementAsync(Guid merchantId, ProcessSettlementRequest request, CancellationToken ct = default);
    Task<PagedResult<PaymentResponse>?> GetOrderPaymentsAsync(Guid orderId, int page = 1, int pageSize = 20, CancellationToken ct = default);
    Task<PaymentResponse?> CreatePaymentAsync(CreatePaymentRequest request, CancellationToken ct = default);
    Task<PagedResult<PaymentResponse>?> GetPendingCourierPaymentsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
    Task<CourierCashSummaryResponse?> GetCourierCashSummaryAsync(DateTime? date = null, CancellationToken ct = default);
    Task<bool> CollectCashPaymentAsync(Guid paymentId, CollectCashPaymentRequest request, CancellationToken ct = default);
    Task<bool> FailCashPaymentAsync(Guid paymentId, string reason, CancellationToken ct = default);
}

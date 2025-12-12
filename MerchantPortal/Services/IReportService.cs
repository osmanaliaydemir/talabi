using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IReportService
{
    /// <summary>
    /// Satış dashboard verilerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Satış dashboard verileri</returns>
    Task<SalesDashboardModel> GetSalesDashboardAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Gelir analizlerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Gelir analizleri</returns>
    Task<RevenueAnalyticsModel> GetRevenueAnalyticsAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Müşteri analizlerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Müşteri analizleri</returns>
    Task<CustomerAnalyticsModel> GetCustomerAnalyticsAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Ürün performans verilerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Ürün performans verileri</returns>
    Task<ProductPerformanceModel> GetProductPerformanceAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Grafik verilerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="chartType">Grafik tipi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Grafik verileri</returns>
    Task<ChartDataModel> GetChartDataAsync(Guid merchantId, string chartType, DateTime? startDate = null, DateTime? endDate = null);

    /// <summary>
    /// Raporu PDF'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>PDF dosyası</returns>
    Task<byte[]> ExportReportToPdfAsync(Guid merchantId, ReportExportRequest request);

    /// <summary>
    /// Raporu Excel'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>Excel dosyası</returns>
    Task<byte[]> ExportReportToExcelAsync(Guid merchantId, ReportExportRequest request);
}

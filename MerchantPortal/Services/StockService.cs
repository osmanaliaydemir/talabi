using Getir.MerchantPortal.Models;
using System.Text;

namespace Getir.MerchantPortal.Services;

public class StockService : IStockService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<StockService> _logger;

    public StockService(IApiClient apiClient, ILogger<StockService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    /// <summary>
    /// Stok uyarılarını getirir.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Stok uyarıları</returns>
    public async Task<List<StockAlertResponse>?> GetStockAlertsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<StockAlertResponse>>>(
                "api/StockManagement/alerts",
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting stock alerts");
            return null;
        }
    }

    /// <summary>
    /// Stok özetini getirir.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Stok özeti</returns>
    public async Task<StockSummaryResponse?> GetStockSummaryAsync(CancellationToken ct = default)
    {
        try
        {
            // We'll calculate this from alerts and products
            var alerts = await GetStockAlertsAsync(ct);
            
            if (alerts == null)
                return null;

            return new StockSummaryResponse
            {
                ActiveAlerts = alerts.Count(a => !a.IsResolved),
                LowStockItems = alerts.Count(a => a.AlertType == "LowStock" && !a.IsResolved),
                OutOfStockItems = alerts.Count(a => a.AlertType == "OutOfStock" && !a.IsResolved),
                OverstockItems = alerts.Count(a => a.AlertType == "Overstock" && !a.IsResolved)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting stock summary");
            return null;
        }
    }

    /// <summary>
    /// Stok geçmişini getirir.
    /// </summary>
    /// <param name="productId">Ürün ID</param>
    /// <param name="fromDate">Başlangıç tarihi</param>
    /// <param name="toDate">Bitiş tarihi</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Stok geçmişi</returns>
    public async Task<List<StockHistoryResponse>?> GetStockHistoryAsync(
        Guid productId, 
        DateTime? fromDate = null, 
        DateTime? toDate = null, 
        CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/StockManagement/history/{productId}";
            var queryParams = new List<string>();

            if (fromDate.HasValue)
                queryParams.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
            
            if (toDate.HasValue)
                queryParams.Add($"toDate={toDate.Value:yyyy-MM-dd}");

            if (queryParams.Any())
                endpoint += "?" + string.Join("&", queryParams);

            var response = await _apiClient.GetAsync<ApiResponse<List<StockHistoryResponse>>>(
                endpoint,
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting stock history for product {ProductId}", productId);
            return null;
        }
    }

    /// <summary>
    /// Stok seviyesini günceller.
    /// </summary>
    /// <param name="request">Stok seviyesi güncelleme isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> UpdateStockLevelAsync(UpdateStockRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<object>>(
                "api/StockManagement/update",
                request,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating stock level for product {ProductId}", request.ProductId);
            return false;
        }
    }

    /// <summary>
    /// Stok seviyelerini bulk günceller.
    /// </summary>
    /// <param name="request">Stok seviyeleri bulk güncelleme isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> BulkUpdateStockLevelsAsync(BulkUpdateStockRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<object>>(
                "api/StockManagement/bulk-update",
                request,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error bulk updating stock levels");
            return false;
        }
    }

    /// <summary>
    /// Stok uyarısını çözümler.
    /// </summary>
    /// <param name="alertId">Stok uyarısı ID</param>
    /// <param name="resolutionNotes">Çözüm notları</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> ResolveStockAlertAsync(Guid alertId, string resolutionNotes, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<object>>(
                $"api/StockAlert/{alertId}/resolve",
                new { ResolutionNotes = resolutionNotes },
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resolving stock alert {AlertId}", alertId);
            return false;
        }
    }

    /// <summary>
    /// Stok seviyelerini kontrol eder.
    /// </summary>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> CheckStockLevelsAsync(CancellationToken ct = default)
    {
        try
        {
            // This endpoint requires merchantId in route, but backend gets it from JWT
            // We'll call the StockAlert endpoint to create low stock alerts
            var response = await _apiClient.PostAsync<ApiResponse<object>>(
                "api/StockAlert/create-low-stock",
                null,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking stock levels");
            return false;
        }
    }

    /// <summary>
    /// Backend report endpoint'i üzerinden stok raporu alır.
    /// </summary>
    public async Task<StockReportResponse?> GetStockReportAsync(StockReportRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<StockReportResponse>>(
                "api/StockManagement/report",
                request,
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting stock report");
            return null;
        }
    }

    /// <summary>
    /// Backend sync endpoint'i üzerinden stok senkronizasyonu başlatır.
    /// </summary>
    public async Task<bool> SynchronizeStockAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<object>>(
                $"api/StockManagement/sync/{merchantId}",
                null,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error synchronizing stock for merchant {MerchantId}", merchantId);
            return false;
        }
    }

    /// <summary>
    /// Backend check-alerts akışını tetikler (JWT/role ile korunur).
    /// </summary>
    public async Task<bool> CheckStockAlertsAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<object>>(
                $"api/StockManagement/check-alerts/{merchantId}",
                null,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking stock alerts for merchant {MerchantId}", merchantId);
            return false;
        }
    }

    /// <summary>
    /// Düşük stoklu ürünleri getirir.
    /// </summary>
    public async Task<List<LowStockProductModel>> GetLowStockProductsAsync(Guid merchantId, int threshold = 10, CancellationToken ct = default)
    {
        try
        {
            // Derive from alerts since low-stock endpoint doesn't exist on backend
            var alertsResponse = await _apiClient.GetAsync<ApiResponse<List<StockAlertResponse>>>(
                "api/StockManagement/alerts",
                ct);

            var alerts = alertsResponse?.Data ?? new List<StockAlertResponse>();

            var lowOrOut = alerts
                .Where(a => (a.AlertType == "LowStock" || a.AlertType == "OutOfStock") && !a.IsResolved)
                .GroupBy(a => a.ProductId)
                .Select(g => new LowStockProductModel
                {
                    ProductId = g.Key,
                    ProductName = g.First().ProductName,
                    SKU = string.Empty,
                    ImageUrl = null,
                    CurrentStock = g.Max(x => x.CurrentStock),
                    MinStock = g.Max(x => x.MinimumStock),
                    MaxStock = g.Max(x => x.MaximumStock),
                    UnitPrice = 0,
                    Status = g.Any(x => x.AlertType == "OutOfStock") ? "Critical" : "Low"
                })
                .ToList();

            return lowOrOut;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting low stock products");
            return new List<LowStockProductModel>();
        }
    }

    /// <summary>
    /// Stok verilerini CSV olarak export eder.
    /// </summary>
    public async Task<byte[]> ExportStockToCsvAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            // Get all products with stock info
            var products = await GetLowStockProductsAsync(merchantId, 999999, ct); // Get all products

            var csv = new StringBuilder();
            csv.AppendLine("ProductId,ProductName,SKU,CurrentStock,MinStock,MaxStock,Status");

            foreach (var product in products)
            {
                csv.AppendLine($"{product.ProductId},{EscapeCsv(product.ProductName)},{EscapeCsv(product.SKU)},{product.CurrentStock},{product.MinStock},{product.MaxStock},{product.Status}");
            }

            return Encoding.UTF8.GetBytes(csv.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting stock to CSV");
            throw;
        }
    }

    /// <summary>
    /// CSV dosyasından stok verilerini import eder.
    /// </summary>
    public async Task<StockImportResult> ImportStockFromCsvAsync(Guid merchantId, Stream csvStream, CancellationToken ct = default)
    {
        var result = new StockImportResult
        {
            TotalRows = 0,
            SuccessCount = 0,
            ErrorCount = 0,
            Errors = new List<string>()
        };

        try
        {
            using var reader = new StreamReader(csvStream);
            
            // Skip header
            await reader.ReadLineAsync();
            
            var updates = new List<BulkStockUpdateModel>();
            var lineNumber = 1;

            while (!reader.EndOfStream)
            {
                lineNumber++;
                result.TotalRows++;

                var line = await reader.ReadLineAsync();
                if (string.IsNullOrWhiteSpace(line)) continue;

                var values = line.Split(',');
                
                if (values.Length < 4)
                {
                    result.ErrorCount++;
                    result.Errors.Add($"Line {lineNumber}: Invalid format");
                    continue;
                }

                if (!Guid.TryParse(values[0], out var productId))
                {
                    result.ErrorCount++;
                    result.Errors.Add($"Line {lineNumber}: Invalid ProductId");
                    continue;
                }

                if (!int.TryParse(values[3], out var stock))
                {
                    result.ErrorCount++;
                    result.Errors.Add($"Line {lineNumber}: Invalid stock value");
                    continue;
                }

                updates.Add(new BulkStockUpdateModel
                {
                    ProductId = productId,
                    NewStockLevel = stock
                });
            }

            // Send bulk update to API
            if (updates.Any())
            {
                var mapped = updates.Select(u => new UpdateStockRequest
                {
                    ProductId = u.ProductId,
                    ProductVariantId = null,
                    NewStockQuantity = u.NewStockLevel,
                    Reason = result.Errors.Any() ? "CSV Import" : null,
                    Notes = null
                }).ToList();

                var bulkRequest = new BulkUpdateStockRequest
                {
                    StockUpdates = mapped
                };

                var success = await BulkUpdateStockLevelsAsync(bulkRequest, ct);
                
                if (success)
                {
                    result.SuccessCount = updates.Count;
                }
                else
                {
                    result.ErrorCount += updates.Count;
                    result.Errors.Add("Bulk update failed");
                }
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error importing stock from CSV");
            result.Errors.Add($"Import error: {ex.Message}");
            return result;
        }
    }

    /// <summary>
    /// Reorder point ayarlar.
    /// </summary>
    public async Task<bool> SetReorderPointAsync(Guid productId, int minStock, int maxStock, CancellationToken ct = default)
    {
        // Backend'de reorder-point uçları yok; şimdilik desteklenmiyor.
        _logger.LogWarning("SetReorderPointAsync is not supported by backend API");
        return false;
    }

    /// <summary>
    /// Reorder points listesi getirir.
    /// </summary>
    public async Task<List<ReorderPointModel>> GetReorderPointsAsync(Guid merchantId, CancellationToken ct = default)
    {
        // Backend'de reorder-points uçları yok; şimdilik boş liste dön.
        _logger.LogWarning("GetReorderPointsAsync is not supported by backend API");
        return new List<ReorderPointModel>();
    }

    private string EscapeCsv(string value)
    {
        if (string.IsNullOrEmpty(value))
            return string.Empty;

        if (value.Contains(",") || value.Contains("\"") || value.Contains("\n"))
        {
            return $"\"{value.Replace("\"", "\"\"")}\"";
        }

        return value;
    }
}


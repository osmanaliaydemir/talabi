using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;
using Getir.MerchantPortal.Models;
using Microsoft.Extensions.Logging;

namespace Getir.MerchantPortal.Services;

public class InventoryService : IInventoryService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<InventoryService> _logger;

    public InventoryService(IApiClient apiClient, ILogger<InventoryService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<InventoryLevelModel>> GetInventoryLevelsAsync(bool includeVariants = true, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/inventory/levels?includeVariants={includeVariants.ToString().ToLowerInvariant()}";
            var response = await _apiClient.GetAsync<ApiResponse<List<InventoryLevelModel>>>(endpoint, ct);
            return response?.Data ?? new List<InventoryLevelModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory levels");
            return new List<InventoryLevelModel>();
        }
    }

    public async Task<List<InventoryCountModel>> GetInventoryCountHistoryAsync(DateTime? fromDate, DateTime? toDate, CancellationToken ct = default)
    {
        try
        {
            var query = BuildDateRangeQuery(fromDate, toDate);
            var endpoint = string.IsNullOrEmpty(query) ? "api/inventory/count/history" : $"api/inventory/count/history?{query}";
            var response = await _apiClient.GetAsync<ApiResponse<List<InventoryCountModel>>>(endpoint, ct);
            return response?.Data ?? new List<InventoryCountModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory count history");
            return new List<InventoryCountModel>();
        }
    }

    public async Task<List<InventoryDiscrepancyModel>> GetInventoryDiscrepanciesAsync(DateTime? fromDate, CancellationToken ct = default)
    {
        try
        {
            var query = fromDate.HasValue ? $"?fromDate={fromDate.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)}" : string.Empty;
            var endpoint = $"api/inventory/discrepancies{query}";
            var response = await _apiClient.GetAsync<ApiResponse<List<InventoryDiscrepancyModel>>>(endpoint, ct);
            return response?.Data ?? new List<InventoryDiscrepancyModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory discrepancies");
            return new List<InventoryDiscrepancyModel>();
        }
    }

    public async Task<InventoryTurnoverModel?> GetInventoryTurnoverAsync(DateTime fromDate, DateTime toDate, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/inventory/turnover-report?fromDate={fromDate:yyyy-MM-dd}&toDate={toDate:yyyy-MM-dd}";
            var response = await _apiClient.GetAsync<ApiResponse<InventoryTurnoverModel>>(endpoint, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory turnover report");
            return null;
        }
    }

    public async Task<List<SlowMovingInventoryModel>> GetSlowMovingInventoryAsync(int daysThreshold, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/inventory/slow-moving?daysThreshold={daysThreshold}";
            var response = await _apiClient.GetAsync<ApiResponse<List<SlowMovingInventoryModel>>>(endpoint, ct);
            return response?.Data ?? new List<SlowMovingInventoryModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving slow moving inventory items");
            return new List<SlowMovingInventoryModel>();
        }
    }

    public async Task<InventoryValuationModel?> GetInventoryValuationAsync(string valuationMethod, CancellationToken ct = default)
    {
        try
        {
            var method = valuationMethod?.Trim();
            if (string.IsNullOrEmpty(method))
            {
                method = "FIFO";
            }

            var endpoint = $"api/inventory/valuation?method={method}";
            var response = await _apiClient.GetAsync<ApiResponse<InventoryValuationModel>>(endpoint, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving inventory valuation using method {Method}", valuationMethod);
            return null;
        }
    }

    private static string BuildDateRangeQuery(DateTime? fromDate, DateTime? toDate)
    {
        var parts = new List<string>();
        if (fromDate.HasValue)
        {
            parts.Add($"fromDate={fromDate.Value:yyyy-MM-dd}");
        }

        if (toDate.HasValue)
        {
            parts.Add($"toDate={toDate.Value:yyyy-MM-dd}");
        }

        return string.Join("&", parts);
    }
}


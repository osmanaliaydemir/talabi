using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IInventoryService
{
    Task<List<InventoryLevelModel>> GetInventoryLevelsAsync(bool includeVariants = true, CancellationToken ct = default);
    Task<List<InventoryCountModel>> GetInventoryCountHistoryAsync(DateTime? fromDate, DateTime? toDate, CancellationToken ct = default);
    Task<List<InventoryDiscrepancyModel>> GetInventoryDiscrepanciesAsync(DateTime? fromDate, CancellationToken ct = default);
    Task<InventoryTurnoverModel?> GetInventoryTurnoverAsync(DateTime fromDate, DateTime toDate, CancellationToken ct = default);
    Task<List<SlowMovingInventoryModel>> GetSlowMovingInventoryAsync(int daysThreshold, CancellationToken ct = default);
    Task<InventoryValuationModel?> GetInventoryValuationAsync(string valuationMethod, CancellationToken ct = default);
}


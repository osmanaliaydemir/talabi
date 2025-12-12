using System;
using System.Collections.Generic;

namespace Getir.MerchantPortal.Models;

public class InventoryDashboardViewModel
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public int SlowMovingThresholdDays { get; set; } = 30;
    public string ValuationMethod { get; set; } = "FIFO";
    public bool IncludeVariants { get; set; } = true;

    public List<InventoryLevelModel> InventoryLevels { get; set; } = new();
    public InventoryTurnoverModel? Turnover { get; set; }
    public List<SlowMovingInventoryModel> SlowMovingItems { get; set; } = new();
    public InventoryValuationModel? Valuation { get; set; }
    public List<InventoryCountModel> CountHistory { get; set; } = new();
    public List<InventoryDiscrepancyModel> Discrepancies { get; set; } = new();

    public decimal TotalInventoryValue => Valuation?.TotalValue ?? 0m;
    public int TotalInventoryItems => Valuation?.TotalItems ?? 0;
    public decimal AverageTurnoverRate => Turnover?.AverageTurnoverRate ?? 0m;
}

public class InventoryLevelModel
{
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? VariantName { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public int CurrentStock { get; set; }
    public int MinimumStock { get; set; }
    public int MaximumStock { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalValue { get; set; }
    public InventoryStockStatus Status { get; set; }
    public DateTime LastUpdated { get; set; }
}

public class InventoryTurnoverModel
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public int TotalItems { get; set; }
    public decimal TotalValue { get; set; }
    public decimal AverageTurnoverRate { get; set; }
    public List<InventoryTurnoverItemModel> FastMovingItems { get; set; } = new();
    public List<InventoryTurnoverItemModel> SlowMovingItems { get; set; } = new();
}

public class InventoryTurnoverItemModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int CurrentStock { get; set; }
    public int StockOutQuantity { get; set; }
    public decimal TurnoverRate { get; set; }
    public decimal DaysToTurnover { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal StockValue { get; set; }
}

public class SlowMovingInventoryModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int CurrentStock { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalValue { get; set; }
    public DateTime? LastMovementDate { get; set; }
    public int DaysSinceLastMovement { get; set; }
}

public class InventoryValuationModel
{
    public ValuationMethodModel Method { get; set; }
    public DateTime ValuationDate { get; set; }
    public decimal TotalValue { get; set; }
    public int TotalItems { get; set; }
    public List<InventoryValuationItemModel> TopValueItems { get; set; } = new();
}

public class InventoryValuationItemModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitValue { get; set; }
    public decimal TotalValue { get; set; }
}

public class InventoryCountModel
{
    public Guid Id { get; set; }
    public DateTime CountDate { get; set; }
    public InventoryCountTypeModel CountType { get; set; }
    public InventoryCountStatusModel Status { get; set; }
    public int DiscrepancyCount { get; set; }
    public string? Notes { get; set; }
    public string? CreatedByName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class InventoryDiscrepancyModel
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? VariantName { get; set; }
    public int ExpectedQuantity { get; set; }
    public int ActualQuantity { get; set; }
    public int Variance { get; set; }
    public decimal VariancePercentage { get; set; }
    public InventoryDiscrepancyStatusModel Status { get; set; }
    public string? ResolutionNotes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ResolvedAt { get; set; }
}

public enum InventoryStockStatus
{
    InStock = 0,
    LowStock = 1,
    OutOfStock = 2,
    Overstock = 3,
    Discontinued = 4
}

public enum InventoryCountTypeModel
{
    Full = 0,
    Partial = 1,
    Cycle = 2,
    SpotCheck = 3,
    Annual = 4
}

public enum InventoryCountStatusModel
{
    InProgress = 0,
    Completed = 1,
    Cancelled = 2,
    PendingApproval = 3,
    Approved = 4
}

public enum InventoryDiscrepancyStatusModel
{
    Pending = 0,
    Resolved = 1,
    Investigating = 2,
    Approved = 3,
    Rejected = 4
}

public enum ValuationMethodModel
{
    FIFO = 0,
    LIFO = 1,
    WeightedAverage = 2,
    MarketPrice = 3,
    StandardCost = 4
}


namespace Getir.MerchantPortal.Models;

/// <summary>
/// Low stock product model
/// </summary>
public class LowStockProductModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string SKU { get; set; } = default!;
    public string? ImageUrl { get; set; }
    public int CurrentStock { get; set; }
    public int MinStock { get; set; }
    public int MaxStock { get; set; }
    public decimal UnitPrice { get; set; }
    public string Status { get; set; } = default!; // Critical, Low, Normal
}

/// <summary>
/// Stock import result
/// </summary>
public class StockImportResult
{
    public int TotalRows { get; set; }
    public int SuccessCount { get; set; }
    public int ErrorCount { get; set; }
    public List<string> Errors { get; set; } = new();
    public List<StockImportRow> ProcessedRows { get; set; } = new();
}

/// <summary>
/// Stock import row
/// </summary>
public class StockImportRow
{
    public int RowNumber { get; set; }
    public string ProductName { get; set; } = default!;
    public string? SKU { get; set; }
    public int NewStock { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}

/// <summary>
/// Reorder point model
/// </summary>
public class ReorderPointModel
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int CurrentStock { get; set; }
    public int MinimumStock { get; set; }
    public int MaximumStock { get; set; }
    public int ReorderPoint { get; set; }
    public int ReorderQuantity { get; set; }
    public bool AutoReorder { get; set; }
    public string? SupplierName { get; set; }
}

/// <summary>
/// Bulk stock update request
/// </summary>
public class BulkStockUpdateModel
{
    public Guid ProductId { get; set; }
    public int NewStockLevel { get; set; }
    public string? Reason { get; set; }
}


/// <summary>
/// Stock history timeline item
/// </summary>
public class StockHistoryTimelineItem
{
    public DateTime Timestamp { get; set; }
    public string ChangeType { get; set; } = default!; // In, Out, Adjustment
    public int PreviousQuantity { get; set; }
    public int NewQuantity { get; set; }
    public int ChangeAmount { get; set; }
    public string? Reason { get; set; }
    public string? ChangedBy { get; set; }
    public string Icon { get; set; } = default!;
    public string Color { get; set; } = default!;
}


using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

/// <summary>
/// Payment history filter model
/// </summary>
public class PaymentFilterModel
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? PaymentMethod { get; set; }
    public string? PaymentStatus { get; set; }
    public decimal? MinAmount { get; set; }
    public decimal? MaxAmount { get; set; }
    public string? OrderNumber { get; set; }
}

/// <summary>
/// Payment history list item
/// </summary>
public class PaymentListItemModel
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = default!;
    public string PaymentMethod { get; set; } = default!;
    public string Status { get; set; } = default!;
    public decimal Amount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? CustomerName { get; set; }
}

/// <summary>
/// Settlement report model
/// </summary>
public class SettlementReportModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TotalCommission { get; set; }
    public decimal NetAmount { get; set; }
    public int TotalOrders { get; set; }
    public int CompletedOrders { get; set; }
    public Dictionary<string, decimal> RevenueByMethod { get; set; } = new();
    public List<DailySettlementModel> DailyBreakdown { get; set; } = new();
}

/// <summary>
/// Daily settlement model
/// </summary>
public class DailySettlementModel
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public decimal Commission { get; set; }
    public decimal NetAmount { get; set; }
    public int OrderCount { get; set; }
}

/// <summary>
/// Top customer model
/// </summary>
public class TopCustomerModel
{
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = default!;
    public decimal TotalSpent { get; set; }
    public int OrderCount { get; set; }
}

/// <summary>
/// Payment method breakdown model
/// </summary>
public class PaymentMethodBreakdownModel
{
    public string Method { get; set; } = default!;
    public string DisplayName { get; set; } = default!;
    public int OrderCount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal Percentage { get; set; }
    public string Color { get; set; } = default!;
}

/// <summary>
/// Export request model
/// </summary>
public class PaymentExportRequest
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Status { get; set; }
    [Required]
    public string Format { get; set; } = "excel"; // excel or pdf
}

public class CashCollectionsViewModel
{
    public PagedResult<PaymentResponse> Collections { get; set; } = new();
    public string? Status { get; set; }
    public int Page { get; set; } = 1;
    public ProcessSettlementInput Settlement { get; set; } = new();
}

public class ProcessSettlementInput
{
    [Required]
    [Display(Name = "Mağaza")]
    public Guid MerchantId { get; set; }

    [Range(0, 1, ErrorMessage = "Komisyon oranı 0 ile 1 arasında olmalıdır.")]
    [Display(Name = "Komisyon Oranı")]
    public decimal CommissionRate { get; set; }

    [Display(Name = "Açıklama")]
    public string? Notes { get; set; }

    [Display(Name = "Havale Referansı")]
    public string? BankTransferReference { get; set; }

    public string? ReturnStatus { get; set; }
    public int ReturnPage { get; set; } = 1;
}


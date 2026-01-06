namespace Talabi.Core.Entities;

public class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public Guid ProductId { get; set; }
    public Product? Product { get; set; }

    // Customer-facing order item ID (6-digit unique number)
    public string CustomerOrderItemId { get; set; } = string.Empty;

    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    // JSON serialized list of selected options
    public string? SelectedOptions { get; set; }

    // Cancellation fields
    public bool IsCancelled { get; set; } = false;
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }
}

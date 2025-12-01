namespace Talabi.Core.Entities;

public class CustomerNotification : BaseEntity
{
    public int CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "general"; // "OrderStatusChanged", "OrderDelivered", "Promotion", etc.

    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }

    public int? OrderId { get; set; }
    public Order? Order { get; set; }
}


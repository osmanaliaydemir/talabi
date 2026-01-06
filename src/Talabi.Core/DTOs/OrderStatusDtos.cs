namespace Talabi.Core.DTOs;

public class OrderDetailDto
{
    public Guid Id { get; set; }
    public string CustomerOrderId { get; set; } = string.Empty;
    public Guid VendorId { get; set; }
    public string VendorName { get; set; } = string.Empty;
    public string CustomerId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }

    public List<OrderItemDetailDto> Items { get; set; } = new();
    public List<OrderStatusHistoryDto> StatusHistory { get; set; } = new();
    public OrderCourierDto? ActiveOrderCourier { get; set; }
}

public class OrderItemDetailDto
{
    public Guid ProductId { get; set; }
    public string CustomerOrderItemId { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public string? ProductImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public bool IsCancelled { get; set; } = false;
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }
    public List<CartItemOptionDto>? SelectedOptions { get; set; }
}

public class OrderStatusHistoryDto
{
    public string Status { get; set; } = string.Empty;
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; } = string.Empty;
}

public class UpdateOrderStatusDto
{
    public string Status { get; set; } = string.Empty;
    public string? Note { get; set; }
}

public class CancelOrderDto
{
    public string Reason { get; set; } = string.Empty;
}

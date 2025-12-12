using Talabi.Core.Enums;

namespace Talabi.Portal.Models;

public class VendorOrderDto
{
    public Guid Id { get; set; }
    public string CustomerOrderId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public int ItemCount { get; set; }
}

public class VendorOrderDetailDto : VendorOrderDto
{
    public List<VendorOrderItemDto> Items { get; set; } = new();
    public string? DeliveryAddress { get; set; }
    public string? CustomerPhone { get; set; }
}

public class VendorOrderItemDto
{
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice => UnitPrice * Quantity;
}

public class UpdateOrderStatusDto
{
    public OrderStatus Status { get; set; }
}

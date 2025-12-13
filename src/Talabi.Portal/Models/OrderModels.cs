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
    
    // Financials
    public decimal DeliveryFee { get; set; }
    
    // Status & Cancellation
    public string? CancelReason { get; set; }
    public List<OrderStatusHistoryDto> StatusHistory { get; set; } = new();
    
    // Courier Info
    public string? CourierName { get; set; }
    public string? CourierPhone { get; set; }
    public string? CourierStatus { get; set; }
}

public class VendorOrderItemDto
{
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice => UnitPrice * Quantity;
}

public class OrderStatusHistoryDto
{
    public OrderStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? Note { get; set; }
}

public class AvailableCourierDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string VehicleType { get; set; } = string.Empty;
    public double AverageRating { get; set; }
    public int TotalDeliveries { get; set; }
    public int CurrentActiveOrders { get; set; }
    public int MaxActiveOrders { get; set; }
    public double Distance { get; set; }
    public int EstimatedArrivalMinutes { get; set; }
}

public class UpdateOrderStatusDto
{
    public OrderStatus Status { get; set; }
}

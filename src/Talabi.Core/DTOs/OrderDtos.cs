namespace Talabi.Core.DTOs;

public class CreateOrderDto
{
    public Guid VendorId { get; set; }
    public List<OrderItemDto> Items { get; set; } = new();
    public Guid? DeliveryAddressId { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Note { get; set; }
    public string? CouponCode { get; set; }
    public Guid? CampaignId { get; set; }
}

public class OrderItemDto
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
}

public class OrderDto
{
    public Guid Id { get; set; }
    public string CustomerOrderId { get; set; } = string.Empty;
    public Guid VendorId { get; set; }
    public string VendorName { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public OrderCourierDto? ActiveOrderCourier { get; set; }
}

public class OrderCourierDto
{
    public Guid CourierId { get; set; }
    public string CourierName { get; set; } = string.Empty;
    public string? CourierImageUrl { get; set; }
    public string? CourierPhone { get; set; }
}

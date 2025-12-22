using Talabi.Core.Entities;

namespace Talabi.Core.DTOs;

public class CalculateOrderDto
{
    public Guid VendorId { get; set; }
    public List<OrderItemDto> Items { get; set; } = new();
    public Guid? DeliveryAddressId { get; set; }
    public string? CouponCode { get; set; }
}

public class OrderCalculationResultDto
{
    public decimal Subtotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public CouponDto? AppliedCoupon { get; set; }
    public List<OrderItemCalculationDto> Items { get; set; } = new();
}

public class OrderItemCalculationDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
}

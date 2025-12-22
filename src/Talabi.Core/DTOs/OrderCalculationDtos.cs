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

public class CouponDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public int DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal DiscountAmount { get; set; } // The actual calculated discount amount for this order
    public string Description { get; set; } = string.Empty;
}

public class OrderItemCalculationDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
}

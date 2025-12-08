using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Order : BaseEntity
{
    public string CustomerId { get; set; } = string.Empty;
    public AppUser? Customer { get; set; }

    public Guid VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    // Customer-facing order ID (6-digit unique number)
    public string CustomerOrderId { get; set; } = string.Empty;

    // Delivery information
    public Guid? DeliveryAddressId { get; set; }
    public UserAddress? DeliveryAddress { get; set; }

    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }

    // Delivery tracking
    public DateTime? EstimatedDeliveryTime { get; set; }

    // Financials - Müşteriden alınan delivery fee (Order'da kalıyor)
    public decimal DeliveryFee { get; set; } = 0;

    // Navigation - OrderCouriers
    public OrderCourier? ActiveOrderCourier { get; set; }
    public ICollection<OrderCourier> OrderCouriers { get; set; } = new List<OrderCourier>();

    // Navigation
    public DeliveryProof? DeliveryProof { get; set; }
    public CourierEarning? CourierEarning { get; set; }

    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}

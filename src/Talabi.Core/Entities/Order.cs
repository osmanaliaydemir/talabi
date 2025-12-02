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

    public Guid? CourierId { get; set; }
    public Courier? Courier { get; set; }

    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }

    // Delivery tracking
    public DateTime? EstimatedDeliveryTime { get; set; }
    public DateTime? CourierAssignedAt { get; set; }
    public DateTime? CourierAcceptedAt { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
    public DateTime? DeliveredAt { get; set; }

    // Financials
    public decimal DeliveryFee { get; set; } = 0;
    public decimal? CourierTip { get; set; }

    // Navigation
    public DeliveryProof? DeliveryProof { get; set; }
    public CourierEarning? CourierEarning { get; set; }

    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}

using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Order : BaseEntity
{
    public string CustomerId { get; set; } = string.Empty;
    public AppUser? Customer { get; set; }

    public int VendorId { get; set; }
    public Vendor? Vendor { get; set; }
    
    // Delivery information
    public int? DeliveryAddressId { get; set; }
    public UserAddress? DeliveryAddress { get; set; }
    
    public int? CourierId { get; set; }
    public Courier? Courier { get; set; }

    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.Pending;
    public DateTime? CancelledAt { get; set; }
    public string? CancelReason { get; set; }
    
    // Delivery tracking
    public DateTime? EstimatedDeliveryTime { get; set; }
    public DateTime? DeliveredAt { get; set; }
    
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<OrderStatusHistory> StatusHistory { get; set; } = new List<OrderStatusHistory>();
}

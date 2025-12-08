using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class OrderCourier : BaseEntity
{
    // Foreign Keys
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    
    public Guid CourierId { get; set; }
    public Courier? Courier { get; set; }
    
    // İşlem Zamanları
    public DateTime? CourierAssignedAt { get; set; }
    public DateTime? CourierAcceptedAt { get; set; }
    public DateTime? CourierRejectedAt { get; set; }
    public string? RejectReason { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    
    // Finansal Bilgiler
    public decimal DeliveryFee { get; set; } = 0;
    public decimal? CourierTip { get; set; }
    
    // Meta Bilgiler
    public bool IsActive { get; set; } = true;  // Bu atama aktif mi?
    public OrderCourierStatus Status { get; set; } = OrderCourierStatus.Assigned;
}


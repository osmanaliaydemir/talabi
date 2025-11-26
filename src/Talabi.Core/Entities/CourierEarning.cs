namespace Talabi.Core.Entities;

public class CourierEarning : BaseEntity
{
    public int CourierId { get; set; }
    public Courier? Courier { get; set; }
    
    public int OrderId { get; set; }
    public Order? Order { get; set; }
    
    public decimal BaseDeliveryFee { get; set; }
    public decimal DistanceBonus { get; set; }
    public decimal TipAmount { get; set; }
    public decimal TotalEarning { get; set; }
    
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    public bool IsPaid { get; set; } = false;
    public DateTime? PaidAt { get; set; }
}

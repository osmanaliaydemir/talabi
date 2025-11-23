using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class OrderStatusHistory : BaseEntity
{
    public int OrderId { get; set; }
    public Order? Order { get; set; }
    
    public OrderStatus Status { get; set; }
    public string? Note { get; set; }
    public string CreatedBy { get; set; } = "System"; // UserId or "System"
}

namespace Talabi.Core.Entities;

public class CourierNotification : BaseEntity
{
    public int CourierId { get; set; }
    public Courier? Courier { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "general";

    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }

    public int? OrderId { get; set; }
    public Order? Order { get; set; }
}


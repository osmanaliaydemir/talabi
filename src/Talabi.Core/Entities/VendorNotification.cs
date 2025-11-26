namespace Talabi.Core.Entities;

public class VendorNotification : BaseEntity
{
    public int VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    public string Type { get; set; } = string.Empty; // "NewOrder", "OrderStatusChanged", "NewReview"
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public int? RelatedEntityId { get; set; } // OrderId or ReviewId
}

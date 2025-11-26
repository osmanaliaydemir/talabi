namespace Talabi.Core.DTOs;

public class VendorNotificationDto
{
    public int Id { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public int? RelatedEntityId { get; set; }
    public DateTime CreatedAt { get; set; }
}

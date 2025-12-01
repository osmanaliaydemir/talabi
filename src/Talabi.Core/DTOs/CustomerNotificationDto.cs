namespace Talabi.Core.DTOs;

public class CustomerNotificationDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "general";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReadAt { get; set; }
    public int? OrderId { get; set; }
}

public class CustomerNotificationResponseDto
{
    public IEnumerable<CustomerNotificationDto> Items { get; set; } = new List<CustomerNotificationDto>();
    public int UnreadCount { get; set; }
}


namespace Talabi.Core.Entities;

public class NotificationSettings : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public bool OrderUpdates { get; set; } = true;
    public bool Promotions { get; set; } = true;
    public bool NewProducts { get; set; } = true;
}

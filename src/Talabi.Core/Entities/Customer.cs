namespace Talabi.Core.Entities;

public class Customer : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    // Additional customer-specific fields can be added here in the future
    // For now, we keep it simple with just the User relationship
}

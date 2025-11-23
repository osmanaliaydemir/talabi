namespace Talabi.Core.Entities;

public class UserAddress : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public string Title { get; set; } = string.Empty; // "Ev", "İş", etc.
    public string FullAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public string? PostalCode { get; set; }
    public bool IsDefault { get; set; }
    
    // Location coordinates for map integration
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

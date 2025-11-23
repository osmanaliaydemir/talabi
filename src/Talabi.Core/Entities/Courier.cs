namespace Talabi.Core.Entities;

public class Courier : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; } // "Bisiklet", "Motosiklet", "Araba"
    public bool IsActive { get; set; } = true;
    
    // Current location
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
    
    public ICollection<Order> Orders { get; set; } = new List<Order>();
}


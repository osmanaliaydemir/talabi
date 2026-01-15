using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Vendor : BaseEntity
{
    public VendorType Type { get; set; } = VendorType.Restaurant; // Default: Restaurant
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Address { get; set; } = string.Empty;
    public string? City { get; set; }

    // Location for distance filtering
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    // Delivery settings
    public int DeliveryRadiusInKm { get; set; } = 5; // Default: 5 km radius

    // Rating (average rating from orders/reviews)
    public decimal? Rating { get; set; }
    public int RatingCount { get; set; } = 0;

    // Profile information
    public string? PhoneNumber { get; set; }
    public string? Description { get; set; }
    public string? ShamCashAccountNumber { get; set; }

    // Business settings
    public decimal? MinimumOrderAmount { get; set; }
    public decimal? DeliveryFee { get; set; }
    public int? EstimatedDeliveryTime { get; set; } // in minutes
    public BusyStatus BusyStatus { get; set; } = BusyStatus.Normal;
    public bool IsActive { get; set; } = true;
    public string? OpeningHours { get; set; } // JSON format

    // Commission Settings
    public decimal CommissionRate { get; set; } = 20; // Usage: 20 for 20% commission

    public string OwnerId { get; set; } = string.Empty;
    public AppUser? Owner { get; set; }

    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<VendorWorkingHour> WorkingHours { get; set; } = new List<VendorWorkingHour>();
}

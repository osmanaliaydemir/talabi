using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Courier : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; } // "Bisiklet", "Motosiklet", "Araba"
    public bool IsActive { get; set; } = true;
    
    // Status Management
    public CourierStatus Status { get; set; } = CourierStatus.Offline;
    public int MaxActiveOrders { get; set; } = 3;
    public int CurrentActiveOrders { get; set; } = 0;
    
    // Current location
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
    
    // Earnings
    public decimal TotalEarnings { get; set; } = 0;
    public decimal CurrentDayEarnings { get; set; } = 0;
    public DateTime? LastEarningsReset { get; set; }
    
    // Statistics
    public int TotalDeliveries { get; set; } = 0;
    public double AverageRating { get; set; } = 0;
    public int TotalRatings { get; set; } = 0;
    
    // Working Hours
    public DateTime? LastActiveAt { get; set; }
    public TimeSpan? WorkingHoursStart { get; set; }
    public TimeSpan? WorkingHoursEnd { get; set; }
    public bool IsWithinWorkingHours { get; set; } = true; // Çalışma saati kontrolü aktif mi?
    
    // Navigation - OrderCouriers (Order ile ilişki artık OrderCouriers üzerinden)
    public ICollection<OrderCourier> OrderCouriers { get; set; } = new List<OrderCourier>();
    public ICollection<CourierNotification> Notifications { get; set; } = new List<CourierNotification>();
}


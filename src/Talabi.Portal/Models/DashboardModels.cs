namespace Talabi.Portal.Models;

public class VendorProfileDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? ImageUrl { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Description { get; set; }
    public double Rating { get; set; }
    public int RatingCount { get; set; }
}


public class HomeViewModel
{
    public VendorProfileDto Profile { get; set; } = new();
    public VendorSettingsDto Settings { get; set; } = new();
    
    // Dashboard Stats
    public int PendingOrdersCount { get; set; }
    public int CompletedOrdersToday { get; set; }
    public decimal TotalRevenueToday { get; set; }
    
    // Enriched Stats
    public decimal AverageOrderValue { get; set; }
    public double CancellationRate { get; set; }
    public int ActiveProductsCount { get; set; }
    
    // Activity Feed
    public List<DashboardActivity> RecentActivities { get; set; } = new();
}

public class DashboardActivity
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string Type { get; set; } = string.Empty; // NewOrder, Alert, Info
    
    public string GetTimeAgo()
    {
        var span = DateTime.UtcNow - CreatedAt;
        if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes}m ago";
        if (span.TotalHours < 24) return $"{(int)span.TotalHours}h ago";
        return $"{(int)span.TotalDays}d ago";
    }
}

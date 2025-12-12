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
    
    // Dashboard Stats (API modeline göre eklenebilir)
    public int PendingOrdersCount { get; set; }
    public int CompletedOrdersToday { get; set; }
    public decimal TotalRevenueToday { get; set; }
}

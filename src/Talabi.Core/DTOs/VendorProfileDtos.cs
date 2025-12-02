namespace Talabi.Core.DTOs;

// Existing DTOs remain...

public class VendorProfileDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Address { get; set; } = string.Empty;
    public string? City { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Description { get; set; }
    public decimal? Rating { get; set; }
    public int RatingCount { get; set; }
}

public class UpdateVendorProfileDto
{
    public string? Name { get; set; }
    public string? ImageUrl { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Description { get; set; }
}

public class VendorSettingsDto
{
    public decimal? MinimumOrderAmount { get; set; }
    public decimal? DeliveryFee { get; set; }
    public int? EstimatedDeliveryTime { get; set; }
    public bool IsActive { get; set; }
    public string? OpeningHours { get; set; }
}

public class UpdateVendorSettingsDto
{
    public decimal? MinimumOrderAmount { get; set; }
    public decimal? DeliveryFee { get; set; }
    public int? EstimatedDeliveryTime { get; set; }
    public bool? IsActive { get; set; }
    public string? OpeningHours { get; set; }
}

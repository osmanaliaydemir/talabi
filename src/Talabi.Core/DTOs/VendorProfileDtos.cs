using System.Text.Json.Serialization;
using Talabi.Core.Enums;

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
    public string? ShamCashAccountNumber { get; set; }
    public decimal? Rating { get; set; }
    public int RatingCount { get; set; }
    public BusyStatus BusyStatus { get; set; }
    public VendorType Type { get; set; }
    public List<WorkingHourDto> WorkingHours { get; set; } = new List<WorkingHourDto>();
}

public class UpdateVendorProfileDto
{
    [JsonPropertyName("name")] public string? Name { get; set; }
    [JsonPropertyName("imageUrl")] public string? ImageUrl { get; set; }
    [JsonPropertyName("address")] public string? Address { get; set; }
    [JsonPropertyName("city")] public string? City { get; set; }
    [JsonPropertyName("latitude")] public double? Latitude { get; set; }
    [JsonPropertyName("longitude")] public double? Longitude { get; set; }
    [JsonPropertyName("phoneNumber")] public string? PhoneNumber { get; set; }
    [JsonPropertyName("description")] public string? Description { get; set; }

    [JsonPropertyName("shamCashAccountNumber")]
    public string? ShamCashAccountNumber { get; set; }

    [JsonPropertyName("workingHours")] public List<WorkingHourDto>? WorkingHours { get; set; }
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

public class UpdateVendorImageDto
{
    [JsonPropertyName("imageUrl")] public string ImageUrl { get; set; } = string.Empty;
}

public class UpdateVendorActiveStatusDto
{
    [JsonPropertyName("isActive")] public bool IsActive { get; set; }
}

public class UpdateVendorBusyStatusDto
{
    [JsonPropertyName("busyStatus")] public BusyStatus BusyStatus { get; set; }
}
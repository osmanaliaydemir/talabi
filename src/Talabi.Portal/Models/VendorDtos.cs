using Talabi.Core.Enums;

namespace Talabi.Portal.Models;

public class VendorListDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public string? ImageUrl { get; set; }
}

public class VendorDetailDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? PhoneNumber { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? City { get; set; } // Added
    public string? Description { get; set; }
    public string? ItemsDescription { get; set; } // Added
    public double? Latitude { get; set; } // Added
    public double? Longitude { get; set; } // Added
    public string? ImageUrl { get; set; } // Added
    public string? CoverImageUrl { get; set; } // Added
    public decimal? MinimumOrderAmount { get; set; } // Added
    public int? DeliveryTimeMinutes { get; set; } // Added
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
}

using System.ComponentModel.DataAnnotations;
using Talabi.Core.DTOs;

namespace Talabi.Portal.Models;

public class VendorDeliveryZoneDto
{
    public Guid Id { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string DistrictName { get; set; } = string.Empty;
    public string LocalityName { get; set; } = string.Empty;
    public decimal? DeliveryFee { get; set; }
    public decimal? MinimumOrderAmount { get; set; }
    public bool IsActive { get; set; }
}

public class CreateDeliveryZoneViewModel
{
    [Required]
    public Guid CityId { get; set; }
    
    [Required]
    public List<Guid> SelectedDistricts { get; set; } = new();

    public decimal? DeliveryFee { get; set; }
    public decimal? MinimumOrderAmount { get; set; }
}



public class DeliveryZonesViewModel
{
    public List<VendorDeliveryZoneDto> Zones { get; set; } = new();
    
    // For dropdowns
    public List<LocationItemDto> Cities { get; set; } = new();
    public List<LocationItemDto> AvailableDistricts { get; set; } = new();
    
    public Guid SelectedCityId { get; set; }
}

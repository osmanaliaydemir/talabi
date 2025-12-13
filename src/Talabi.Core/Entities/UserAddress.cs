using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class UserAddress : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public string Title { get; set; } = string.Empty; // "Ev", "İş", etc.
    public string FullAddress { get; set; } = string.Empty;
    
    // Relational Location Data
    public Guid? CountryId { get; set; }
    [ForeignKey("CountryId")]
    public Country? Country { get; set; }

    public Guid? CityId { get; set; }
    [ForeignKey("CityId")]
    public City? City { get; set; }

    public Guid? DistrictId { get; set; }
    [ForeignKey("DistrictId")]
    public District? District { get; set; }

    public Guid? LocalityId { get; set; }
    [ForeignKey("LocalityId")]
    public Locality? Locality { get; set; }

    public string? PostalCode { get; set; }
    public bool IsDefault { get; set; }
    
    // Location coordinates for map integration
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

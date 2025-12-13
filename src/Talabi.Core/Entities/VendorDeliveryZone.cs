using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class VendorDeliveryZone : BaseEntity
{
    public Guid VendorId { get; set; }
    [ForeignKey("VendorId")]
    public Vendor? Vendor { get; set; }

    public Guid? CityId { get; set; } // Kept for reference, though District knows City
    
    public Guid DistrictId { get; set; }
    [ForeignKey("DistrictId")]
    public District? District { get; set; }

    public Guid? LocalityId { get; set; }
    [ForeignKey("LocalityId")]
    public Locality? Locality { get; set; }

    // Optional overrides for this specific zone
    public decimal? DeliveryFee { get; set; }
    public decimal? MinimumOrderAmount { get; set; }

    public bool IsActive { get; set; } = true;
}

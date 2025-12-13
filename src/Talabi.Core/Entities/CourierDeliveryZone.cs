using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class CourierDeliveryZone : BaseEntity
{
    public Guid CourierId { get; set; }
    [ForeignKey("CourierId")]
    public Courier? Courier { get; set; }

    public Guid DistrictId { get; set; }
    [ForeignKey("DistrictId")]
    public District? District { get; set; }

    public bool IsActive { get; set; } = true;
}

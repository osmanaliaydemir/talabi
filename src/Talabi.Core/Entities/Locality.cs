using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class Locality : BaseEntity
{
    [Required]
    public string NameTr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public Guid DistrictId { get; set; }
    [ForeignKey("DistrictId")]
    public District? District { get; set; }
}

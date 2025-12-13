using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class District : BaseEntity
{
    [Required]
    public string NameTr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public Guid CityId { get; set; }
    [ForeignKey("CityId")]
    public City? City { get; set; }

    public ICollection<Locality> Localities { get; set; } = new List<Locality>();
}

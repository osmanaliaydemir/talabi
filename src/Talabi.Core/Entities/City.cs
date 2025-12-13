using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Talabi.Core.Entities;

public class City : BaseEntity
{
    [Required]
    public string NameTr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;

    public Guid CountryId { get; set; }
    [ForeignKey("CountryId")]
    public Country? Country { get; set; }

    public ICollection<District> Districts { get; set; } = new List<District>();
}

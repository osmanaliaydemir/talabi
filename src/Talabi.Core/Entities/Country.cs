using System.ComponentModel.DataAnnotations;

namespace Talabi.Core.Entities;

public class Country : BaseEntity
{
    [Required]
    public string NameTr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    
    public string Code { get; set; } = string.Empty; // e.g. TR, SY

    public ICollection<City> Cities { get; set; } = new List<City>();
}

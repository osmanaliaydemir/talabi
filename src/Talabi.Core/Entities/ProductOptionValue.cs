using System.ComponentModel.DataAnnotations;

namespace Talabi.Core.Entities;

public class ProductOptionValue : BaseEntity
{
    public Guid OptionGroupId { get; set; }
    public ProductOptionGroup OptionGroup { get; set; } = null!;

    [Required] [MaxLength(100)] public string Name { get; set; } = string.Empty;

    public decimal PriceAdjustment { get; set; } = 0; // Additional cost (can be 0 or negative)
    public bool IsDefault { get; set; } = false;

    public int DisplayOrder { get; set; } = 0;
}

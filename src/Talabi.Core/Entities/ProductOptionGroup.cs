using System.ComponentModel.DataAnnotations;

namespace Talabi.Core.Entities;

public class ProductOptionGroup : BaseEntity
{
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;

    [Required] [MaxLength(100)] public string Name { get; set; } = string.Empty;

    // Configuration
    public bool IsRequired { get; set; } = false; // Must select at least one?
    public bool AllowMultiple { get; set; } = false; // Checkbox vs Radio?

    public int MinSelection { get; set; } = 0; // For validation (e.g. choose at least 2)
    public int MaxSelection { get; set; } = 0; // For validation (e.g. choose max 3, 0 means unlimited)

    public int DisplayOrder { get; set; } = 0;

    public ICollection<ProductOptionValue> Options { get; set; } = new List<ProductOptionValue>();
}

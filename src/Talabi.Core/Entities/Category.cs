using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Category : BaseEntity
{
    public VendorType VendorType { get; set; } = VendorType.Restaurant; // Default: Restaurant
    public string Name { get; set; } = string.Empty; // Default/System name
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; } = 0; // Display order for sorting
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<CategoryTranslation> Translations { get; set; } = new List<CategoryTranslation>();
}

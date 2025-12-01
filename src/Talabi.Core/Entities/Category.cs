namespace Talabi.Core.Entities;

public class Category : BaseEntity
{
    public string Name { get; set; } = string.Empty; // Default/System name
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<CategoryTranslation> Translations { get; set; } = new List<CategoryTranslation>();
}

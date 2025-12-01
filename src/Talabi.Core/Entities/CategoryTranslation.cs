namespace Talabi.Core.Entities;

public class CategoryTranslation : BaseEntity
{
    public int CategoryId { get; set; }
    public Category? Category { get; set; }

    public string LanguageCode { get; set; } = string.Empty; // tr, en, ar
    public string Name { get; set; } = string.Empty;
}

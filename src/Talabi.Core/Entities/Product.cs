namespace Talabi.Core.Entities;

public class Product : BaseEntity
{
    public Guid VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; } // Deprecated, use CategoryId
    public Guid? CategoryId { get; set; }
    public Category? ProductCategory { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }

    // Product availability and stock management
    public bool IsAvailable { get; set; } = true;
    public int? Stock { get; set; }
    public int? PreparationTime { get; set; } // in minutes
}

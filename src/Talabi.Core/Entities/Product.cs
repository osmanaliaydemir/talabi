namespace Talabi.Core.Entities;

public class Product : BaseEntity
{
    public int VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
}

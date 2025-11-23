namespace Talabi.Core.DTOs;

public class ProductDto
{
    public int Id { get; set; }
    public int VendorId { get; set; }
    public string? VendorName { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
}

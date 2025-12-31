using Talabi.Core.Enums;

namespace Talabi.Core.DTOs;

public class ProductDto
{
    public Guid Id { get; set; }
    public Guid VendorId { get; set; }
    public string? VendorName { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public VendorType? VendorType { get; set; }
    public decimal Price { get; set; }
    public Currency Currency { get; set; } = Currency.TRY;
    public string? ImageUrl { get; set; }
    public bool IsBestSeller { get; set; }
}

public class VendorProductDto
{
    public Guid Id { get; set; }
    public Guid VendorId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public Currency Currency { get; set; } = Currency.TRY;
    public string? ImageUrl { get; set; }
    public bool IsAvailable { get; set; }
    public int? Stock { get; set; }
    public int? PreparationTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateProductDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public Currency Currency { get; set; } = Currency.TRY; // Required
    public string? ImageUrl { get; set; }
    public bool IsAvailable { get; set; } = true;
    public int? Stock { get; set; }
    public int? PreparationTime { get; set; }
}

public class UpdateProductDto
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal? Price { get; set; }
    public Currency? Currency { get; set; }
    public string? ImageUrl { get; set; }
    public bool? IsAvailable { get; set; }
    public int? Stock { get; set; }
    public int? PreparationTime { get; set; }
}

public class UpdateProductAvailabilityDto
{
    public bool IsAvailable { get; set; }
}

public class UpdateProductPriceDto
{
    public decimal Price { get; set; }
}


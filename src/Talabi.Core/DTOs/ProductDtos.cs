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
    public double? Rating { get; set; }
    public int ReviewCount { get; set; }
    public List<ProductOptionGroupDto> OptionGroups { get; set; } = new List<ProductOptionGroupDto>();
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
    public List<ProductOptionGroupDto> OptionGroups { get; set; } = new List<ProductOptionGroupDto>();
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
    public List<CreateProductOptionGroupDto>? OptionGroups { get; set; }
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
    public List<CreateProductOptionGroupDto>? OptionGroups { get; set; }
}

public class UpdateProductAvailabilityDto
{
    public bool IsAvailable { get; set; }
}

public class UpdateProductPriceDto
{
    public decimal Price { get; set; }
}

public class ProductOptionGroupDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsRequired { get; set; }
    public bool AllowMultiple { get; set; }
    public int MinSelection { get; set; }
    public int MaxSelection { get; set; }
    public int DisplayOrder { get; set; }
    public List<ProductOptionValueDto> Options { get; set; } = new List<ProductOptionValueDto>();
}

public class ProductOptionValueDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal PriceAdjustment { get; set; }
    public bool IsDefault { get; set; }
    public int DisplayOrder { get; set; }
}

public class CreateProductOptionGroupDto
{
    public string Name { get; set; } = string.Empty;
    public bool IsRequired { get; set; }
    public bool AllowMultiple { get; set; }
    public int MinSelection { get; set; } = 0;
    public int MaxSelection { get; set; } = 0;
    public int DisplayOrder { get; set; } = 0;
    public List<CreateProductOptionValueDto>? Options { get; set; }
}

public class CreateProductOptionValueDto
{
    public string Name { get; set; } = string.Empty;
    public decimal PriceAdjustment { get; set; } = 0;
    public bool IsDefault { get; set; } = false;
    public int DisplayOrder { get; set; } = 0;
}



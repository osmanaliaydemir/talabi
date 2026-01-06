using System.ComponentModel.DataAnnotations;

namespace Talabi.Portal.Models;

public class VendorProductDto
{
    public Guid Id { get; set; }
    public Guid VendorId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "TRY";
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
    [Required] public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "TRY";
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
    public string? Currency { get; set; }
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

public class PagedResultDto<T>
{
    public List<T> Items { get; set; } = new();
    public long TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
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

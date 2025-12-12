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
}

public class CreateProductDto
{
    [Required]
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "TRY";
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
    public string? Currency { get; set; }
    public string? ImageUrl { get; set; }
    public bool? IsAvailable { get; set; }
    public int? Stock { get; set; }
    public int? PreparationTime { get; set; }
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

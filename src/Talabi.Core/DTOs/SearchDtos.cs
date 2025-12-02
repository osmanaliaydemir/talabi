namespace Talabi.Core.DTOs;

public class ProductSearchRequestDto
{
    public string? Query { get; set; }
    public string? Category { get; set; }
    public Guid? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public Guid? VendorId { get; set; }
    public string? SortBy { get; set; } // "price_asc", "price_desc", "name", "newest"
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class VendorSearchRequestDto
{
    public string? Query { get; set; }
    public string? City { get; set; }
    public decimal? MinRating { get; set; }

    // Distance filtering (requires user location)
    public double? UserLatitude { get; set; }
    public double? UserLongitude { get; set; }
    public double? MaxDistanceInKm { get; set; }

    public string? SortBy { get; set; } // "name", "newest", "rating_desc", "popularity", "distance"
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class PagedResultDto<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class AutocompleteResultDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty; // "product" or "vendor"
}

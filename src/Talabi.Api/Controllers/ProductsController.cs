using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Ürün işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// ProductsController constructor
    /// </summary>
    /// <param name="unitOfWork">Unit of Work instance</param>
    public ProductsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Ürün arama endpoint'i - Filtreleme, sıralama ve sayfalama desteği ile
    /// </summary>
    /// <param name="request">Arama parametreleri</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("search")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> Search([FromQuery] ProductSearchRequestDto request)
    {
        IQueryable<Product> query = _unitOfWork.Products.Query()
            .Include(p => p.Vendor);

        // Text search - Case-insensitive search helper kullanımı
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            query = query.WhereContainsIgnoreCase(p => p.Name, request.Query);
            // Description için de case-insensitive search
            if (!string.IsNullOrWhiteSpace(request.Query))
            {
                query = query.Where(p => p.Description != null && 
                    p.Description.ToLower().Contains(request.Query.ToLower()));
            }
        }

        // Category filter
        if (request.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == request.CategoryId.Value);
        }
        else if (!string.IsNullOrWhiteSpace(request.Category))
        {
            // Fallback to string match (deprecated)
            query = query.Where(p => p.Category == request.Category);
        }

        // Price range filter
        if (request.MinPrice.HasValue)
        {
            query = query.Where(p => p.Price >= request.MinPrice.Value);
        }

        if (request.MaxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= request.MaxPrice.Value);
        }

        // Vendor filter
        if (request.VendorId.HasValue)
        {
            query = query.Where(p => p.VendorId == request.VendorId.Value);
        }

        // Sorting
        IOrderedQueryable<Product> orderedQuery = request.SortBy?.ToLower() switch
        {
            "price_asc" => query.OrderBy(p => p.Price),
            "price_desc" => query.OrderByDescending(p => p.Price),
            "name" => query.OrderBy(p => p.Name),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            _ => query.OrderBy(p => p.Name)
        };

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                VendorName = p.Vendor != null ? p.Vendor.Name : null,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            },
            request.Page,
            request.PageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<ProductDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result, "Ürünler başarıyla getirildi"));
    }

    /// <summary>
    /// Kategorileri getirir - Dil desteği ile
    /// </summary>
    /// <param name="lang">Dil kodu (tr, en, ar) - Varsayılan: tr</param>
    /// <returns>Kategori listesi</returns>
    [HttpGet("categories")]
    public async Task<ActionResult<ApiResponse<List<CategoryDto>>>> GetCategories([FromQuery] string? lang = "tr")
    {
        var categories = await _unitOfWork.Categories.Query()
            .Include(c => c.Translations)
            .ToListAsync();

        var categoryDtos = categories.Select(c =>
        {
            var translation = c.Translations.FirstOrDefault(t => t.LanguageCode == lang);
            return new CategoryDto
            {
                Id = c.Id,
                Name = translation?.Name ?? c.Name,
                Icon = c.Icon,
                Color = c.Color,
                ImageUrl = c.ImageUrl,
                DisplayOrder = c.DisplayOrder
            };
        }).OrderBy(c => c.DisplayOrder).ThenBy(c => c.Name).ToList();

        return Ok(new ApiResponse<List<CategoryDto>>(categoryDtos, "Kategoriler başarıyla getirildi"));
    }

    /// <summary>
    /// Ürün arama için autocomplete endpoint'i
    /// </summary>
    /// <param name="query">Arama metni</param>
    /// <returns>Autocomplete sonuçları</returns>
    [HttpGet("autocomplete")]
    public async Task<ActionResult<ApiResponse<List<AutocompleteResultDto>>>> Autocomplete([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(new List<AutocompleteResultDto>(), "Sonuç bulunamadı"));
        }

        var results = await _unitOfWork.Products.Query()
            .Where(p => p.Name.Contains(query))
            .Take(10)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AutocompleteResultDto>>(results, "Autocomplete sonuçları getirildi"));
    }

    /// <summary>
    /// Popüler ürünleri getirir - Sipariş sayısına göre sıralanır
    /// </summary>
    /// <param name="limit">Getirilecek ürün sayısı - Varsayılan: 10</param>
    /// <returns>Popüler ürün listesi</returns>
    [HttpGet("popular")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetPopularProducts([FromQuery] int limit = 10)
    {
        // Get popular products based on order count
        var popularProducts = await _unitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Select(p => new
            {
                Product = p,
                OrderCount = _unitOfWork.OrderItems.Query().Count(oi => oi.ProductId == p.Id)
            })
            .OrderByDescending(x => x.OrderCount)
            .ThenByDescending(x => x.Product.CreatedAt)
            .Take(limit)
            .Select(x => new ProductDto
            {
                Id = x.Product.Id,
                VendorId = x.Product.VendorId,
                VendorName = x.Product.Vendor != null ? x.Product.Vendor.Name : null,
                Name = x.Product.Name,
                Description = x.Product.Description,
                Category = x.Product.Category,
                Price = x.Product.Price,
                ImageUrl = x.Product.ImageUrl
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<ProductDto>>(popularProducts, "Popüler ürünler başarıyla getirildi"));
    }

    /// <summary>
    /// ID'ye göre ürün detayını getirir
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <returns>Ürün detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> GetProduct(Guid id)
    {
        var product = await _unitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Id == id)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                VendorName = p.Vendor != null ? p.Vendor.Name : null,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            })
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound(new ApiResponse<ProductDto>("Ürün bulunamadı", "PRODUCT_NOT_FOUND"));
        }

        return Ok(new ApiResponse<ProductDto>(product, "Ürün başarıyla getirildi"));
    }
}

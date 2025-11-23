using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public ProductsController(TalabiDbContext context)
    {
        _context = context;
    }

    [HttpGet("search")]
    public async Task<ActionResult<PagedResultDto<ProductDto>>> Search([FromQuery] ProductSearchRequestDto request)
    {
        var query = _context.Products.AsQueryable();

        // Text search
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            query = query.Where(p => p.Name.Contains(request.Query) || 
                                    (p.Description != null && p.Description.Contains(request.Query)));
        }

        // Category filter
        if (!string.IsNullOrWhiteSpace(request.Category))
        {
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

        // Get total count before pagination
        var totalCount = await query.CountAsync();

        // Sorting
        query = request.SortBy?.ToLower() switch
        {
            "price_asc" => query.OrderBy(p => p.Price),
            "price_desc" => query.OrderByDescending(p => p.Price),
            "name" => query.OrderBy(p => p.Name),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            _ => query.OrderBy(p => p.Name)
        };

        // Pagination
        var items = await query
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                VendorName = p.Vendor != null ? p.Vendor.Name : null,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                ImageUrl = p.ImageUrl
            })
            .ToListAsync();

        return Ok(new PagedResultDto<ProductDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize)
        });
    }

    [HttpGet("categories")]
    public async Task<ActionResult<List<string>>> GetCategories()
    {
        var categories = await _context.Products
            .Where(p => p.Category != null)
            .Select(p => p.Category!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        return Ok(categories);
    }

    [HttpGet("autocomplete")]
    public async Task<ActionResult<List<AutocompleteResultDto>>> Autocomplete([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new List<AutocompleteResultDto>());
        }

        var results = await _context.Products
            .Where(p => p.Name.Contains(query))
            .Take(10)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        return Ok(results);
    }

    [HttpGet("popular")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetPopularProducts([FromQuery] int limit = 10)
    {
        // Get popular products based on order count
        var popularProducts = await _context.Products
            .Include(p => p.Vendor)
            .Select(p => new
            {
                Product = p,
                OrderCount = _context.OrderItems.Count(oi => oi.ProductId == p.Id)
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

        return Ok(popularProducts);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(int id)
    {
        var product = await _context.Products
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
                ImageUrl = p.ImageUrl
            })
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound("Product not found");
        }

        return Ok(product);
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/products")]
[ApiController]
[Authorize]
public class VendorProductsController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public VendorProductsController(TalabiDbContext context)
    {
        _context = context;
    }

    private string? GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

    private async Task<int?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    // GET: api/vendor/products
    [HttpGet]
    public async Task<ActionResult<IEnumerable<VendorProductDto>>> GetProducts(
        [FromQuery] string? category = null,
        [FromQuery] bool? isAvailable = null)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var query = _context.Products
            .Where(p => p.VendorId == vendorId.Value);

        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(p => p.Category == category);

        if (isAvailable.HasValue)
            query = query.Where(p => p.IsAvailable == isAvailable.Value);

        var products = await query
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new VendorProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                ImageUrl = p.ImageUrl,
                IsAvailable = p.IsAvailable,
                Stock = p.Stock,
                PreparationTime = p.PreparationTime,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .ToListAsync();

        return Ok(products);
    }

    // GET: api/vendor/products/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<VendorProductDto>> GetProduct(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = await _context.Products
            .Where(p => p.Id == id && p.VendorId == vendorId.Value)
            .Select(p => new VendorProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                ImageUrl = p.ImageUrl,
                IsAvailable = p.IsAvailable,
                Stock = p.Stock,
                PreparationTime = p.PreparationTime,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (product == null)
            return NotFound("Product not found or you don't have permission to access it");

        return Ok(product);
    }

    // POST: api/vendor/products
    [HttpPost]
    public async Task<ActionResult<VendorProductDto>> CreateProduct(CreateProductDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = new Product
        {
            VendorId = vendorId.Value,
            Name = dto.Name,
            Description = dto.Description,
            Category = dto.Category,
            CategoryId = dto.CategoryId,
            Price = dto.Price,
            ImageUrl = dto.ImageUrl,
            IsAvailable = dto.IsAvailable,
            Stock = dto.Stock,
            PreparationTime = dto.PreparationTime
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        var result = new VendorProductDto
        {
            Id = product.Id,
            VendorId = product.VendorId,
            Name = product.Name,
            Description = product.Description,
            Category = product.Category,
            Price = product.Price,
            ImageUrl = product.ImageUrl,
            IsAvailable = product.IsAvailable,
            Stock = product.Stock,
            PreparationTime = product.PreparationTime,
            CreatedAt = product.CreatedAt,
            UpdatedAt = product.UpdatedAt
        };

        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, result);
    }

    // PUT: api/vendor/products/{id}
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProduct(int id, UpdateProductDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
            return NotFound("Product not found or you don't have permission to update it");

        // Update only provided fields
        if (dto.Name != null)
            product.Name = dto.Name;
        if (dto.Description != null)
            product.Description = dto.Description;
        if (dto.Category != null)
            product.Category = dto.Category;
        if (dto.CategoryId.HasValue)
            product.CategoryId = dto.CategoryId.Value;
        if (dto.Price.HasValue)
            product.Price = dto.Price.Value;
        if (dto.ImageUrl != null)
            product.ImageUrl = dto.ImageUrl;
        if (dto.IsAvailable.HasValue)
            product.IsAvailable = dto.IsAvailable.Value;
        if (dto.Stock.HasValue)
            product.Stock = dto.Stock;
        if (dto.PreparationTime.HasValue)
            product.PreparationTime = dto.PreparationTime;

        product.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // DELETE: api/vendor/products/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
            return NotFound("Product not found or you don't have permission to delete it");

        _context.Products.Remove(product);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // PUT: api/vendor/products/{id}/availability
    [HttpPut("{id}/availability")]
    public async Task<IActionResult> UpdateProductAvailability(int id, UpdateProductAvailabilityDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
            return NotFound("Product not found or you don't have permission to update it");

        product.IsAvailable = dto.IsAvailable;
        product.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // PUT: api/vendor/products/{id}/price
    [HttpPut("{id}/price")]
    public async Task<IActionResult> UpdateProductPrice(int id, UpdateProductPriceDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var product = await _context.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
            return NotFound("Product not found or you don't have permission to update it");

        product.Price = dto.Price;
        product.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/vendor/products/categories
    [HttpGet("categories")]
    public async Task<ActionResult<IEnumerable<string>>> GetCategories()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var categories = await _context.Products
            .Where(p => p.VendorId == vendorId.Value && p.Category != null)
            .Select(p => p.Category!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        return Ok(categories);
    }
}

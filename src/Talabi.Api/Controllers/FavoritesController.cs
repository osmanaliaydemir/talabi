using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public FavoritesController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetFavorites()
    {
        var userId = GetUserId();

        var favorites = await _context.FavoriteProducts
            .Where(f => f.UserId == userId)
            .Include(f => f.Product)
            .Select(f => new ProductDto
            {
                Id = f.Product!.Id,
                VendorId = f.Product.VendorId,
                Name = f.Product.Name,
                Description = f.Product.Description,
                Price = f.Product.Price,
                Currency = f.Product.Currency,
                ImageUrl = f.Product.ImageUrl
            })
            .ToListAsync();

        return Ok(favorites);
    }

    [HttpPost("{productId}")]
    public async Task<ActionResult> AddToFavorites(Guid productId)
    {
        var userId = GetUserId();

        // Check if product exists
        var product = await _context.Products.FindAsync(productId);
        if (product == null)
        {
            return NotFound("Product not found");
        }

        // Check if already favorited
        var exists = await _context.FavoriteProducts
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        if (exists)
        {
            return BadRequest("Product already in favorites");
        }

        var favorite = new FavoriteProduct
        {
            UserId = userId,
            ProductId = productId
        };

        _context.FavoriteProducts.Add(favorite);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Added to favorites" });
    }

    [HttpDelete("{productId}")]
    public async Task<ActionResult> RemoveFromFavorites(Guid productId)
    {
        var userId = GetUserId();

        var favorite = await _context.FavoriteProducts
            .FirstOrDefaultAsync(f => f.UserId == userId && f.ProductId == productId);

        if (favorite == null)
        {
            return NotFound("Favorite not found");
        }

        _context.FavoriteProducts.Remove(favorite);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Removed from favorites" });
    }

    [HttpGet("check/{productId}")]
    public async Task<ActionResult<bool>> IsFavorite(Guid productId)
    {
        var userId = GetUserId();

        var isFavorite = await _context.FavoriteProducts
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        return Ok(new { IsFavorite = isFavorite });
    }
}

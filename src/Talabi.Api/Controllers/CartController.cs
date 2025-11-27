using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public CartController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<CartDto>> GetCart()
    {
        var userId = GetUserId();
        
        var cart = await _context.Carts
            .Include(c => c.CartItems)
            .ThenInclude(ci => ci.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null)
        {
            return Ok(new CartDto { UserId = userId, Items = new List<CartItemDto>() });
        }

        var cartDto = new CartDto
        {
            Id = cart.Id,
            UserId = cart.UserId,
            Items = cart.CartItems.Select(ci => new CartItemDto
            {
                Id = ci.Id,
                ProductId = ci.ProductId,
                ProductName = ci.Product?.Name ?? "",
                ProductPrice = ci.Product?.Price ?? 0,
                ProductImageUrl = ci.Product?.ImageUrl,
                Quantity = ci.Quantity
            }).ToList()
        };

        return Ok(cartDto);
    }

    [HttpPost("items")]
    public async Task<ActionResult> AddToCart(AddToCartDto dto)
    {
        var userId = GetUserId();

        // Kullanıcının adresi var mı kontrol et (Customer için)
        var hasAddress = await _context.UserAddresses.AnyAsync(a => a.UserId == userId);
        if (!hasAddress)
        {
            return BadRequest(new
            {
                Message = "Sepete ürün eklemek için önce bir adres eklemeniz gerekmektedir.",
                Code = "ADDRESS_REQUIRED",
                RequiresAddress = true
            });
        }

        // Get or create cart
        var cart = await _context.Carts
            .Include(c => c.CartItems)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null)
        {
            cart = new Core.Entities.Cart { UserId = userId };
            _context.Carts.Add(cart);
            await _context.SaveChangesAsync();
        }

        // Check if product exists
        var product = await _context.Products.FindAsync(dto.ProductId);
        if (product == null)
        {
            return NotFound("Product not found");
        }

        // Check if item already in cart
        var existingItem = cart.CartItems.FirstOrDefault(ci => ci.ProductId == dto.ProductId);
        if (existingItem != null)
        {
            existingItem.Quantity += dto.Quantity;
        }
        else
        {
            cart.CartItems.Add(new Core.Entities.CartItem
            {
                ProductId = dto.ProductId,
                Quantity = dto.Quantity
            });
        }

        await _context.SaveChangesAsync();
        return Ok(new { Message = "Item added to cart" });
    }

    [HttpPut("items/{itemId}")]
    public async Task<ActionResult> UpdateCartItem(int itemId, UpdateCartItemDto dto)
    {
        var userId = GetUserId();

        var cartItem = await _context.CartItems
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound("Cart item not found");
        }

        if (dto.Quantity <= 0)
        {
            _context.CartItems.Remove(cartItem);
        }
        else
        {
            cartItem.Quantity = dto.Quantity;
        }

        await _context.SaveChangesAsync();
        return Ok(new { Message = "Cart item updated" });
    }

    [HttpDelete("items/{itemId}")]
    public async Task<ActionResult> RemoveFromCart(int itemId)
    {
        var userId = GetUserId();

        var cartItem = await _context.CartItems
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound("Cart item not found");
        }

        _context.CartItems.Remove(cartItem);
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Item removed from cart" });
    }

    [HttpDelete]
    public async Task<ActionResult> ClearCart()
    {
        var userId = GetUserId();

        var cart = await _context.Carts
            .Include(c => c.CartItems)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart != null)
        {
            _context.CartItems.RemoveRange(cart.CartItems);
            await _context.SaveChangesAsync();
        }

        return Ok(new { Message = "Cart cleared" });
    }
}

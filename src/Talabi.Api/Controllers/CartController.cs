using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Sepet işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// CartController constructor
    /// </summary>
    public CartController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcının sepetini getirir
    /// </summary>
    /// <returns>Sepet bilgileri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<CartDto>>> GetCart()
    {
        var userId = GetUserId();

        var cart = await _unitOfWork.Carts.Query()
            .Include(c => c.CartItems)
            .ThenInclude(ci => ci.Product)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        CartDto cartDto;
        if (cart == null)
        {
            cartDto = new CartDto { UserId = userId, Items = new List<CartItemDto>() };
        }
        else
        {
            cartDto = new CartDto
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
        }

        return Ok(new ApiResponse<CartDto>(cartDto, "Sepet başarıyla getirildi"));
    }

    /// <summary>
    /// Sepete ürün ekler
    /// </summary>
    /// <param name="dto">Sepete eklenecek ürün bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("items")]
    public async Task<ActionResult<ApiResponse<object>>> AddToCart(AddToCartDto dto)
    {
        var maxRetries = 3;
        for (int i = 0; i < maxRetries; i++)
        {
            try
            {
                var userId = GetUserId();

                // Check if user has an address (Customer)
                var hasAddress = await _unitOfWork.UserAddresses.Query()
                    .AnyAsync(a => a.UserId == userId);
                if (!hasAddress)
                {
                    return BadRequest(new ApiResponse<object>(
                        "Sepete ürün eklemek için önce bir adres eklemeniz gerekmektedir.",
                        "ADDRESS_REQUIRED",
                        new List<string>())
                    {
                        Data = new { RequiresAddress = true }
                    });
                }

                // Verify product exists
                var product = await _unitOfWork.Products.GetByIdAsync(dto.ProductId);
                if (product == null)
                {
                    return NotFound(new ApiResponse<object>("Ürün bulunamadı", "PRODUCT_NOT_FOUND"));
                }

                // 1. Get or Create Cart
                var cart = await _unitOfWork.Carts.Query()
                    .FirstOrDefaultAsync(c => c.UserId == userId);
                if (cart == null)
                {
                    cart = new Core.Entities.Cart { UserId = userId };
                    await _unitOfWork.Carts.AddAsync(cart);
                    // Save immediately to establish the Cart
                    await _unitOfWork.SaveChangesAsync();
                }

                // 2. Manage CartItem directly
                var cartItem = await _unitOfWork.CartItems.Query()
                    .FirstOrDefaultAsync(ci => ci.CartId == cart.Id && ci.ProductId == dto.ProductId);

                if (cartItem != null)
                {
                    cartItem.Quantity += dto.Quantity;
                    _unitOfWork.CartItems.Update(cartItem);
                }
                else
                {
                    cartItem = new Core.Entities.CartItem
                    {
                        CartId = cart.Id,
                        ProductId = dto.ProductId,
                        Quantity = dto.Quantity
                    };
                    await _unitOfWork.CartItems.AddAsync(cartItem);
                }

                await _unitOfWork.SaveChangesAsync();
                return Ok(new ApiResponse<object>(new { }, "Ürün sepete eklendi"));
            }
            catch (DbUpdateConcurrencyException)
            {
                if (i == maxRetries - 1)
                {
                    // Rethrow to let ExceptionHandlingMiddleware log it and return 409
                    throw;
                }

                // Clear the change tracker to detach entities before retrying
                // Note: UnitOfWork doesn't expose ChangeTracker, so we'll need to handle this differently
                // For now, we'll just retry
                await Task.Delay(100);
            }
            catch (Exception ex)
            {
                // For other exceptions, we might want to log them too, but here we return BadRequest as before
                // Or we could throw if we want 500
                return BadRequest(new ApiResponse<object>(ex.Message, "ADD_TO_CART_FAILED"));
            }
        }

        return BadRequest(new ApiResponse<object>("Beklenmeyen hata", "UNEXPECTED_ERROR"));
    }

    /// <summary>
    /// Sepet öğesini günceller
    /// </summary>
    /// <param name="itemId">Sepet öğesi ID'si</param>
    /// <param name="dto">Güncellenecek miktar bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("items/{itemId}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateCartItem(Guid itemId, UpdateCartItemDto dto)
    {
        var userId = GetUserId();

        var cartItem = await _unitOfWork.CartItems.Query()
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound(new ApiResponse<object>("Sepet öğesi bulunamadı", "CART_ITEM_NOT_FOUND"));
        }

        if (dto.Quantity <= 0)
        {
            _unitOfWork.CartItems.Remove(cartItem);
        }
        else
        {
            cartItem.Quantity = dto.Quantity;
            _unitOfWork.CartItems.Update(cartItem);
        }

        // Mark cart as modified to trigger UpdatedAt
        if (cartItem.Cart != null)
        {
            _unitOfWork.Carts.Update(cartItem.Cart);
        }

        await _unitOfWork.SaveChangesAsync();
        return Ok(new ApiResponse<object>(new { }, "Sepet öğesi güncellendi"));
    }

    /// <summary>
    /// Sepetten ürün çıkarır
    /// </summary>
    /// <param name="itemId">Sepet öğesi ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("items/{itemId}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveFromCart(Guid itemId)
    {
        var userId = GetUserId();

        var cartItem = await _unitOfWork.CartItems.Query()
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound(new ApiResponse<object>("Sepet öğesi bulunamadı", "CART_ITEM_NOT_FOUND"));
        }

        _unitOfWork.CartItems.Remove(cartItem);

        // Mark cart as modified to trigger UpdatedAt
        if (cartItem.Cart != null)
        {
            _unitOfWork.Carts.Update(cartItem.Cart);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Ürün sepetten çıkarıldı"));
    }

    /// <summary>
    /// Sepeti temizler
    /// </summary>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete]
    public async Task<ActionResult<ApiResponse<object>>> ClearCart()
    {
        var userId = GetUserId();

        var cart = await _unitOfWork.Carts.Query()
            .Include(c => c.CartItems)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart != null)
        {
            foreach (var item in cart.CartItems)
            {
                _unitOfWork.CartItems.Remove(item);
            }

            // Mark cart as modified to trigger UpdatedAt
            _unitOfWork.Carts.Update(cart);

            await _unitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { }, "Sepet temizlendi"));
    }
}

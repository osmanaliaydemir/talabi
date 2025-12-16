using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Sepet işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController : BaseController
{
    private readonly IMapper _mapper;
    private const string ResourceName = "CartResources";

    /// <summary>
    /// CartController constructor
    /// </summary>
    public CartController(
        IUnitOfWork unitOfWork,
        ILogger<CartController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _mapper = mapper;
    }

    /// <summary>
    /// Kullanıcının sepetini getirir
    /// </summary>
    /// <returns>Sepet bilgileri</returns>
    /// <summary>
    /// Kullanıcının sepetini getirir
    /// </summary>
    /// <returns>Sepet bilgileri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<CartDto>>> GetCart()
    {


        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<CartDto>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cart = await UnitOfWork.Carts.Query()
            .Include(c => c.CartItems)
            .ThenInclude(ci => ci.Product)
            .ThenInclude(p => p!.Vendor)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        CartDto cartDto;
        if (cart == null)
        {
            cartDto = new CartDto { UserId = userId, Items = new List<CartItemDto>() };
        }
        else
        {
            cartDto = _mapper.Map<CartDto>(cart);
        }

        return Ok(new ApiResponse<CartDto>(cartDto, LocalizationService.GetLocalizedString(ResourceName, "CartRetrievedSuccessfully", CurrentCulture)));
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
                var userId = UserContext.GetUserId();
                if (string.IsNullOrWhiteSpace(userId))
                {
                    return Unauthorized(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                        "UNAUTHORIZED"));
                }

                // Check if user has an address (Customer)
                var hasAddress = await UnitOfWork.UserAddresses.Query()
                    .AnyAsync(a => a.UserId == userId);
                if (!hasAddress)
                {
                    return BadRequest(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "AddressRequiredToAddItem", CurrentCulture),
                        "ADDRESS_REQUIRED",
                        new List<string>())
                    {
                        Data = new { RequiresAddress = true }
                    });
                }

                // Verify product exists
                var product = await UnitOfWork.Products.GetByIdAsync(dto.ProductId);
                if (product == null)
                {
                    return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture), "PRODUCT_NOT_FOUND"));
                }

                // 1. Get or Create Cart
                var cart = await UnitOfWork.Carts.Query()
                    .FirstOrDefaultAsync(c => c.UserId == userId);
                if (cart == null)
                {
                    cart = new Core.Entities.Cart { UserId = userId };
                    await UnitOfWork.Carts.AddAsync(cart);
                    // Save immediately to establish the Cart
                    await UnitOfWork.SaveChangesAsync();
                }

                // 2. Manage CartItem directly
                var cartItem = await UnitOfWork.CartItems.Query()
                    .FirstOrDefaultAsync(ci => ci.CartId == cart.Id && ci.ProductId == dto.ProductId);

                if (cartItem != null)
                {
                    cartItem.Quantity += dto.Quantity;
                    UnitOfWork.CartItems.Update(cartItem);
                }
                else
                {
                    cartItem = new Core.Entities.CartItem
                    {
                        CartId = cart.Id,
                        ProductId = dto.ProductId,
                        Quantity = dto.Quantity
                    };
                    await UnitOfWork.CartItems.AddAsync(cartItem);
                }

                await UnitOfWork.SaveChangesAsync();
                return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "ItemAddedToCartSuccessfully", CurrentCulture)));
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

        return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "UnexpectedError", CurrentCulture), "UNEXPECTED_ERROR"));
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


        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cartItem = await UnitOfWork.CartItems.Query()
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CartItemNotFound", CurrentCulture), "CART_ITEM_NOT_FOUND"));
        }

        if (dto.Quantity <= 0)
        {
            UnitOfWork.CartItems.Remove(cartItem);
        }
        else
        {
            cartItem.Quantity = dto.Quantity;
            UnitOfWork.CartItems.Update(cartItem);
        }

        // Mark cart as modified to trigger UpdatedAt
        if (cartItem.Cart != null)
        {
            UnitOfWork.Carts.Update(cartItem.Cart);
        }

        await UnitOfWork.SaveChangesAsync();
        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CartItemUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sepetten ürün çıkarır
    /// </summary>
    /// <param name="itemId">Sepet öğesi ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("items/{itemId}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveFromCart(Guid itemId)
    {


        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cartItem = await UnitOfWork.CartItems.Query()
            .Include(ci => ci.Cart)
            .FirstOrDefaultAsync(ci => ci.Id == itemId && ci.Cart!.UserId == userId);

        if (cartItem == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CartItemNotFound", CurrentCulture), "CART_ITEM_NOT_FOUND"));
        }

        UnitOfWork.CartItems.Remove(cartItem);

        // Mark cart as modified to trigger UpdatedAt
        if (cartItem.Cart != null)
        {
            UnitOfWork.Carts.Update(cartItem.Cart);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "ItemRemovedFromCartSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sepeti temizler
    /// </summary>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Sepeti temizler
    /// </summary>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete]
    public async Task<ActionResult<ApiResponse<object>>> ClearCart()
    {


        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cart = await UnitOfWork.Carts.Query()
            .Include(c => c.CartItems)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart != null)
        {
            foreach (var item in cart.CartItems)
            {
                UnitOfWork.CartItems.Remove(item);
            }

            // Mark cart as modified to trigger UpdatedAt
            UnitOfWork.Carts.Update(cart);

            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CartClearedSuccessfully", CurrentCulture)));
    }
}

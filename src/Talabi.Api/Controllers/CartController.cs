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
            .Include(c => c.Coupon)
            .Include(c => c.Campaign)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        CartDto cartDto;
        if (cart == null)
        {
            cartDto = new CartDto { UserId = userId, Items = new List<CartItemDto>() };
        }
        else
        {
            cartDto = _mapper.Map<CartDto>(cart);
            // Manual mapping for new properties if Mapper Profile not updated
            // Assuming Mapper handles basic mapping, but we extended CartDto
            // Safer to double check or set manually
            cartDto.CouponId = cart.CouponId;
            cartDto.CampaignId = cart.CampaignId;
            cartDto.CouponCode = cart.Coupon?.Code;
            cartDto.CampaignTitle = cart.Campaign?.Title;
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
    /// Sepetin promosyon (kampanya/kupon) bilgilerini günceller
    /// </summary>
    [HttpPut("promotions")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateCartPromotions(UpdateCartPromotionsDto dto)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cart = await UnitOfWork.Carts.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null)
        {
            cart = new Core.Entities.Cart { UserId = userId };
            await UnitOfWork.Carts.AddAsync(cart);
        }

        // Logic:
        // 1. Coupon
        if (!string.IsNullOrEmpty(dto.CouponCode))
        {
            var coupon = await UnitOfWork.Coupons.Query()
                .FirstOrDefaultAsync(c => c.Code == dto.CouponCode && c.IsActive);
            
            if (coupon != null)
            {
                cart.CouponId = coupon.Id;
            }
            else
            {
                 // Invalid coupon? Clear it or ignore? 
                 // If sending a coupon code that doesn't exist, maybe clear?
                 // But safest is to only set if valid. If empty string sent, we clear.
            }
        }
        else
        {
            // If explicitly sent as null/empty, clear it
            // Assuming the client sends "null" or "" to remove.
            // But checking dto property presence is hard in C#, so we assume the DTO sends valid state.
            // Actually, if we want to support clearing, we should treat empty string as clear.
            // But if DTO property is nullable, null might mean "don't change".
            // Let's assume the mobile app sends the *current desired state*.
            // So if CouponCode is null, it means no coupon.
            cart.CouponId = null;
        }

        // However, standard PATCH logic says null = no change.
        // But here we are doing PUT (UpdateCartPromotions).
        // Let's refine:
        // If CouponCode is provided (non-null), look it up.
        // If it is empty string "", clear it.
        // If null, clear it? Or ignore?
        // Mobile Implementation:
        // - Select Coupon -> Sends Code
        // - Remove Coupon -> Sends null
        // So null should clear.

        if (!string.IsNullOrEmpty(dto.CouponCode))
        {
             var coupon = await UnitOfWork.Coupons.Query()
                .FirstOrDefaultAsync(c => c.Code == dto.CouponCode);
             if (coupon != null) cart.CouponId = coupon.Id;
             else cart.CouponId = null; // Invalid code -> clear
        }
        else
        {
            cart.CouponId = null;
        }


        // 2. Campaign
        if (dto.CampaignId.HasValue)
        {
            var campaign = await UnitOfWork.Campaigns.GetByIdAsync(dto.CampaignId.Value);
            if (campaign != null && campaign.IsActive)
            {
                cart.CampaignId = campaign.Id;
            }
            else
            {
                cart.CampaignId = null;
            }
        }
        else
        {
            cart.CampaignId = null;
        }

        UnitOfWork.Carts.Update(cart);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CartUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sepetteki tüm promosyonları (kampanya ve kupon) temizler
    /// </summary>
    [HttpDelete("promotions")]
    public async Task<ActionResult<ApiResponse<object>>> ClearPromotions()
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var cart = await UnitOfWork.Carts.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (cart == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CartNotFound", CurrentCulture),
                "CART_NOT_FOUND"));
        }

        // Clear promotions
        cart.CampaignId = null;
        cart.CouponId = null;

        UnitOfWork.Carts.Update(cart);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "PromotionsCleared", CurrentCulture)));
    }

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

            // Clear promotions too
            cart.CouponId = null;
            cart.CampaignId = null;

            // Mark cart as modified to trigger UpdatedAt
            UnitOfWork.Carts.Update(cart);

            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CartClearedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcıya ürün önerileri getirir. 
    /// Kullanıcının geçmiş siparişleri varsa oradan, yoksa konuma en yakın restoran/marketten önerir.
    /// </summary>
    [HttpGet("recommendations")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetRecommendations([FromQuery] VendorType? type, [FromQuery] double? lat, [FromQuery] double? lon)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<List<ProductDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        // 1. Önce kullanıcının eski siparişlerinden öneriler bulmaya çalış (aynı tipte)
        var previousProducts = await UnitOfWork.OrderItems.Query()
            .Include(oi => oi.Order)
            .Include(oi => oi.Product)
                .ThenInclude(p => p.Vendor)
            .Where(oi => oi.Order.UserId == userId)
            .Where(oi => type == null || (oi.Product.VendorType == type || (oi.Product.Vendor != null && oi.Product.Vendor.Type == type)))
            .OrderByDescending(oi => oi.Order.CreatedAt)
            .Select(oi => oi.Product)
            .Where(p => p != null)
            .Distinct()
            .Take(10)
            .ToListAsync();

        if (previousProducts.Any())
        {
            var dtos = _mapper.Map<List<ProductDto>>(previousProducts);
            return Ok(new ApiResponse<List<ProductDto>>(dtos, LocalizationService.GetLocalizedString(ResourceName, "Success", CurrentCulture)));
        }

        // 2. Eğer eski siparişi yoksa konuma en yakın restoran/marketin ürünlerini öner
        double? targetLat = lat;
        double? targetLon = lon;

        if (targetLat == null || targetLon == null)
        {
            var defaultAddress = await UnitOfWork.UserAddresses.Query()
                .FirstOrDefaultAsync(a => a.UserId == userId && a.IsDefault);
            if (defaultAddress != null)
            {
                targetLat = defaultAddress.Latitude;
                targetLon = defaultAddress.Longitude;
            }
        }

        // En yakın vendor'u bul
        var vendorsQuery = UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive);
        
        if (type.HasValue)
        {
            vendorsQuery = vendorsQuery.Where(v => v.Type == type.Value);
        }

        Vendor? nearestVendor = null;
        if (targetLat.HasValue && targetLon.HasValue)
        {
             // Basit mesafe sıralaması (API seviyesinde tam formül yerine yaklaşık)
             nearestVendor = await vendorsQuery
                .OrderBy(v => (v.Latitude - targetLat.Value) * (v.Latitude - targetLat.Value) + (v.Longitude - targetLon.Value) * (v.Longitude - targetLon.Value))
                .FirstOrDefaultAsync();
        }
        else
        {
            nearestVendor = await vendorsQuery
                .OrderByDescending(v => v.Rating)
                .FirstOrDefaultAsync();
        }

        if (nearestVendor != null)
        {
            var recommendedProducts = await UnitOfWork.Products.Query()
                .Include(p => p.Vendor)
                .Where(p => p.VendorId == nearestVendor.Id && p.IsAvailable)
                .Take(10)
                .ToListAsync();

            var dtos = _mapper.Map<List<ProductDto>>(recommendedProducts);
            return Ok(new ApiResponse<List<ProductDto>>(dtos, LocalizationService.GetLocalizedString(ResourceName, "Success", CurrentCulture)));
        }

        return Ok(new ApiResponse<List<ProductDto>>(new List<ProductDto>(), LocalizationService.GetLocalizedString(ResourceName, "Success", CurrentCulture)));
    }
}

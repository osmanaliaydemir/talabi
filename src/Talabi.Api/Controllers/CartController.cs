using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Core.Helpers;
using AutoMapper;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using System.Text.Json;

namespace Talabi.Api.Controllers;

/// <summary>
/// Sepet işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController(
    IUnitOfWork unitOfWork,
    ILogger<CartController> logger,
    ILocalizationService localizationService,
    IUserContextService userContext,
    IMapper mapper,
    ICampaignCalculator campaignCalculator)
    : BaseController(unitOfWork, logger, localizationService, userContext)
{
    private readonly IMapper _mapper = mapper;
    private readonly ICampaignCalculator _campaignCalculator = campaignCalculator;
    private const string ResourceName = "CartResources";

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
            .ThenInclude(cmp => cmp!.CampaignProducts) // Load related products
            .Include(c => c.Campaign)
            .ThenInclude(cmp => cmp!.CampaignCategories) // Load related categories
            .FirstOrDefaultAsync(c => c.UserId == userId);

        // Kullanıcının default adresini al (konum kontrolü için)
        var defaultAddress = await UnitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.UserId == userId && a.IsDefault);

        CartDto cartDto;
        if (cart == null)
        {
            cartDto = new CartDto { UserId = userId, Items = [] };
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
            cartDto.CouponCode = cart.Coupon?.Code;
            cartDto.CampaignTitle = cart.Campaign?.Title;

            // Konum kuralı: Vendor'ın delivery radius içindeki item'ları filtrele
            var validItems = new List<CartItemDto>();
            var itemsToRemove = new List<Guid>(); // Sepetten kaldırılacak item'lar

            foreach (var item in cartDto.Items)
            {
                var cartItemEntity = cart.CartItems.FirstOrDefault(ci => ci.Id == item.Id);
                if (cartItemEntity?.Product?.Vendor == null)
                {
                    // Vendor bilgisi yoksa item'ı kaldır
                    itemsToRemove.Add(item.Id);
                    continue;
                }

                var vendor = cartItemEntity.Product.Vendor;

                // Konum kontrolü: Kullanıcı adresi ve vendor konumu varsa kontrol et
                if (defaultAddress?.Latitude.HasValue == true &&
                    defaultAddress.Longitude.HasValue == true &&
                    vendor.Latitude.HasValue &&
                    vendor.Longitude.HasValue)
                {
                    var userLat = defaultAddress.Latitude.Value;
                    var userLon = defaultAddress.Longitude.Value;
                    var vendorLat = vendor.Latitude.Value;
                    var vendorLon = vendor.Longitude.Value;

                    // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
                    var deliveryRadius = vendor.DeliveryRadiusInKm == 0 ? 5 : vendor.DeliveryRadiusInKm;
                    var distance = GeoHelper.CalculateDistance(userLat, userLon, vendorLat, vendorLon);

                    if (distance > deliveryRadius)
                    {
                        // Vendor'ın delivery radius dışında - item'ı sepetten kaldır
                        itemsToRemove.Add(item.Id);
                        continue;
                    }
                }
                else if (defaultAddress?.Latitude.HasValue == true &&
                         defaultAddress.Longitude.HasValue == true)
                {
                    // Kullanıcı konumu var ama vendor konumu yok - item'ı kaldır
                    itemsToRemove.Add(item.Id);
                    continue;
                }
                // Eğer kullanıcı konumu yoksa, tüm item'ları göster (geriye dönük uyumluluk)

                // Rating ve ReviewCount'u ekle
                item.ReviewCount = UnitOfWork.Reviews.Query().Count(r => r.ProductId == item.ProductId && r.IsApproved);
                item.Rating = UnitOfWork.Reviews.Query().Where(r => r.ProductId == item.ProductId && r.IsApproved)
                    .Select(r => (double?)r.Rating).Average();

                // Deserialize options
                if (!string.IsNullOrEmpty(cartItemEntity.SelectedOptions))
                {
                    try
                    {
                        item.SelectedOptions =
                            JsonSerializer.Deserialize<List<CartItemOptionDto>>(cartItemEntity.SelectedOptions);
                    }
                    catch
                    {
                        // Ignore deserialization errors
                    }
                }

                validItems.Add(item);
            }

            // Sepetten kaldırılacak item'ları database'den sil
            if (itemsToRemove.Any())
            {
                var cartItemsToRemove = cart.CartItems.Where(ci => itemsToRemove.Contains(ci.Id)).ToList();
                foreach (var cartItemToRemove in cartItemsToRemove)
                {
                    UnitOfWork.CartItems.Remove(cartItemToRemove);
                }
                await UnitOfWork.SaveChangesAsync();
            }

            // CartDto'yu güncelle - sadece geçerli item'ları tut
            cartDto.Items = validItems;

            // Calculate Campaign Discount
            if (cart.Campaign != null)
            {
                var calculationResult = await _campaignCalculator.CalculateAsync(cart, cart.Campaign, userId);
                if (calculationResult.IsValid)
                {
                    cartDto.CampaignDiscountAmount = calculationResult.DiscountAmount;
                    cartDto.DiscountedItemIds = calculationResult.ApplicableItemIds;
                }
                else
                {
                    // Campaign is invalid (expired, limit reached, etc.)
                    // We might want to clear it or notify user.
                    // For now, let's just not apply discount.
                    cartDto.CampaignId = null;
                    cartDto.CampaignTitle = null;
                }
            }
        }

        return Ok(new ApiResponse<CartDto>(cartDto,
            LocalizationService.GetLocalizedString(ResourceName, "CartRetrievedSuccessfully", CurrentCulture)));
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
                        LocalizationService.GetLocalizedString(ResourceName, "AddressRequiredToAddItem",
                            CurrentCulture),
                        "ADDRESS_REQUIRED",
                        new List<string>())
                    {
                        Data = new { RequiresAddress = true }
                    });
                }

                // Verify product exists
                var product = await UnitOfWork.Products.Query()
                    .Include(p => p.Vendor)
                    .FirstOrDefaultAsync(p => p.Id == dto.ProductId);
                
                if (product == null)
                {
                    return NotFound(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                        "PRODUCT_NOT_FOUND"));
                }

                // Konum kuralı: Vendor'ın delivery radius kontrolü
                var defaultAddress = await UnitOfWork.UserAddresses.Query()
                    .FirstOrDefaultAsync(a => a.UserId == userId && a.IsDefault);

                if (defaultAddress?.Latitude.HasValue == true &&
                    defaultAddress.Longitude.HasValue == true &&
                    product.Vendor != null &&
                    product.Vendor.Latitude.HasValue &&
                    product.Vendor.Longitude.HasValue)
                {
                    var userLat = defaultAddress.Latitude.Value;
                    var userLon = defaultAddress.Longitude.Value;
                    var vendorLat = product.Vendor.Latitude.Value;
                    var vendorLon = product.Vendor.Longitude.Value;

                    // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
                    var deliveryRadius = product.Vendor.DeliveryRadiusInKm == 0 ? 5 : product.Vendor.DeliveryRadiusInKm;
                    var distance = GeoHelper.CalculateDistance(userLat, userLon, vendorLat, vendorLon);

                    if (distance > deliveryRadius)
                    {
                        // Vendor'ın delivery radius dışında - ürün eklenemez
                        return BadRequest(new ApiResponse<object>(
                            LocalizationService.GetLocalizedString(ResourceName, "ProductOutOfDeliveryRadius",
                                CurrentCulture) ?? $"Bu ürün teslimat yarıçapınız ({deliveryRadius} km) dışında. Mesafe: {distance:F2} km",
                            "PRODUCT_OUT_OF_DELIVERY_RADIUS"));
                    }
                }
                else if (defaultAddress?.Latitude.HasValue == true &&
                         defaultAddress.Longitude.HasValue == true)
                {
                    // Kullanıcı konumu var ama vendor konumu yok - ürün eklenemez
                    return BadRequest(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "VendorLocationNotAvailable",
                            CurrentCulture) ?? "Satıcı konum bilgisi mevcut değil",
                        "VENDOR_LOCATION_NOT_AVAILABLE"));
                }
                // Eğer kullanıcı konumu yoksa, ürün eklenebilir (geriye dönük uyumluluk)

                // 1. Get or Create Cart
                var cart = await UnitOfWork.Carts.Query()
                    .FirstOrDefaultAsync(c => c.UserId == userId);
                if (cart == null)
                {
                    cart = new Cart { UserId = userId };
                    await UnitOfWork.Carts.AddAsync(cart);
                    // Save immediately to establish the Cart
                    await UnitOfWork.SaveChangesAsync();
                }

                // 2. Manage CartItem directly
                // Logic to find existing item must match SelectedOptions hash/string.
                string? optionsJson = null;
                if (dto.SelectedOptions != null && dto.SelectedOptions.Any())
                {
                    // Sort to ensure consistency
                    var sortedOptions = dto.SelectedOptions.OrderBy(o => o.OptionGroupId).ToList();
                    optionsJson = JsonSerializer.Serialize(sortedOptions);
                }

                var existingItems = await UnitOfWork.CartItems.Query()
                    .Where(ci => ci.CartId == cart.Id && ci.ProductId == dto.ProductId)
                    .ToListAsync();

                var cartItem = existingItems.FirstOrDefault(ci => ci.SelectedOptions == optionsJson);

                if (cartItem != null)
                {
                    cartItem.Quantity += dto.Quantity;
                    UnitOfWork.CartItems.Update(cartItem);
                }
                else
                {
                    cartItem = new CartItem
                    {
                        CartId = cart.Id,
                        ProductId = dto.ProductId,
                        Quantity = dto.Quantity,
                        SelectedOptions = optionsJson
                    };
                    await UnitOfWork.CartItems.AddAsync(cartItem);
                }

                await UnitOfWork.SaveChangesAsync();
                return Ok(new ApiResponse<object>(new { },
                    LocalizationService.GetLocalizedString(ResourceName, "ItemAddedToCartSuccessfully",
                        CurrentCulture)));
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

        return BadRequest(new ApiResponse<object>(
            LocalizationService.GetLocalizedString(ResourceName, "UnexpectedError", CurrentCulture),
            "UNEXPECTED_ERROR"));
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
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CartItemNotFound", CurrentCulture),
                "CART_ITEM_NOT_FOUND"));
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
        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "CartItemUpdatedSuccessfully", CurrentCulture)));
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
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CartItemNotFound", CurrentCulture),
                "CART_ITEM_NOT_FOUND"));
        }

        UnitOfWork.CartItems.Remove(cartItem);

        // Mark cart as modified to trigger UpdatedAt
        if (cartItem.Cart != null)
        {
            UnitOfWork.Carts.Update(cartItem.Cart);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "ItemRemovedFromCartSuccessfully", CurrentCulture)));
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
            cart = new Cart { UserId = userId };
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

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "CartUpdatedSuccessfully", CurrentCulture)));
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

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "CartClearedSuccessfully", CurrentCulture)));
    }

    [HttpGet("recommendations")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetRecommendations([FromQuery] VendorType? type,
        [FromQuery] double? lat, [FromQuery] double? lon)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<List<ProductDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        // Kullanıcının default adresini al (konum kontrolü için)
        var defaultAddress = await UnitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.UserId == userId && a.IsDefault);

        // Konum bilgisini belirle (query parametreleri veya default adres)
        double? targetLat = lat;
        double? targetLon = lon;

        if (targetLat == null || targetLon == null)
        {
            if (defaultAddress != null)
            {
                targetLat = defaultAddress.Latitude;
                targetLon = defaultAddress.Longitude;
            }
        }

        var results = new List<Product>();
        string messageKey = "RecommendedForYou";

        // 1. Önce kullanıcının eski siparişlerinden öneriler bulmaya çalış (aynı tipte)
        var previousProducts = await UnitOfWork.OrderItems.Query()
            .Include(oi => oi.Order)
            .Include(oi => oi.Product)
            .ThenInclude(p => p!.Vendor) // Product can be null in oi
            .Where(oi => oi.Order != null && oi.Order.CustomerId == userId)
            .Where(oi => oi.Product != null && (type == null || (oi.Product.VendorType == type ||
                                                                 (oi.Product.Vendor != null &&
                                                                  oi.Product.Vendor.Type == type))))
            .OrderByDescending(oi => oi.Order != null ? oi.Order.CreatedAt : DateTime.MinValue)
            .Select(oi => oi.Product)
            .Where(p => p != null && p!.IsAvailable)
            .Distinct()
            .Take(10)
            .ToListAsync();

        if (previousProducts.Any())
        {
            // Konum kuralı: Vendor'ın delivery radius kontrolü
            var validProducts = new List<Product>();
            foreach (var product in previousProducts.OfType<Product>())
            {
                if (product.Vendor == null)
                {
                    continue;
                }

                var vendor = product.Vendor;

                // Konum kontrolü: Kullanıcı adresi ve vendor konumu varsa kontrol et
                if (targetLat.HasValue && targetLon.HasValue &&
                    vendor.Latitude.HasValue && vendor.Longitude.HasValue)
                {
                    var userLat = targetLat.Value;
                    var userLon = targetLon.Value;
                    var vendorLat = vendor.Latitude.Value;
                    var vendorLon = vendor.Longitude.Value;

                    // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
                    var deliveryRadius = vendor.DeliveryRadiusInKm == 0 ? 5 : vendor.DeliveryRadiusInKm;
                    var distance = GeoHelper.CalculateDistance(userLat, userLon, vendorLat, vendorLon);

                    if (distance <= deliveryRadius)
                    {
                        validProducts.Add(product);
                    }
                }
                else if (!targetLat.HasValue || !targetLon.HasValue)
                {
                    // Kullanıcı konumu yoksa, tüm ürünleri göster (geriye dönük uyumluluk)
                    validProducts.Add(product);
                }
                // Kullanıcı konumu var ama vendor konumu yok - ürünü gösterme
            }

            if (validProducts.Any())
            {
                results.AddRange(validProducts);
                messageKey = "RecommendedForYou";
            }
        }

        // 2. Eğer önceki siparişlerden ürün bulunamadıysa, konuma en yakın restoran/marketin ürünlerini getir
        if (!results.Any())
        {
            if (!targetLat.HasValue || !targetLon.HasValue)
            {
                // Kullanıcı konumu yoksa boş liste döndür
                return Ok(new ApiResponse<List<ProductDto>>(new List<ProductDto>(),
                    LocalizationService.GetLocalizedString(ResourceName, messageKey, CurrentCulture)));
            }

            // Tüm aktif vendor'ları al (konum kontrolü için memory'de filtreleme yapacağız)
            var allVendors = await UnitOfWork.Vendors.Query()
                .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue)
                .ToListAsync();

            if (type.HasValue)
            {
                allVendors = allVendors.Where(v => v.Type == type.Value).ToList();
            }

            // Konum kuralı: Delivery radius içindeki vendor'ları filtrele
            // targetLat ve targetLon zaten null kontrolü yapıldı (yukarıda), burada kesinlikle değer var
            var userLat = targetLat.Value;
            var userLon = targetLon.Value;

            var vendorsInRadius = allVendors
                .Where(v => GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <=
                           (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
                .ToList();

            if (!vendorsInRadius.Any())
            {
                // Delivery radius içinde vendor yoksa boş liste döndür
                return Ok(new ApiResponse<List<ProductDto>>(new List<ProductDto>(),
                    LocalizationService.GetLocalizedString(ResourceName, messageKey, CurrentCulture)));
            }

            // En yakın vendor'u bul (delivery radius içindeki vendor'lar arasından)
            var nearestVendor = vendorsInRadius
                .OrderBy(v => GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value))
                .FirstOrDefault();

            if (nearestVendor != null)
            {
                results = await UnitOfWork.Products.Query()
                    .Include(p => p.Vendor)
                    .Where(p => p.VendorId == nearestVendor.Id && p.IsAvailable)
                    .Take(10)
                    .ToListAsync();

                messageKey = "NearestDeliciousness";
            }
        }

        var dtos = _mapper.Map<List<ProductDto>>(results);
        return Ok(new ApiResponse<List<ProductDto>>(dtos,
            LocalizationService.GetLocalizedString(ResourceName, messageKey, CurrentCulture)));
    }
}

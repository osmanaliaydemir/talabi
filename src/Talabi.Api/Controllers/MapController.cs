using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Talabi.Core.DTOs;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Harita işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class MapController : BaseController
{
    private readonly IMapper _mapper;
    private readonly IConfiguration _configuration;
    private const string ResourceName = "MapResources";

    /// <summary>
    /// MapController constructor
    /// </summary>
    public MapController(IUnitOfWork unitOfWork, ILogger<MapController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext, IMapper mapper, IConfiguration configuration) : base(unitOfWork, logger,
        localizationService, userContext)
    {
        _mapper = mapper;
        _configuration = configuration;
    }

    /// <summary>
    /// Harita görüntüleme için konum bilgisi olan tüm satıcıları getirir
    /// </summary>
    /// <param name="userLatitude">Kullanıcı enlemi (opsiyonel)</param>
    /// <param name="userLongitude">Kullanıcı boylamı (opsiyonel)</param>
    /// <returns>Satıcı harita bilgileri listesi</returns>
    [HttpGet("vendors")]
    public async Task<ActionResult<ApiResponse<List<VendorMapDto>>>> GetVendorsForMap([FromQuery] double? userLatitude,
        [FromQuery] double? userLongitude)
    {
        var query = UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue);

        // Distance filter (REQUIRED: user location must be provided)
        if (!userLatitude.HasValue || !userLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
            return Ok(new ApiResponse<List<VendorMapDto>>(new List<VendorMapDto>(),
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForMapVendors", CurrentCulture)));
        }

        var userLat = userLatitude.Value;
        var userLon = userLongitude.Value;

        // Filter: Is the user within the vendor's delivery radius?
        // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
        // Entity Framework, GeoHelper.CalculateDistance'i SQL'e çeviremediği için
        // önce memory'ye alıp sonra filtreliyoruz
        var allVendors = await query.ToListAsync();

        // Memory'de mesafe hesaplayarak filtrele
        var vendors = allVendors
            .Where(v => GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value,
                v.Longitude!.Value) <= (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
            .ToList();

        var vendorMapDtos = vendors.Select(v =>
        {
            var dto = _mapper.Map<VendorMapDto>(v);
            // Calculate distance if user location provided
            if (userLatitude.HasValue && userLongitude.HasValue && v.Latitude.HasValue && v.Longitude.HasValue)
            {
                dto.DistanceInKm = GeoHelper.CalculateDistance(
                    userLatitude.Value,
                    userLongitude.Value,
                    v.Latitude.Value,
                    v.Longitude.Value
                );
            }

            return dto;
        }).ToList();

        // Sort by distance if user location provided
        if (userLatitude.HasValue && userLongitude.HasValue)
        {
            vendorMapDtos = vendorMapDtos.OrderBy(v => v.DistanceInKm).ToList();
        }

        return Ok(new ApiResponse<List<VendorMapDto>>(vendorMapDtos,
            LocalizationService.GetLocalizedString(ResourceName, "VendorMapInfoRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Teslimat takip bilgilerini getirir
    /// </summary>
    /// <param name="orderId">Sipariş ID'si</param>
    /// <returns>Teslimat takip bilgileri</returns>
    [HttpGet("delivery-tracking/{orderId}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<DeliveryTrackingDto>>> GetDeliveryTracking(Guid orderId)
    {
        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.DeliveryAddress)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            return NotFound(new ApiResponse<DeliveryTrackingDto>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        var userId = UserContext.GetUserId();
        if (order.CustomerId != userId)
        {
            return StatusCode(403, new ApiResponse<DeliveryTrackingDto>(
                LocalizationService.GetLocalizedString(ResourceName, "NotAuthorizedForOrder", CurrentCulture),
                "FORBIDDEN"
            ));
        }

        if (order.DeliveryAddress == null ||
            !order.DeliveryAddress.Latitude.HasValue ||
            !order.DeliveryAddress.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<DeliveryTrackingDto>(
                LocalizationService.GetLocalizedString(ResourceName, "DeliveryAddressLocationNotAvailable",
                    CurrentCulture),
                "DELIVERY_ADDRESS_LOCATION_NOT_AVAILABLE"
            ));
        }

        if (order.Vendor == null ||
            !order.Vendor.Latitude.HasValue ||
            !order.Vendor.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<DeliveryTrackingDto>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorLocationNotAvailable", CurrentCulture),
                "VENDOR_LOCATION_NOT_AVAILABLE"
            ));
        }

        var tracking = new DeliveryTrackingDto
        {
            OrderId = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            OrderStatus = order.Status.ToString(),
            EstimatedDeliveryTime = order.EstimatedDeliveryTime,
            VendorLatitude = order.Vendor.Latitude.Value,
            VendorLongitude = order.Vendor.Longitude.Value,
            VendorAddress = order.Vendor.Address,
            DeliveryLatitude = order.DeliveryAddress.Latitude.Value,
            DeliveryLongitude = order.DeliveryAddress.Longitude.Value,
            DeliveryAddress = order.DeliveryAddress.FullAddress
        };

        // Get active courier from OrderCouriers
        var activeOrderCourier = await UnitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Courier)
            .FirstOrDefaultAsync(oc => oc.OrderId == order.Id && oc.IsActive);

        if (activeOrderCourier?.Courier != null &&
            activeOrderCourier.Courier.CurrentLatitude.HasValue &&
            activeOrderCourier.Courier.CurrentLongitude.HasValue)
        {
            tracking.CourierId = activeOrderCourier.Courier.Id;
            tracking.CourierName = activeOrderCourier.Courier.Name;
            tracking.CourierLatitude = activeOrderCourier.Courier.CurrentLatitude.Value;
            tracking.CourierLongitude = activeOrderCourier.Courier.CurrentLongitude.Value;
            tracking.CourierLastUpdate = activeOrderCourier.Courier.LastLocationUpdate;
        }

        return Ok(new ApiResponse<DeliveryTrackingDto>(tracking,
            LocalizationService.GetLocalizedString(ResourceName, "DeliveryTrackingRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Google Maps API anahtarını getirir (frontend için)
    /// </summary>
    /// <returns>Google Maps API anahtarı</returns>
    [HttpGet("api-key")]
    public ActionResult<ApiResponse<object>> GetApiKey()
    {
        try
        {
            if (_configuration == null)
            {
                Logger?.LogError("Configuration service is null");
                return StatusCode(500,
                    new ApiResponse<object>("Configuration service is not available", "INTERNAL_SERVER_ERROR"));
            }

            var apiKey = _configuration["GoogleMaps:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                return NotFound(new ApiResponse<object>("API key is not configured", "API_KEY_NOT_CONFIGURED"));
            }

            return Ok(new ApiResponse<object>(new { ApiKey = apiKey }, "API key retrieved successfully"));
        }
        catch (Exception ex)
        {
            Logger?.LogError(ex, "Error retrieving Google Maps API key: {Error}", ex.Message);
            return StatusCode(500,
                new ApiResponse<object>("An error occurred while retrieving the API key", "INTERNAL_SERVER_ERROR"));
        }
    }
}


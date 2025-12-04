using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Harita işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class MapController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// MapController constructor
    /// </summary>
    public MapController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Harita görüntüleme için konum bilgisi olan tüm satıcıları getirir
    /// </summary>
    /// <param name="userLatitude">Kullanıcı enlemi (opsiyonel)</param>
    /// <param name="userLongitude">Kullanıcı boylamı (opsiyonel)</param>
    /// <returns>Satıcı harita bilgileri listesi</returns>
    [HttpGet("vendors")]
    public async Task<ActionResult<ApiResponse<List<VendorMapDto>>>> GetVendorsForMap(
        [FromQuery] double? userLatitude,
        [FromQuery] double? userLongitude)
    {
        var vendors = await _unitOfWork.Vendors.Query()
            .Where(v => v.Latitude.HasValue && v.Longitude.HasValue)
            .Select(v => new VendorMapDto
            {
                Id = v.Id,
                Name = v.Name,
                Address = v.Address,
                Latitude = v.Latitude!.Value,
                Longitude = v.Longitude!.Value,
                ImageUrl = v.ImageUrl,
                Rating = v.Rating
            })
            .ToListAsync();

        // Calculate distance if user location provided
        if (userLatitude.HasValue && userLongitude.HasValue)
        {
            foreach (var vendor in vendors)
            {
                vendor.DistanceInKm = CalculateDistance(
                    userLatitude.Value,
                    userLongitude.Value,
                    vendor.Latitude,
                    vendor.Longitude);
            }

            // Sort by distance
            vendors = vendors.OrderBy(v => v.DistanceInKm).ToList();
        }

        return Ok(new ApiResponse<List<VendorMapDto>>(vendors, "Satıcı harita bilgileri başarıyla getirildi"));
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
        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.Courier)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            return NotFound(new ApiResponse<DeliveryTrackingDto>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (order.CustomerId != userId)
        {
            return StatusCode(403, new ApiResponse<DeliveryTrackingDto>(
                "Bu siparişe erişim yetkiniz yok",
                "FORBIDDEN"
            ));
        }

        if (order.DeliveryAddress == null ||
            !order.DeliveryAddress.Latitude.HasValue ||
            !order.DeliveryAddress.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<DeliveryTrackingDto>(
                "Teslimat adresi konumu mevcut değil",
                "DELIVERY_ADDRESS_LOCATION_NOT_AVAILABLE"
            ));
        }

        if (order.Vendor == null ||
            !order.Vendor.Latitude.HasValue ||
            !order.Vendor.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<DeliveryTrackingDto>(
                "Satıcı konumu mevcut değil",
                "VENDOR_LOCATION_NOT_AVAILABLE"
            ));
        }

        var tracking = new DeliveryTrackingDto
        {
            OrderId = order.Id,
            OrderStatus = order.Status.ToString(),
            EstimatedDeliveryTime = order.EstimatedDeliveryTime,
            VendorLatitude = order.Vendor.Latitude.Value,
            VendorLongitude = order.Vendor.Longitude.Value,
            VendorAddress = order.Vendor.Address,
            DeliveryLatitude = order.DeliveryAddress.Latitude.Value,
            DeliveryLongitude = order.DeliveryAddress.Longitude.Value,
            DeliveryAddress = order.DeliveryAddress.FullAddress
        };

        if (order.Courier != null &&
            order.Courier.CurrentLatitude.HasValue &&
            order.Courier.CurrentLongitude.HasValue)
        {
            tracking.CourierId = order.Courier.Id;
            tracking.CourierName = order.Courier.Name;
            tracking.CourierLatitude = order.Courier.CurrentLatitude.Value;
            tracking.CourierLongitude = order.Courier.CurrentLongitude.Value;
            tracking.CourierLastUpdate = order.Courier.LastLocationUpdate;
        }

        return Ok(new ApiResponse<DeliveryTrackingDto>(tracking, "Teslimat takip bilgileri başarıyla getirildi"));
    }

    /// <summary>
    /// Google Maps API anahtarını getirir (frontend için)
    /// </summary>
    /// <param name="configuration">Configuration servisi</param>
    /// <returns>Google Maps API anahtarı</returns>
    [HttpGet("api-key")]
    public ActionResult<ApiResponse<object>> GetApiKey([FromServices] IConfiguration configuration)
    {
        var apiKey = configuration["GoogleMaps:ApiKey"];
        if (string.IsNullOrEmpty(apiKey))
        {
            return NotFound(new ApiResponse<object>("Google Maps API anahtarı yapılandırılmamış", "API_KEY_NOT_CONFIGURED"));
        }

        return Ok(new ApiResponse<object>(new { ApiKey = apiKey }, "Google Maps API anahtarı başarıyla getirildi"));
    }

    // Haversine formula to calculate distance between two coordinates in kilometers
    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusKm = 6371.0;

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return earthRadiusKm * c;
    }

    private static double ToRadians(double degrees)
    {
        return degrees * Math.PI / 180.0;
    }
}


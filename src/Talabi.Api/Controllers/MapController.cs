using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MapController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public MapController(TalabiDbContext context)
    {
        _context = context;
    }

    // Get all vendors with location for map display
    [HttpGet("vendors")]
    public async Task<ActionResult<List<VendorMapDto>>> GetVendorsForMap(
        [FromQuery] double? userLatitude,
        [FromQuery] double? userLongitude)
    {
        var vendors = await _context.Vendors
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

        return Ok(vendors);
    }

    // Get delivery tracking information
    [HttpGet("delivery-tracking/{orderId}")]
    [Authorize]
    public async Task<ActionResult<DeliveryTrackingDto>> GetDeliveryTracking(int orderId)
    {
        var order = await _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.Courier)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            return NotFound("Order not found");
        }

        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (order.CustomerId != userId)
        {
            return Forbid();
        }

        if (order.DeliveryAddress == null || 
            !order.DeliveryAddress.Latitude.HasValue || 
            !order.DeliveryAddress.Longitude.HasValue)
        {
            return BadRequest("Delivery address location not available");
        }

        if (order.Vendor == null ||
            !order.Vendor.Latitude.HasValue ||
            !order.Vendor.Longitude.HasValue)
        {
            return BadRequest("Vendor location not available");
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

        return Ok(tracking);
    }

    // Get Google Maps API key (for frontend)
    [HttpGet("api-key")]
    public ActionResult GetApiKey([FromServices] IConfiguration configuration)
    {
        var apiKey = configuration["GoogleMaps:ApiKey"];
        if (string.IsNullOrEmpty(apiKey))
        {
            return NotFound("Google Maps API key not configured");
        }

        return Ok(new { ApiKey = apiKey });
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


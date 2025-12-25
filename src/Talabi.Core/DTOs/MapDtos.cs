namespace Talabi.Core.DTOs;

public class MapMarkerDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Type { get; set; } = string.Empty; // "vendor", "courier", "address"
    public string? ImageUrl { get; set; }
    public string? Address { get; set; }
}

public class VendorMapDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? Rating { get; set; }
    public double? DistanceInKm { get; set; }
}

public class DeliveryTrackingDto
{
    public Guid OrderId { get; set; }
    public string CustomerOrderId { get; set; } = string.Empty;
    public string OrderStatus { get; set; } = string.Empty;
    public DateTime? EstimatedDeliveryTime { get; set; }

    // Vendor location
    public double VendorLatitude { get; set; }
    public double VendorLongitude { get; set; }
    public string VendorAddress { get; set; } = string.Empty;

    // Delivery address
    public double DeliveryLatitude { get; set; }
    public double DeliveryLongitude { get; set; }
    public string DeliveryAddress { get; set; } = string.Empty;

    // Courier location (if assigned)
    public Guid? CourierId { get; set; }
    public string? CourierName { get; set; }
    public double? CourierLatitude { get; set; }
    public double? CourierLongitude { get; set; }
    public DateTime? CourierLastUpdate { get; set; }
}


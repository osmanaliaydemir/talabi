using Talabi.Core.Enums;

namespace Talabi.Core.DTOs;

public class VendorDto
{
    public Guid Id { get; set; }
    public VendorType Type { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Address { get; set; } = string.Empty;
    public string? City { get; set; }
    public decimal? Rating { get; set; }
    public int RatingCount { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double? DistanceInKm { get; set; }
}

public class CreateVendorDto
{
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string Address { get; set; } = string.Empty;
    public string? City { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class VendorOrderDto
{
    public Guid Id { get; set; }
    public string CustomerOrderId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? EstimatedDeliveryTime { get; set; }
    public List<VendorOrderItemDto> Items { get; set; } = new();
    
    // Courier Information
    public VendorCourierInfoDto? Courier { get; set; }
}

public class VendorCourierInfoDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public string? Status { get; set; }
    public DateTime? AssignedAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
}

public class VendorOrderItemDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
}

public class SalesReportDto
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int TotalOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public int CompletedOrders { get; set; }
    public int CancelledOrders { get; set; }
    public List<DailySalesDto> DailySales { get; set; } = new();
    public List<ProductSalesDto> TopProducts { get; set; } = new();
}

public class DailySalesDto
{
    public DateTime Date { get; set; }
    public int OrderCount { get; set; }
    public decimal Revenue { get; set; }
}

public class ProductSalesDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int QuantitySold { get; set; }
    public decimal TotalRevenue { get; set; }
}

namespace Talabi.Core.DTOs.Courier;

public class CourierOrderDto
{
    public Guid Id { get; set; }
    public string VendorName { get; set; } = string.Empty;
    public string VendorAddress { get; set; } = string.Empty;
    public double VendorLatitude { get; set; }
    public double VendorLongitude { get; set; }

    public string CustomerName { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public double DeliveryLatitude { get; set; }
    public double DeliveryLongitude { get; set; }

    public decimal DeliveryFee { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    public List<CourierOrderItemDto> Items { get; set; } = new List<CourierOrderItemDto>();
}

public class CourierOrderItemDto
{
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
}

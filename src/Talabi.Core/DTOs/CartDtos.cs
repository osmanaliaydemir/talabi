namespace Talabi.Core.DTOs;

public class CartDto
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public List<CartItemDto> Items { get; set; } = new();
    public Guid? CouponId { get; set; }
    public string? CouponCode { get; set; }
    public Guid? CampaignId { get; set; }
    public string? CampaignTitle { get; set; }
    public decimal CampaignDiscountAmount { get; set; } // Total discount from campaign
    public List<Guid> DiscountedItemIds { get; set; } = new(); // Items that received discount
}

public class CartItemDto
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal ProductPrice { get; set; }
    public string? ProductImageUrl { get; set; }
    public int Quantity { get; set; }
    public Guid VendorId { get; set; }
    public string VendorName { get; set; } = string.Empty;
    public int VendorType { get; set; } // 1 = Restaurant, 2 = Market
}

public class AddToCartDto
{
    public Guid ProductId { get; set; }
    public int Quantity { get; set; } = 1;
}

public class UpdateCartItemDto
{
    public int Quantity { get; set; }
}

public class UpdateCartPromotionsDto
{
    public string? CouponCode { get; set; }
    public Guid? CampaignId { get; set; }
}

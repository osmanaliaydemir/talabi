namespace Talabi.Core.Entities;

public class Cart : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    public ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
    
    // Promotions
    public Guid? CouponId { get; set; }
    public Coupon? Coupon { get; set; }
    
    public Guid? CampaignId { get; set; }
    public Campaign? Campaign { get; set; }
}

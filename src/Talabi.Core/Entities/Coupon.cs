

namespace Talabi.Core.Entities;

public enum DiscountType
{
    Percentage,
    FixedAmount
}

public class Coupon : BaseEntity
{
    public string Code { get; set; } = string.Empty;
    public DiscountType DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal MinCartAmount { get; set; }
    public DateTime ExpirationDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    public string? Title { get; set; }

    // --- Advanced Rules ---
    public int? VendorType { get; set; } // 1: Restaurant, 2: Market
    public Guid? VendorId { get; set; } // Specific Vendor
    
    // Time Rules
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }

    // Navigation Properties
    public ICollection<CouponCity> CouponCities { get; set; } = new List<CouponCity>();
    public ICollection<CouponDistrict> CouponDistricts { get; set; } = new List<CouponDistrict>();
    public ICollection<CouponCategory> CouponCategories { get; set; } = new List<CouponCategory>();
    public ICollection<CouponProduct> CouponProducts { get; set; } = new List<CouponProduct>();
}

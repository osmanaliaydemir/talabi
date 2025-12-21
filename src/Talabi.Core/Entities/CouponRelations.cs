namespace Talabi.Core.Entities;

public class CouponCity : BaseEntity
{
    public Guid CouponId { get; set; }
    public Coupon Coupon { get; set; } = null!;
    
    public Guid CityId { get; set; }
    public City City { get; set; } = null!;
}

public class CouponDistrict : BaseEntity
{
    public Guid CouponId { get; set; }
    public Coupon Coupon { get; set; } = null!;
    
    public Guid DistrictId { get; set; }
    public District District { get; set; } = null!;
}

public class CouponCategory : BaseEntity
{
    public Guid CouponId { get; set; }
    public Coupon Coupon { get; set; } = null!;
    
    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;
}

public class CouponProduct : BaseEntity
{
    public Guid CouponId { get; set; }
    public Coupon Coupon { get; set; } = null!;
    
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;
}

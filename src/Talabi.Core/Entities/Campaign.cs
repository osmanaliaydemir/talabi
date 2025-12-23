using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Campaign : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public string? ActionUrl { get; set; }
    
    // Priority for sorting
    // Priority for sorting
    public int Priority { get; set; } = 0;

    // Discount
    public DiscountType DiscountType { get; set; } = DiscountType.Percentage;
    public decimal DiscountValue { get; set; } = 0;

    // Rules
    public bool IsFirstOrderOnly { get; set; } = false; // Deprecated, use TargetAudience.NewUsers
    public TargetAudience TargetAudience { get; set; } = TargetAudience.All;

    // --- Advanced Rules ---

    // Usage Limits
    public int? MaxUsageCount { get; set; } // Total global usage limit
    public int? UsageLimitPerUser { get; set; } // Limit per specific user
    public int CurrentUsageCount { get; set; } = 0; // Current global usage

    // Scheduling
    // Comma separated ints: 1=Monday, 7=Sunday. Null or empty = Any day
    public string? ValidDaysOfWeek { get; set; } 

    // Time Rules
    public TimeSpan? StartTime { get; set; } 
    public TimeSpan? EndTime { get; set; }

    // Budget
    public decimal? TotalDiscountBudget { get; set; } // Max total discount amount to give away

    // Stacking
    public bool IsStackable { get; set; } = false; // Can be combined with other campaigns/coupons?

    // Vendor & Product Rules
    public int? VendorType { get; set; } // 1: Restaurant, 2: Market
    
    // Inclusions & Exclusions
    // Note: Implicitly inclusions via Relations.
    // Exclusions can be added similarly if needed, but typically Inclusions are enough for positive targeting.
    // If we need "All products except X", we'd need exclusion tables. 
    // For now, let's keep it simple with inclusions only (CampaignProducts). 
    // If CampaignProducts is empty, it applies to all products (unless Category restricted).
    
    // Cart Rules
    public decimal? MinCartAmount { get; set; }

    // Navigation Properties for Many-to-Many
    // We need to create these intermediate entities: CampaignCity, CampaignDistrict, CampaignCategory, CampaignProduct
    public ICollection<CampaignCity> CampaignCities { get; set; } = new List<CampaignCity>();
    public ICollection<CampaignDistrict> CampaignDistricts { get; set; } = new List<CampaignDistrict>();
    public ICollection<CampaignCategory> CampaignCategories { get; set; } = new List<CampaignCategory>();
    public ICollection<CampaignProduct> CampaignProducts { get; set; } = new List<CampaignProduct>();
}

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
    public int Priority { get; set; } = 0;

    // --- Advanced Rules ---

    // Vendor & Product Rules
    public int? VendorType { get; set; } // 1: Restaurant, 2: Market
    // Relations for specific inclusions
    // We will use dedicated join tables but keep navigation properties here
    // For simplicity in this first step, let's add the navigation properties or IDs if using simple lists
    // EF Core Many-to-Many requires join entities or automatic handling. We will define explicit join entities later.

    // Time Rules
    public TimeSpan? StartTime { get; set; } 
    public TimeSpan? EndTime { get; set; }

    // Cart Rules
    public decimal? MinCartAmount { get; set; }

    // Navigation Properties for Many-to-Many
    // We need to create these intermediate entities: CampaignCity, CampaignDistrict, CampaignCategory, CampaignProduct
    public ICollection<CampaignCity> CampaignCities { get; set; } = new List<CampaignCity>();
    public ICollection<CampaignDistrict> CampaignDistricts { get; set; } = new List<CampaignDistrict>();
    public ICollection<CampaignCategory> CampaignCategories { get; set; } = new List<CampaignCategory>();
    public ICollection<CampaignProduct> CampaignProducts { get; set; } = new List<CampaignProduct>();
}

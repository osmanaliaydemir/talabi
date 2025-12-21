namespace Talabi.Core.Entities;

public class CampaignCity : BaseEntity
{
    public Guid CampaignId { get; set; }
    public Campaign Campaign { get; set; } = null!;
    
    public Guid CityId { get; set; }
    public City City { get; set; } = null!;
}

public class CampaignDistrict : BaseEntity
{
    public Guid CampaignId { get; set; }
    public Campaign Campaign { get; set; } = null!;
    
    public Guid DistrictId { get; set; }
    public District District { get; set; } = null!;
}

public class CampaignCategory : BaseEntity
{
    public Guid CampaignId { get; set; }
    public Campaign Campaign { get; set; } = null!;
    
    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!;
}

public class CampaignProduct : BaseEntity
{
    public Guid CampaignId { get; set; }
    public Campaign Campaign { get; set; } = null!;
    
    public Guid ProductId { get; set; }
    public Product Product { get; set; } = null!;
}

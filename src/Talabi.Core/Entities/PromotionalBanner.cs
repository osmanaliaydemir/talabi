namespace Talabi.Core.Entities;

public class PromotionalBanner : BaseEntity
{
    public string Title { get; set; } = string.Empty; // Default/System title
    public string Subtitle { get; set; } = string.Empty; // Default/System subtitle
    public string? ButtonText { get; set; } // Default/System button text
    public string? ButtonAction { get; set; } // URL or action identifier
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; } = 0; // For ordering banners
    public bool IsActive { get; set; } = true;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public int? VendorType { get; set; } // 1: Restaurant, 2: Market, null: All
    public ICollection<PromotionalBannerTranslation> Translations { get; set; } = new List<PromotionalBannerTranslation>();
}


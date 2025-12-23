using Microsoft.AspNetCore.Mvc.Rendering;

namespace Talabi.Portal.Models;

public class CampaignFormViewModel
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public IFormFile? ImageFile { get; set; }
    public DateTime StartDate { get; set; } = DateTime.Now;
    public DateTime EndDate { get; set; } = DateTime.Now.AddDays(14);
    public bool IsActive { get; set; } = true;
    public string? ActionUrl { get; set; }
    public int Priority { get; set; } = 0;
    
    // Discount
    public int DiscountType { get; set; } // 0: Percentage, 1: FixedAmount
    public decimal DiscountValue { get; set; } = 0;
    
    public bool IsFirstOrderOnly { get; set; } = false;
    public int TargetAudience { get; set; }

    // Advanced Rules
    public int? VendorType { get; set; }
    public TimeSpan? StartTime { get; set; } 
    public TimeSpan? EndTime { get; set; }
    public decimal? MinCartAmount { get; set; }

    // Multi-Select IDs
    public List<Guid> SelectedCityIds { get; set; } = new();
    public List<Guid> SelectedDistrictIds { get; set; } = new();
    public List<Guid> SelectedCategoryIds { get; set; } = new();
    public List<Guid> SelectedProductIds { get; set; } = new();

    // Data Sources
    public List<SelectListItem> Cities { get; set; } = new();
    public List<SelectListItem> Districts { get; set; } = new();
    public List<SelectListItem> Categories { get; set; } = new();
    public List<SelectListItem> Products { get; set; } = new();
}

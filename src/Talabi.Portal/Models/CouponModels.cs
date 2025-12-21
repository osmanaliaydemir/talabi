using Microsoft.AspNetCore.Mvc.Rendering;
using Talabi.Core.Entities;

namespace Talabi.Portal.Models;

public class CouponFormViewModel
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public DiscountType DiscountType { get; set; }
    public decimal DiscountValue { get; set; }
    public decimal MinCartAmount { get; set; }
    public DateTime ExpirationDate { get; set; } = DateTime.Now.AddDays(30);
    public bool IsActive { get; set; } = true;
    public string? Description { get; set; }
    public string? Title { get; set; }

    // --- Advanced Rules ---
    public int? VendorType { get; set; } // 1: Restaurant, 2: Market
    public Guid? VendorId { get; set; }
    
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }

    // Multi-Select IDs
    public List<Guid> SelectedCityIds { get; set; } = new();
    public List<Guid> SelectedDistrictIds { get; set; } = new();
    public List<Guid> SelectedCategoryIds { get; set; } = new();
    public List<Guid> SelectedProductIds { get; set; } = new();

    // Data Sources for Dropdowns
    public List<SelectListItem> Cities { get; set; } = new();
    public List<SelectListItem> Districts { get; set; } = new();
    public List<SelectListItem> Categories { get; set; } = new(); // Flattened categories
    public List<SelectListItem> Vendors { get; set; } = new();
    // Products might be too many to list all at once, but we will add it for completeness 
    // or maybe load via AJAX. For now let's skip Products purely via static list if it's too heavy, 
    // but the entity has CouponProducts. Let's add it.
    public List<SelectListItem> Products { get; set; } = new();
}

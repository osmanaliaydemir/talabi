using Talabi.Core.Enums;

namespace Talabi.Portal.Models;

public class VendorSettingsDto
{
    public decimal MinimumOrderAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public int EstimatedDeliveryTime { get; set; } // Prep time usually? Or Delivery time?
    public BusyStatus BusyStatus { get; set; }
    public bool IsActive { get; set; }
    public string? OpeningHours { get; set; }
}

public class SystemSettingsDto
{
    public bool OrderUpdates { get; set; }
    public bool Promotions { get; set; }
    public bool NewProducts { get; set; }
}

public class SettingsViewModel
{
    public VendorSettingsDto Vendor { get; set; } = new();
    public SystemSettingsDto System { get; set; } = new();
}

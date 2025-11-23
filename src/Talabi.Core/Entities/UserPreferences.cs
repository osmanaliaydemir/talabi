namespace Talabi.Core.Entities;

public class UserPreferences : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    // Language: "tr", "en", "ar"
    public string Language { get; set; } = "tr";
    
    // Currency: "TRY", "USDT"
    public string Currency { get; set; } = "TRY";
    
    // Regional settings
    public string? TimeZone { get; set; }
    public string? DateFormat { get; set; } // "dd/MM/yyyy", "MM/dd/yyyy", etc.
    public string? TimeFormat { get; set; } // "24h", "12h"
}


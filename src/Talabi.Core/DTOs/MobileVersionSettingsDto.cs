namespace Talabi.Core.DTOs;

public class MobileVersionSettingsDto
{
    public bool ForceUpdate { get; set; }
    public string MinVersionAndroid { get; set; } = "1.0.0";
    public string MinVersionIOS { get; set; } = "1.0.0";
    
    // Localized Titles
    public string Title_TR { get; set; } = string.Empty;
    public string Title_EN { get; set; } = string.Empty;
    public string Title_AR { get; set; } = string.Empty;

    // Localized Bodies
    public string Body_TR { get; set; } = string.Empty;
    public string Body_EN { get; set; } = string.Empty;
    public string Body_AR { get; set; } = string.Empty;
}

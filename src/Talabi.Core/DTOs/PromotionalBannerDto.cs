namespace Talabi.Core.DTOs;

public class PromotionalBannerDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? ButtonText { get; set; }
    public string? ButtonAction { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? LanguageCode { get; set; } // For client to know which language version
}


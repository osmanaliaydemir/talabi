namespace Talabi.Core.Entities;

public class PromotionalBannerTranslation : BaseEntity
{
    public Guid PromotionalBannerId { get; set; }
    public PromotionalBanner? PromotionalBanner { get; set; }

    public string LanguageCode { get; set; } = string.Empty; // tr, en, ar
    public string Title { get; set; } = string.Empty;
    public string Subtitle { get; set; } = string.Empty;
    public string? ButtonText { get; set; }
}


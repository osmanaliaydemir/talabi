namespace Talabi.Core.Entities;

public class LegalDocument : BaseEntity
{
    public string Type { get; set; } = string.Empty; // TermsOfUse, PrivacyPolicy, RefundPolicy, DistanceSalesAgreement
    public string LanguageCode { get; set; } = string.Empty; // tr, en
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty; // HTML or Markdown content
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}

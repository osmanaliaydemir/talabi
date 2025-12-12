namespace Getir.MerchantPortal.Models;

public class LocalizationAdminViewModel
{
    public List<LanguageResponse> Languages { get; set; } = new();
    public List<LanguageStatisticsResponse> Statistics { get; set; } = new();
    public TranslationSearchResponseModel? TranslationSearch { get; set; }
    public string? SearchKey { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}


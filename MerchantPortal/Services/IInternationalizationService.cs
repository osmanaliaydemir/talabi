using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IInternationalizationService
{
    Task<List<LanguageResponse>> GetLanguagesAsync(CancellationToken ct = default);
    Task<List<LanguageStatisticsResponse>> GetLanguageStatisticsAsync(CancellationToken ct = default);
    Task<bool> SetDefaultLanguageAsync(Guid languageId, CancellationToken ct = default);
    Task<TranslationSearchResponseModel?> SearchTranslationsAsync(TranslationSearchRequestModel request, CancellationToken ct = default);
}


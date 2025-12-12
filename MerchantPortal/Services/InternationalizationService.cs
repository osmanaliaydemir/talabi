using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class InternationalizationService : IInternationalizationService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<InternationalizationService> _logger;

    public InternationalizationService(IApiClient apiClient, ILogger<InternationalizationService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<LanguageResponse>> GetLanguagesAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<LanguageResponse>>>("api/internationalization/languages", ct);
            return response?.Data ?? new List<LanguageResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch languages");
            return new List<LanguageResponse>();
        }
    }

    public async Task<List<LanguageStatisticsResponse>> GetLanguageStatisticsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<LanguageStatisticsResponse>>>("api/internationalization/languages/statistics", ct);
            return response?.Data ?? new List<LanguageStatisticsResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch language statistics");
            return new List<LanguageStatisticsResponse>();
        }
    }

    public async Task<bool> SetDefaultLanguageAsync(Guid languageId, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/internationalization/languages/{languageId}/set-default";
        var response = await _apiClient.PostAsync<ApiResponse<object>>(endpoint, null, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set default language {LanguageId}", languageId);
            return false;
        }
    }

    public async Task<TranslationSearchResponseModel?> SearchTranslationsAsync(TranslationSearchRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<TranslationSearchResponseModel>>(
                "api/internationalization/translations/search",
                request,
                ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to search translations");
            return null;
        }
    }
}


using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;

namespace Talabi.Api.Controllers;

/// <summary>
/// İçerik ve yasal belgeler için controller
/// </summary>
[Route("api/content")]
[ApiController]
public class ContentController(
    IUnitOfWork unitOfWork,
    ILogger<ContentController> logger,
    ILocalizationService localizationService,
    IUserContextService userContext,
    ICacheService cacheService,
    IOptions<CacheOptions> cacheOptions)
    : BaseController(unitOfWork, logger, localizationService, userContext)
{
    private readonly ICacheService _cacheService = cacheService;
    private readonly CacheOptions _cacheOptions = cacheOptions.Value;
    private const string ResourceName = "ContentResources";

    /// <summary>
    /// Dil ve tip bazında yasal belge içeriğini getirir
    /// </summary>
    /// <param name="type">Belge tipi: terms-of-use, privacy-policy, refund-policy, distance-sales-agreement</param>
    /// <returns>Yasal belge içeriği</returns>
    [HttpGet("legal/{type}")]
    public async Task<ActionResult<ApiResponse<object>>> GetLegalDocument(string type)
    {
        var languageCode = CurrentCulture.TwoLetterISOLanguageName;

        // Cache key oluştur: legal_documents_{type}_{lang}
        var cacheKey = $"{_cacheOptions.LegalDocumentsKeyPrefix}_{type}_{languageCode}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var documentDto = await _cacheService.GetOrSetAsync<object>(
            cacheKey,
            async () =>
            {
                var document = await UnitOfWork.LegalDocuments.Query()
                    .FirstOrDefaultAsync(d => d.Type == type && d.LanguageCode == languageCode);

                if (document == null)
                {
                    return null!; // Return null to indicate not found
                }

                return (object)new
                {
                    document.Type,
                    document.LanguageCode,
                    document.Title,
                    document.Content,
                    document.LastUpdated
                };
            },
            _cacheOptions.LegalDocumentsCacheTTLMinutes
        );

        if (documentDto == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "LegalDocumentNotFound", CurrentCulture, type, languageCode),
                "LEGAL_DOCUMENT_NOT_FOUND"
            ));
        }

        return Ok(new ApiResponse<object>(
            documentDto,
            LocalizationService.GetLocalizedString(ResourceName, "LegalDocumentRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Tüm mevcut yasal belge tiplerini getirir
    /// </summary>
    /// <returns>Yasal belge tipleri listesi</returns>
    [HttpGet("legal/types")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetLegalDocumentTypes()
    {
        // Cache key: legal_documents_types
        var cacheKey = $"{_cacheOptions.LegalDocumentsKeyPrefix}_types";

        // Cache-aside pattern: Önce cache'den kontrol et
        var types = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                return await UnitOfWork.LegalDocuments.Query()
                    .Select(d => d.Type)
                    .Distinct()
                    .ToListAsync();
            },
            _cacheOptions.LegalDocumentsCacheTTLMinutes
        );

        return Ok(new ApiResponse<List<string>>(
            types,
            LocalizationService.GetLocalizedString(ResourceName, "LegalDocumentTypesRetrievedSuccessfully", CurrentCulture)));
    }
}

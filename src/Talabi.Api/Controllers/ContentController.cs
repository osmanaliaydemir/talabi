using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// İçerik ve yasal belgeler için controller
/// </summary>
[Route("api/content")]
[ApiController]
public class ContentController : BaseController
{
    private const string ResourceName = "ContentResources";

    /// <summary>
    /// ContentController constructor
    /// </summary>
    public ContentController(
        IUnitOfWork unitOfWork,
        ILogger<ContentController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Dil ve tip bazında yasal belge içeriğini getirir
    /// </summary>
    /// <param name="type">Belge tipi: terms-of-use, privacy-policy, refund-policy, distance-sales-agreement</param>
    /// <returns>Yasal belge içeriği</returns>
    [HttpGet("legal/{type}")]
    public async Task<ActionResult<ApiResponse<object>>> GetLegalDocument(string type)
    {
        var languageCode = CurrentCulture.TwoLetterISOLanguageName;


        var document = await UnitOfWork.LegalDocuments.Query()
            .FirstOrDefaultAsync(d => d.Type == type && d.LanguageCode == languageCode);

        if (document == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "LegalDocumentNotFound", CurrentCulture, type, languageCode),
                "LEGAL_DOCUMENT_NOT_FOUND"
            ));
        }

        var documentDto = new
        {
            document.Type,
            document.LanguageCode,
            document.Title,
            document.Content,
            document.LastUpdated
        };

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


        var types = await UnitOfWork.LegalDocuments.Query()
            .Select(d => d.Type)
            .Distinct()
            .ToListAsync();

        return Ok(new ApiResponse<List<string>>(
            types,
            LocalizationService.GetLocalizedString(ResourceName, "LegalDocumentTypesRetrievedSuccessfully", CurrentCulture)));
    }
}

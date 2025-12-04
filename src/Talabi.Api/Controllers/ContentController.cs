using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// İçerik ve yasal belgeler için controller
/// </summary>
[Route("api/content")]
[ApiController]
public class ContentController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// ContentController constructor
    /// </summary>
    public ContentController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Dil ve tip bazında yasal belge içeriğini getirir
    /// </summary>
    /// <param name="type">Belge tipi: terms-of-use, privacy-policy, refund-policy, distance-sales-agreement</param>
    /// <param name="lang">Dil kodu (tr, en). Varsayılan: tr</param>
    /// <returns>Yasal belge içeriği</returns>
    [HttpGet("legal/{type}")]
    public async Task<ActionResult<ApiResponse<object>>> GetLegalDocument(string type, [FromQuery] string lang = "tr")
    {
        var document = await _unitOfWork.LegalDocuments.Query()
            .FirstOrDefaultAsync(d => d.Type == type && d.LanguageCode == lang);

        if (document == null)
        {
            return NotFound(new ApiResponse<object>(
                $"Yasal belge '{type}' '{lang}' dili için bulunamadı",
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

        return Ok(new ApiResponse<object>(documentDto, "Yasal belge başarıyla getirildi"));
    }

    /// <summary>
    /// Tüm mevcut yasal belge tiplerini getirir
    /// </summary>
    /// <returns>Yasal belge tipleri listesi</returns>
    [HttpGet("legal/types")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetLegalDocumentTypes()
    {
        var types = await _unitOfWork.LegalDocuments.Query()
            .Select(d => d.Type)
            .Distinct()
            .ToListAsync();

        return Ok(new ApiResponse<List<string>>(types, "Yasal belge tipleri başarıyla getirildi"));
    }
}

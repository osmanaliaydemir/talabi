using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/content")]
[ApiController]
public class ContentController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public ContentController(TalabiDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get legal document content by type and language
    /// </summary>
    /// <param name="type">Document type: terms-of-use, privacy-policy, refund-policy, distance-sales-agreement</param>
    /// <param name="lang">Language code (tr, en). Default: tr</param>
    [HttpGet("legal/{type}")]
    public async Task<IActionResult> GetLegalDocument(string type, [FromQuery] string lang = "tr")
    {
        var document = await _context.LegalDocuments
            .FirstOrDefaultAsync(d => d.Type == type && d.LanguageCode == lang);

        if (document == null)
        {
            return NotFound(new { Message = $"Legal document '{type}' not found for language '{lang}'" });
        }

        return Ok(new
        {
            document.Type,
            document.LanguageCode,
            document.Title,
            document.Content,
            document.LastUpdated
        });
    }

    /// <summary>
    /// Get all available legal document types
    /// </summary>
    [HttpGet("legal/types")]
    public async Task<IActionResult> GetLegalDocumentTypes()
    {
        var types = await _context.LegalDocuments
            .Select(d => d.Type)
            .Distinct()
            .ToListAsync();

        return Ok(types);
    }
}

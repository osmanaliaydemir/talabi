using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Arama işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class SearchController : BaseController
{
    private const string ResourceName = "SearchResources";

    /// <summary>
    /// SearchController constructor
    /// </summary>
    public SearchController(
        IUnitOfWork unitOfWork,
        ILogger<SearchController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Ürün ve satıcılar için otomatik tamamlama sonuçları getirir
    /// </summary>
    /// <param name="query">Arama sorgusu</param>
    /// <returns>Otomatik tamamlama sonuçları</returns>
    [HttpGet("autocomplete")]
    public async Task<ActionResult<ApiResponse<List<AutocompleteResultDto>>>> Autocomplete([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(
                new List<AutocompleteResultDto>(),
                LocalizationService.GetLocalizedString(ResourceName, "EmptyQuery", CurrentCulture)));
        }

        // Query is sanitized by InputSanitizationActionFilter
        // Entity Framework uses parameterized queries, so SQL injection is protected
        // For XSS protection, the filter sanitizes HTML tags from the query
        var searchQuery = query.Trim();

        var productResults = await UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Name.Contains(searchQuery) && (p.Vendor == null || p.Vendor.IsActive))
            .Take(5)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                ImageUrl = p.ImageUrl,
                Type = "product"
            })
            .ToListAsync();

        var vendorResults = await UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Name.Contains(searchQuery))
            .Take(5)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Type = "vendor"
            })
            .ToListAsync();

        var combined = productResults.Concat(vendorResults).ToList();
        return Ok(new ApiResponse<List<AutocompleteResultDto>>(
            combined,
            LocalizationService.GetLocalizedString(ResourceName, "AutocompleteResultsRetrievedSuccessfully",
                CurrentCulture)));
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Arama işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class SearchController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// SearchController constructor
    /// </summary>
    public SearchController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
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
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(new List<AutocompleteResultDto>(), "Arama sorgusu boş"));
        }

        var productResults = await _unitOfWork.Products.Query()
            .Where(p => p.Name.Contains(query))
            .Take(5)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        var vendorResults = await _unitOfWork.Vendors.Query()
            .Where(v => v.Name.Contains(query))
            .Take(5)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                Type = "vendor"
            })
            .ToListAsync();

        var combined = productResults.Concat(vendorResults).ToList();
        return Ok(new ApiResponse<List<AutocompleteResultDto>>(combined, "Otomatik tamamlama sonuçları başarıyla getirildi"));
    }
}

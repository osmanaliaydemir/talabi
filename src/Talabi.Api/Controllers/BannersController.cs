using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BannersController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public BannersController(TalabiDbContext context)
    {
        _context = context;
    }

    // GET: api/banners
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PromotionalBannerDto>>> GetBanners(
        [FromQuery] string? language = "tr")
    {
        var now = DateTime.UtcNow;
        var languageCode = language?.ToLower() ?? "tr";
        
        // Validate language code
        if (languageCode != "tr" && languageCode != "en" && languageCode != "ar")
        {
            languageCode = "tr"; // Default to Turkish
        }

        var banners = await _context.PromotionalBanners
            .Include(b => b.Translations)
            .Where(b => b.IsActive &&
                       (b.StartDate == null || b.StartDate <= now) &&
                       (b.EndDate == null || b.EndDate >= now))
            .OrderBy(b => b.DisplayOrder)
            .ThenBy(b => b.CreatedAt)
            .ToListAsync();

        var result = banners.Select(b =>
        {
            // Try to get translation for the requested language
            var translation = b.Translations
                .FirstOrDefault(t => t.LanguageCode == languageCode);

            return new PromotionalBannerDto
            {
                Id = b.Id,
                Title = translation?.Title ?? b.Title,
                Subtitle = translation?.Subtitle ?? b.Subtitle,
                ButtonText = translation?.ButtonText ?? b.ButtonText,
                ButtonAction = b.ButtonAction,
                ImageUrl = b.ImageUrl,
                DisplayOrder = b.DisplayOrder,
                IsActive = b.IsActive,
                StartDate = b.StartDate,
                EndDate = b.EndDate,
                LanguageCode = languageCode
            };
        }).ToList();

        return Ok(result);
    }

    // GET: api/banners/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<PromotionalBannerDto>> GetBanner(
        Guid id,
        [FromQuery] string? language = "tr")
    {
        var languageCode = language?.ToLower() ?? "tr";
        
        // Validate language code
        if (languageCode != "tr" && languageCode != "en" && languageCode != "ar")
        {
            languageCode = "tr"; // Default to Turkish
        }

        var banner = await _context.PromotionalBanners
            .Include(b => b.Translations)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (banner == null)
        {
            return NotFound();
        }

        // Try to get translation for the requested language
        var translation = banner.Translations
            .FirstOrDefault(t => t.LanguageCode == languageCode);

        var result = new PromotionalBannerDto
        {
            Id = banner.Id,
            Title = translation?.Title ?? banner.Title,
            Subtitle = translation?.Subtitle ?? banner.Subtitle,
            ButtonText = translation?.ButtonText ?? banner.ButtonText,
            ButtonAction = banner.ButtonAction,
            ImageUrl = banner.ImageUrl,
            DisplayOrder = banner.DisplayOrder,
            IsActive = banner.IsActive,
            StartDate = banner.StartDate,
            EndDate = banner.EndDate,
            LanguageCode = languageCode
        };

        return Ok(result);
    }
}


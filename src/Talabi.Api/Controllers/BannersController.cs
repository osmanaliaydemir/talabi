using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Promosyonel banner'lar için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class BannersController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// BannersController constructor
    /// </summary>
    public BannersController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Aktif promosyonel banner'ları getirir
    /// </summary>
    /// <param name="language">Dil kodu (tr, en, ar). Varsayılan: tr</param>
    /// <param name="vendorType">Satıcı türü (1: Restaurant, 2: Market). Opsiyonel</param>
    /// <returns>Banner listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<PromotionalBannerDto>>>> GetBanners([FromQuery] string? language = "tr", [FromQuery] int? vendorType = null)
    {
        var now = DateTime.UtcNow;
        var languageCode = language?.ToLower() ?? "tr";

        // Validate language code
        if (languageCode != "tr" && languageCode != "en" && languageCode != "ar")
        {
            languageCode = "tr"; // Default to Turkish
        }

        IQueryable<PromotionalBanner> query = _unitOfWork.PromotionalBanners.Query()
            .Include(b => b.Translations)
            .Where(b => b.IsActive &&
                       (b.StartDate == null || b.StartDate <= now) &&
                       (b.EndDate == null || b.EndDate >= now));

        // Filter by VendorType if provided
        // Logic: Return banners specific to that vendor type OR generic banners (null)
        if (vendorType.HasValue)
        {
            query = query.Where(b => b.VendorType == null || b.VendorType == vendorType.Value);
        }

        IOrderedQueryable<PromotionalBanner> orderedQuery = query
            .OrderBy(b => b.DisplayOrder)
            .ThenBy(b => b.CreatedAt);

        var banners = await orderedQuery.ToListAsync();

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
                LanguageCode = languageCode,
                VendorType = b.VendorType
            };
        }).ToList();

        return Ok(new ApiResponse<List<PromotionalBannerDto>>(result, "Banner'lar başarıyla getirildi"));
    }

    /// <summary>
    /// ID'ye göre banner getirir
    /// </summary>
    /// <param name="id">Banner ID'si</param>
    /// <param name="language">Dil kodu (tr, en, ar). Varsayılan: tr</param>
    /// <returns>Banner detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<PromotionalBannerDto>>> GetBanner(Guid id, [FromQuery] string? language = "tr")
    {
        var languageCode = language?.ToLower() ?? "tr";

        // Validate language code
        if (languageCode != "tr" && languageCode != "en" && languageCode != "ar")
        {
            languageCode = "tr"; // Default to Turkish
        }

        var banner = await _unitOfWork.PromotionalBanners.Query()
            .Include(b => b.Translations)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (banner == null)
        {
            return NotFound(new ApiResponse<PromotionalBannerDto>(
                "Banner bulunamadı",
                "BANNER_NOT_FOUND"
            ));
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
            LanguageCode = languageCode,
            VendorType = banner.VendorType
        };

        return Ok(new ApiResponse<PromotionalBannerDto>(result, "Banner başarıyla getirildi"));
    }
}


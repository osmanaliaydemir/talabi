using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;

namespace Talabi.Api.Controllers;

/// <summary>
/// Promosyonel banner'lar için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class BannersController : BaseController
{
    private readonly ICacheService _cacheService;
    private readonly CacheOptions _cacheOptions;
    private const string ResourceName = "BannerResources";

    /// <summary>
    /// BannersController constructor
    /// </summary>
    public BannersController(
        IUnitOfWork unitOfWork,
        ILogger<BannersController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        ICacheService cacheService,
        IOptions<CacheOptions> cacheOptions)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _cacheService = cacheService;
        _cacheOptions = cacheOptions.Value;
    }

    /// <summary>
    /// Aktif promosyonel banner'ları getirir
    /// </summary>
    /// <summary>
    /// Aktif promosyonel banner'ları getirir
    /// </summary>
    /// <param name="vendorType">Satıcı türü (1: Restaurant, 2: Market). Opsiyonel</param>
    /// <returns>Banner listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<PromotionalBannerDto>>>> GetBanners([FromQuery] int? vendorType = null)
    {
        var languageCode = CurrentCulture.TwoLetterISOLanguageName;
        
        // Cache key oluştur: banners_{vendorType}_{lang}
        var vendorTypeStr = vendorType?.ToString() ?? "all";
        var cacheKey = $"{_cacheOptions.BannersKeyPrefix}_{vendorTypeStr}_{languageCode}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var result = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                var now = DateTime.UtcNow;

                IQueryable<PromotionalBanner> query = UnitOfWork.PromotionalBanners.Query()
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

                return banners.Select(b =>
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
            },
            _cacheOptions.BannersCacheTTLMinutes
        );

        return Ok(new ApiResponse<List<PromotionalBannerDto>>(result, LocalizationService.GetLocalizedString(ResourceName, "BannersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// ID'ye göre banner getirir
    /// </summary>
    /// <summary>
    /// ID'ye göre banner getirir
    /// </summary>
    /// <param name="id">Banner ID'si</param>
    /// <returns>Banner detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<PromotionalBannerDto>>> GetBanner(Guid id)
    {

        var banner = await UnitOfWork.PromotionalBanners.Query()
            .Include(b => b.Translations)
            .FirstOrDefaultAsync(b => b.Id == id);

        if (banner == null)
        {
            return NotFound(new ApiResponse<PromotionalBannerDto>(
                LocalizationService.GetLocalizedString(ResourceName, "BannerNotFound", CurrentCulture),
                "BANNER_NOT_FOUND"
            ));
        }

        // Try to get translation for the requested language
        var translation = banner.Translations
            .FirstOrDefault(t => t.LanguageCode == CurrentCulture.TwoLetterISOLanguageName);

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
            LanguageCode = CurrentCulture.TwoLetterISOLanguageName,
            VendorType = banner.VendorType
        };

        return Ok(new ApiResponse<PromotionalBannerDto>(result, LocalizationService.GetLocalizedString(ResourceName, "BannerRetrievedSuccessfully", CurrentCulture)));
    }
}


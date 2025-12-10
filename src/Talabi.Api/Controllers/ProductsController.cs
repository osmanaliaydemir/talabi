using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Ürün işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class ProductsController : BaseController
{
    private readonly IMapper _mapper;
    private readonly ICacheService _cacheService;
    private readonly CacheOptions _cacheOptions;
    private const string ResourceName = "ProductResources";

    /// <summary>
    /// ProductsController constructor
    /// </summary>
    /// <param name="unitOfWork">Unit of Work instance</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="localizationService">Localization service</param>
    /// <param name="userContext">User context service</param>
    /// <param name="mapper">AutoMapper instance</param>
    /// <param name="cacheService">Cache service instance</param>
    /// <param name="cacheOptions">Cache options</param>
    public ProductsController(
        IUnitOfWork unitOfWork, 
        ILogger<ProductsController> logger, 
        ILocalizationService localizationService, 
        IUserContextService userContext, 
        IMapper mapper,
        ICacheService cacheService,
        IOptions<CacheOptions> cacheOptions)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _mapper = mapper;
        _cacheService = cacheService;
        _cacheOptions = cacheOptions.Value;
    }

    /// <summary>
    /// Ürün arama endpoint'i - Filtreleme, sıralama ve sayfalama desteği ile
    /// </summary>
    /// <summary>
    /// Ürün arama endpoint'i - Filtreleme, sıralama ve sayfalama desteği ile
    /// </summary>
    /// <param name="request">Arama parametreleri</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("search")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> Search([FromQuery] ProductSearchRequestDto request)
    {

        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Vendor == null || p.Vendor.IsActive); // Sadece aktif vendor'ların ürünleri

        // Text search - Case-insensitive search helper kullanımı
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            query = query.WhereContainsIgnoreCase(p => p.Name, request.Query);
            // Description için de case-insensitive search
            if (!string.IsNullOrWhiteSpace(request.Query))
            {
                query = query.Where(p => p.Description != null &&
                    p.Description.ToLower().Contains(request.Query.ToLower()));
            }
        }

        // VendorType filter (Vendor üzerinden - performans için)
        if (request.VendorType.HasValue)
        {
            query = query.Where(p => p.Vendor != null && p.Vendor.Type == request.VendorType.Value);
        }

        // Category filter
        if (request.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == request.CategoryId.Value);
        }
        else if (!string.IsNullOrWhiteSpace(request.Category))
        {
            // Fallback to string match (deprecated)
            query = query.Where(p => p.Category == request.Category);
        }

        // Price range filter
        if (request.MinPrice.HasValue)
        {
            query = query.Where(p => p.Price >= request.MinPrice.Value);
        }

        if (request.MaxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= request.MaxPrice.Value);
        }

        // Vendor filter
        if (request.VendorId.HasValue)
        {
            query = query.Where(p => p.VendorId == request.VendorId.Value);
        }

        // Sorting
        IOrderedQueryable<Product> orderedQuery = request.SortBy?.ToLower() switch
        {
            "price_asc" => query.OrderBy(p => p.Price),
            "price_desc" => query.OrderByDescending(p => p.Price),
            "name" => query.OrderBy(p => p.Name),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            _ => query.OrderBy(p => p.Name)
        };

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                VendorName = p.Vendor != null ? p.Vendor.Name : null,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            },
            request.Page,
            request.PageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<ProductDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result, LocalizationService.GetLocalizedString(ResourceName, "ProductsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kategorileri getirir - Dil ve VendorType desteği ile
    /// </summary>
    /// <param name="lang">Dil kodu (tr, en, ar) - Opsiyonel, header yoksa kullanılır</param>
    /// <param name="vendorType">Vendor türü filtresi (opsiyonel)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış kategori listesi</returns>
    [HttpGet("categories")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<CategoryDto>>>> GetCategories(
        [FromQuery] string? lang = null,
        [FromQuery] Talabi.Core.Enums.VendorType? vendorType = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        // lang parametresi varsa onu kullan, yoksa header'dan gelen CurrentCulture'ı kullan
        var languageCode = !string.IsNullOrEmpty(lang) ? NormalizeLanguageCode(lang) : CurrentCulture.TwoLetterISOLanguageName;

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Cache key oluştur: categories_{vendorType}_{lang}_{page}_{pageSize}
        var vendorTypeStr = vendorType?.ToString() ?? "all";
        var cacheKey = $"{_cacheOptions.CategoriesKeyPrefix}_{vendorTypeStr}_{languageCode}_{page}_{pageSize}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var result = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                // Base query - Include kullanmadan direkt Select ile projection yapıyoruz (daha performanslı)
                IQueryable<Category> baseQuery = UnitOfWork.Categories.Query();

                // VendorType filtresi
                if (vendorType.HasValue)
                {
                    baseQuery = baseQuery.Where(c => c.VendorType == vendorType.Value);
                }

                // Database seviyesinde pagination ve projection
                // Translation'ı subquery ile alıyoruz (left join benzeri)
                var query = baseQuery
                    .OrderBy(c => c.DisplayOrder)
                    .ThenBy(c => c.Name)
                    .Select(c => new CategoryDto
                    {
                        Id = c.Id,
                        VendorType = c.VendorType,
                        // Translation varsa onu kullan, yoksa default name'i kullan
                        Name = c.Translations
                            .Where(t => t.LanguageCode == languageCode)
                            .Select(t => t.Name)
                            .FirstOrDefault() ?? c.Name,
                        Icon = c.Icon,
                        Color = c.Color,
                        ImageUrl = c.ImageUrl,
                        DisplayOrder = c.DisplayOrder
                    });

                // Database seviyesinde pagination - ToPagedResultAsync kullanıyoruz
                var pagedResult = await query.ToPagedResultAsync(page, pageSize);

                // PagedResult'ı PagedResultDto'ya çevir
                return new PagedResultDto<CategoryDto>
                {
                    Items = pagedResult.Items,
                    TotalCount = pagedResult.TotalCount,
                    Page = pagedResult.Page,
                    PageSize = pagedResult.PageSize,
                    TotalPages = pagedResult.TotalPages
                };
            },
            _cacheOptions.CategoriesCacheTTLMinutes
        );

        return Ok(new ApiResponse<PagedResultDto<CategoryDto>>(result, LocalizationService.GetLocalizedString(ResourceName, "CategoriesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Ürün arama için autocomplete endpoint'i
    /// </summary>
    /// <summary>
    /// Ürün arama için autocomplete endpoint'i
    /// </summary>
    /// <param name="query">Arama metni</param>
    /// <returns>Autocomplete sonuçları</returns>
    [HttpGet("autocomplete")]
    public async Task<ActionResult<ApiResponse<List<AutocompleteResultDto>>>> Autocomplete([FromQuery] string query)
    {

        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(new List<AutocompleteResultDto>(), LocalizationService.GetLocalizedString(ResourceName, "NoResultsFound", CurrentCulture)));
        }

        var results = await UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Name.Contains(query) && (p.Vendor == null || p.Vendor.IsActive)) // Sadece aktif vendor'ların ürünleri
            .Take(10)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AutocompleteResultDto>>(results, LocalizationService.GetLocalizedString(ResourceName, "AutocompleteResultsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Popüler ürünleri getirir - Sipariş sayısına göre sıralanır
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <param name="vendorType">Vendor türü filtresi (opsiyonel)</param>
    /// <summary>
    /// Popüler ürünleri getirir - Sipariş sayısına göre sıralanır
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <param name="vendorType">Vendor türü filtresi (opsiyonel)</param>
    /// <returns>Sayfalanmış popüler ürün listesi</returns>
    [HttpGet("popular")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetPopularProducts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6,
        [FromQuery] Talabi.Core.Enums.VendorType? vendorType = null)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Cache key: popular_products_{vendorType}_{page}_{pageSize}
        var vendorTypeStr = vendorType?.ToString() ?? "all";
        var cacheKey = $"{_cacheOptions.PopularProductsKeyPrefix}_{vendorTypeStr}_{page}_{pageSize}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var result = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                var query = UnitOfWork.Products.Query()
                    .Include(p => p.Vendor)
                    .Where(p => p.Vendor == null || p.Vendor.IsActive) // Sadece aktif vendor'ların ürünleri
                    .AsQueryable();

                if (vendorType.HasValue)
                {
                    query = query.Where(p => (p.VendorType ?? (p.Vendor != null ? p.Vendor.Type : (Talabi.Core.Enums.VendorType?)null)) == vendorType.Value);
                }

                // Get popular products based on order count
                var orderedQuery = query
                    .Select(p => new
                    {
                        Product = p,
                        OrderCount = UnitOfWork.OrderItems.Query().Count(oi => oi.ProductId == p.Id)
                    })
                    .OrderByDescending(x => x.OrderCount)
                    .ThenByDescending(x => x.Product.CreatedAt)
                    .Select(x => x.Product);

                // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
                var pagedResult = await orderedQuery.ToPagedResultAsync(
                    p => new ProductDto
                    {
                        Id = p.Id,
                        VendorId = p.VendorId,
                        VendorName = p.Vendor != null ? p.Vendor.Name : null,
                        Name = p.Name,
                        Description = p.Description,
                        Category = p.Category,
                        Price = p.Price,
                        Currency = p.Currency,
                        ImageUrl = p.ImageUrl,
                        VendorType = p.VendorType ?? (p.Vendor != null ? p.Vendor.Type : null)
                    },
                    page,
                    pageSize);

                // PagedResult'ı PagedResultDto'ya çevir
                return new PagedResultDto<ProductDto>
                {
                    Items = pagedResult.Items,
                    TotalCount = pagedResult.TotalCount,
                    Page = pagedResult.Page,
                    PageSize = pagedResult.PageSize,
                    TotalPages = pagedResult.TotalPages
                };
            },
            _cacheOptions.PopularProductsCacheTTLMinutes
        );

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "PopularProductsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// ID'ye göre ürün detayını getirir
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <returns>Ürün detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> GetProduct(Guid id)
    {
        var product = await UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Include(p => p.ProductCategory)
            .Where(p => p.Id == id && (p.Vendor == null || p.Vendor.IsActive)) // Sadece aktif vendor'ların ürünleri
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound(new ApiResponse<ProductDto>(LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        var productDto = _mapper.Map<ProductDto>(product);

        if (product == null)
        {
            return NotFound(new ApiResponse<ProductDto>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        return Ok(new ApiResponse<ProductDto>(productDto, LocalizationService.GetLocalizedString(ResourceName, "ProductRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Benzer ürünleri getirir - Aynı kategorideki diğer ürünler
    /// </summary>
    /// <param name="id">Mevcut ürün ID'si</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış benzer ürün listesi</returns>
    [HttpGet("{id}/similar")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetSimilarProducts(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Mevcut ürünü getir
        var currentProduct = await UnitOfWork.Products.Query()
            .Where(p => p.Id == id)
            .FirstOrDefaultAsync();

        if (currentProduct == null)
        {
            return NotFound(new ApiResponse<PagedResultDto<ProductDto>>(LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        // Aynı kategorideki diğer ürünleri getir
        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Id != id && p.IsAvailable && (p.Vendor == null || p.Vendor.IsActive)); // Mevcut ürünü hariç tut, sadece müsait olanları ve aktif vendor'ların ürünlerini getir

        // CategoryId varsa ona göre filtrele (öncelikli)
        if (currentProduct.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == currentProduct.CategoryId.Value);
        }
        // CategoryId yoksa Category string'ine göre filtrele (fallback)
        else if (!string.IsNullOrWhiteSpace(currentProduct.Category))
        {
            query = query.Where(p => p.Category == currentProduct.Category);
        }
        else
        {
            // Ne CategoryId ne de Category varsa boş liste döndür
            var emptyResult = new PagedResultDto<ProductDto>
            {
                Items = new List<ProductDto>(),
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                TotalPages = 0
            };
            return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "SimilarProductsNotFound", CurrentCulture)));
        }

        IOrderedQueryable<Product> orderedQuery = query.OrderByDescending(p => p.CreatedAt); // En yeni ürünler önce

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                VendorName = p.Vendor != null ? p.Vendor.Name : null,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                CategoryId = p.CategoryId,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            },
            page,
            pageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<ProductDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "SimilarProductsRetrievedSuccessfully", CurrentCulture)));
    }
}

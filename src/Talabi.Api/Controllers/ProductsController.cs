using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Talabi.Core.Enums;
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
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> Search(
        [FromQuery] ProductSearchRequestDto request)
    {
        // Distance filter (REQUIRED: user location must be provided)
        if (!request.UserLatitude.HasValue || !request.UserLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
            var emptyResult = new PagedResultDto<ProductDto>
            {
                Items = new List<ProductDto>(),
                TotalCount = 0,
                Page = request.Page,
                PageSize = request.PageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForProductSearch", CurrentCulture)));
        }

        var userLat = request.UserLatitude.Value;
        var userLon = request.UserLongitude.Value;

        // Önce yarıçap içindeki vendor'ları bul
        var vendorsInRadius = await UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue &&
                        GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <= 
                        (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
            .Select(v => v.Id)
            .ToListAsync();

        if (!vendorsInRadius.Any())
        {
            // Yarıçap içinde vendor yoksa boş liste döndür
            var emptyResult = new PagedResultDto<ProductDto>
            {
                Items = new List<ProductDto>(),
                TotalCount = 0,
                Page = request.Page,
                PageSize = request.PageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "NoVendorsInDeliveryRadius", CurrentCulture)));
        }

        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Vendor != null && p.Vendor.IsActive && vendorsInRadius.Contains(p.VendorId)); // Sadece yarıçap içindeki aktif vendor'ların ürünleri

        // Text search
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            // Query is already sanitized by InputSanitizationActionFilter
            // But we trim and normalize for search
            var q = request.Query.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(q) ||
                                     (p.Description != null && p.Description.ToLower().Contains(q)));
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
                ImageUrl = p.ImageUrl,
                IsBestSeller = UnitOfWork.OrderItems.Query().Count(oi => oi.ProductId == p.Id) > 10,
                ReviewCount = UnitOfWork.Reviews.Query().Count(r => r.ProductId == p.Id && r.IsApproved),
                Rating = UnitOfWork.Reviews.Query().Where(r => r.ProductId == p.Id && r.IsApproved)
                    .Select(r => (double?)r.Rating).Average()
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

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result,
            LocalizationService.GetLocalizedString(ResourceName, "ProductsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kategorileri getirir - Dil ve VendorType desteği ile
    /// </summary>
    /// <param name="lang">Dil kodu (tr, en, ar) - Opsiyonel, header yoksa kullanılır</param>
    /// <param name="vendorType">Vendor türü filtresi (opsiyonel)</param>
    /// <param name="userLatitude">Kullanıcı enlemi (ZORUNLU - mesafe filtresi için)</param>
    /// <param name="userLongitude">Kullanıcı boylamı (ZORUNLU - mesafe filtresi için)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış kategori listesi</returns>
    [HttpGet("categories")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<CategoryDto>>>> GetCategories(
        [FromQuery] string? lang = null,
        [FromQuery] VendorType? vendorType = null,
        [FromQuery] double? userLatitude = null,
        [FromQuery] double? userLongitude = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        // lang parametresi varsa onu kullan, yoksa header'dan gelen CurrentCulture'ı kullan
        var languageCode = !string.IsNullOrEmpty(lang)
            ? NormalizeLanguageCode(lang)
            : CurrentCulture.TwoLetterISOLanguageName;

        // Distance filter (REQUIRED: user location must be provided)
        if (!userLatitude.HasValue || !userLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
            var emptyResult = new PagedResultDto<CategoryDto>
            {
                Items = new List<CategoryDto>(),
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<CategoryDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForCategories", CurrentCulture)));
        }

        var userLat = userLatitude.Value;
        var userLon = userLongitude.Value;

        // Önce yarıçap içindeki vendor'ları bul
        var vendorsInRadius = await UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue &&
                        GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <= 
                        (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
            .Select(v => v.Id)
            .ToListAsync();

        if (!vendorsInRadius.Any())
        {
            // Yarıçap içinde vendor yoksa boş liste döndür
            var emptyResult = new PagedResultDto<CategoryDto>
            {
                Items = new List<CategoryDto>(),
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<CategoryDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "NoVendorsInDeliveryRadius", CurrentCulture)));
        }

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Cache key oluştur: categories_{vendorType}_{lang}_{userLat}_{userLon}_{page}_{pageSize}
        var vendorTypeStr = vendorType?.ToString() ?? "all";
        var cacheKey = $"{_cacheOptions.CategoriesKeyPrefix}_{vendorTypeStr}_{languageCode}_{userLat}_{userLon}_{page}_{pageSize}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var result = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                // Sadece yarıçap içindeki vendor'ların ürünlerine sahip kategorileri getir
                var categoriesWithProducts = await UnitOfWork.Products.Query()
                    .Where(p => vendorsInRadius.Contains(p.VendorId) && 
                                p.CategoryId.HasValue)
                    .Select(p => p.CategoryId!.Value)
                    .Distinct()
                    .ToListAsync();

                // Base query - Sadece yarıçap içindeki vendor'ların kategorileri
                IQueryable<Category> baseQuery = UnitOfWork.Categories.Query()
                    .Where(c => categoriesWithProducts.Contains(c.Id));

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

        return Ok(new ApiResponse<PagedResultDto<CategoryDto>>(result,
            LocalizationService.GetLocalizedString(ResourceName, "CategoriesRetrievedSuccessfully", CurrentCulture)));
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
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(new List<AutocompleteResultDto>(),
                LocalizationService.GetLocalizedString(ResourceName, "NoResultsFound", CurrentCulture)));
        }

        // Autocomplete için konum filtresi yok (hızlı arama için)
        // Ama yine de aktif vendor kontrolü yapıyoruz
        var results = await UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Name.Contains(query) &&
                        (p.Vendor == null || p.Vendor.IsActive)) // Sadece aktif vendor'ların ürünleri
            .Take(10)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                Type = "product"
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AutocompleteResultDto>>(results,
            LocalizationService.GetLocalizedString(ResourceName, "AutocompleteResultsRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Popüler ürünleri getirir - Sipariş sayısına göre sıralanır
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <param name="vendorType">Vendor türü filtresi (opsiyonel)</param>
    /// <param name="userLatitude">Kullanıcı enlemi (ZORUNLU - mesafe filtresi için)</param>
    /// <param name="userLongitude">Kullanıcı boylamı (ZORUNLU - mesafe filtresi için)</param>
    /// <returns>Sayfalanmış popüler ürün listesi</returns>
    [HttpGet("popular")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetPopularProducts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6,
        [FromQuery] VendorType? vendorType = null,
        [FromQuery] double? userLatitude = null,
        [FromQuery] double? userLongitude = null)
    {
        // Distance filter (REQUIRED: user location must be provided)
        if (!userLatitude.HasValue || !userLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
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
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForPopularProducts", CurrentCulture)));
        }

        var userLat = userLatitude.Value;
        var userLon = userLongitude.Value;

        // Önce yarıçap içindeki vendor'ları bul
        var vendorsInRadius = await UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue &&
                        GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <= 
                        (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
            .Select(v => v.Id)
            .ToListAsync();

        if (!vendorsInRadius.Any())
        {
            // Yarıçap içinde vendor yoksa boş liste döndür
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
                LocalizationService.GetLocalizedString(ResourceName, "NoVendorsInDeliveryRadius", CurrentCulture)));
        }

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Cache key: popular_products_{vendorType}_{userLat}_{userLon}_{page}_{pageSize}
        var vendorTypeStr = vendorType?.ToString() ?? "all";
        var cacheKey = $"{_cacheOptions.PopularProductsKeyPrefix}_{vendorTypeStr}_{userLat}_{userLon}_{page}_{pageSize}";

        // Cache-aside pattern: Önce cache'den kontrol et
        var result = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                var query = UnitOfWork.Products.Query()
                    .Include(p => p.Vendor)
                    .Where(p => p.Vendor != null && p.Vendor.IsActive && vendorsInRadius.Contains(p.VendorId)) // Sadece yarıçap içindeki aktif vendor'ların ürünleri
                    .AsQueryable();

                if (vendorType.HasValue)
                {
                    query = query.Where(p =>
                        (p.VendorType ?? (p.Vendor != null ? p.Vendor.Type : null)) ==
                        vendorType.Value);
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
                        VendorType = p.VendorType ?? (p.Vendor != null ? p.Vendor.Type : null),
                        IsBestSeller = UnitOfWork.OrderItems.Query().Count(oi => oi.ProductId == p.Id) > 10,
                        ReviewCount = UnitOfWork.Reviews.Query().Count(r => r.ProductId == p.Id && r.IsApproved),
                        Rating = UnitOfWork.Reviews.Query().Where(r => r.ProductId == p.Id && r.IsApproved)
                            .Select(r => (double?)r.Rating).Average()
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
            LocalizationService.GetLocalizedString(ResourceName, "PopularProductsRetrievedSuccessfully",
                CurrentCulture)));
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
            .Include(p => p.OptionGroups)
            .ThenInclude(og => og.Options)
            .Where(p => p.Id == id && (p.Vendor == null || p.Vendor.IsActive)) // Sadece aktif vendor'ların ürünleri
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound(new ApiResponse<ProductDto>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        var productDto = _mapper.Map<ProductDto>(product);
        productDto.IsBestSeller = await UnitOfWork.OrderItems.Query().CountAsync(oi => oi.ProductId == product.Id) > 10;
        productDto.ReviewCount =
            await UnitOfWork.Reviews.Query().CountAsync(r => r.ProductId == product.Id && r.IsApproved);
        productDto.Rating = await UnitOfWork.Reviews.Query().Where(r => r.ProductId == product.Id && r.IsApproved)
            .Select(r => (double?)r.Rating).AverageAsync();

        return Ok(new ApiResponse<ProductDto>(productDto,
            LocalizationService.GetLocalizedString(ResourceName, "ProductRetrievedSuccessfully", CurrentCulture)));
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
            return NotFound(new ApiResponse<PagedResultDto<ProductDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        // Aynı kategorideki diğer ürünleri getir
        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Id != id && p.IsAvailable &&
                        (p.Vendor == null ||
                         p.Vendor
                             .IsActive)); // Mevcut ürünü hariç tut, sadece müsait olanları ve aktif vendor'ların ürünlerini getir

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
                ImageUrl = p.ImageUrl,
                IsBestSeller = UnitOfWork.OrderItems.Query().Count(oi => oi.ProductId == p.Id) > 10,
                ReviewCount = UnitOfWork.Reviews.Query().Count(r => r.ProductId == p.Id && r.IsApproved),
                Rating = UnitOfWork.Reviews.Query().Where(r => r.ProductId == p.Id && r.IsApproved)
                    .Select(r => (double?)r.Rating).Average()
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
            LocalizationService.GetLocalizedString(ResourceName, "SimilarProductsRetrievedSuccessfully",
                CurrentCulture)));
    }
}

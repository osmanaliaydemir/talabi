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
/// Satıcı işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class VendorsController : BaseController
{
    private readonly ICacheService _cacheService;
    private readonly CacheOptions _cacheOptions;
    private const string ResourceName = "VendorResources";

    /// <summary>
    /// VendorsController constructor
    /// </summary>
    public VendorsController(
        IUnitOfWork unitOfWork,
        ILogger<VendorsController> logger,
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
    /// Tüm satıcıları getirir
    /// </summary>
    /// <param name="vendorType">Satıcı türü filtresi (opsiyonel)</param>
    /// <param name="userLatitude">Kullanıcı enlemi (opsiyonel - mesafe filtresi için)</param>
    /// <param name="userLongitude">Kullanıcı boylamı (opsiyonel - mesafe filtresi için)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış satıcı listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorDto>>>> GetVendors(
        [FromQuery] Talabi.Core.Enums.VendorType? vendorType = null,
        [FromQuery] double? userLatitude = null,
        [FromQuery] double? userLongitude = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        IQueryable<Vendor> query = UnitOfWork.Vendors.Query();

        // IsActive filtresi - Sadece aktif vendor'ları getir
        query = query.Where(v => v.IsActive);

        // VendorType filtresi
        if (vendorType.HasValue)
        {
            query = query.Where(v => v.Type == vendorType.Value);
        }

        // Distance filter (REQUIRED: user location must be provided)
        if (!userLatitude.HasValue || !userLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
            var emptyResult = new PagedResultDto<VendorDto>
            {
                Items = new List<VendorDto>(),
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<VendorDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForVendorList", CurrentCulture)));
        }

        var userLat = userLatitude.Value;
        var userLon = userLongitude.Value;

        // Filter: Is the user within the vendor's delivery radius?
        // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
        // Sadece yarıçap içindeki vendor'ları göster, dışındakileri gösterme
        query = query.Where(v => v.Latitude.HasValue && v.Longitude.HasValue &&
                                 GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value,
                                     v.Longitude!.Value) <= (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm));

        IOrderedQueryable<Vendor> orderedQuery = query.OrderBy(v => v.Name);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var vendors = await orderedQuery
            .Paginate(page, pageSize)
            .ToListAsync();

        // Calculate distance and map to DTOs
        var items = vendors.Select(v =>
        {
            var dto = new VendorDto
            {
                Id = v.Id,
                Type = v.Type,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Address = v.Address,
                City = v.City,
                Rating = v.Rating,
                RatingCount = v.RatingCount,
                // DeliveryRadiusInKm = 0 ise, 5 km olarak göster (default)
                DeliveryRadiusInKm = v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm,
                Latitude = v.Latitude.HasValue ? (double)v.Latitude.Value : null,
                Longitude = v.Longitude.HasValue ? (double)v.Longitude.Value : null
            };

            // Calculate distance if user location provided
            if (userLatitude.HasValue && userLongitude.HasValue &&
                v.Latitude.HasValue && v.Longitude.HasValue)
            {
                dto.DistanceInKm = GeoHelper.CalculateDistance(
                    userLatitude.Value,
                    userLongitude.Value,
                    v.Latitude.Value,
                    v.Longitude.Value);
            }

            return dto;
        }).ToList();

        // Total count hesapla
        var totalCount = await query.CountAsync();

        var result = new PagedResultDto<VendorDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
        };

        return Ok(new ApiResponse<PagedResultDto<VendorDto>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "VendorsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Yeni satıcı oluşturur
    /// </summary>
    /// <param name="dto">Satıcı bilgileri</param>
    /// <returns>Oluşturulan satıcı</returns>
    [HttpPost]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<ActionResult<ApiResponse<VendorDto>>> CreateVendor(CreateVendorDto dto)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new ApiResponse<VendorDto>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        var vendor = new Vendor
        {
            Name = dto.Name,
            ImageUrl = dto.ImageUrl,
            Address = dto.Address,
            OwnerId = userId
        };

        await UnitOfWork.Vendors.AddAsync(vendor);
        await UnitOfWork.SaveChangesAsync();

        var vendorDto = new VendorDto
        {
            Id = vendor.Id,
            Name = vendor.Name,
            ImageUrl = vendor.ImageUrl,
            Address = vendor.Address,
            City = vendor.City,
            Rating = vendor.Rating,
            RatingCount = vendor.RatingCount,
            DeliveryRadiusInKm = vendor.DeliveryRadiusInKm
        };

        return CreatedAtAction(
            nameof(GetVendors),
            new { id = vendor.Id },
            new ApiResponse<VendorDto>(
                vendorDto,
                LocalizationService.GetLocalizedString(ResourceName, "VendorCreatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir satıcının ürünlerini getirir
    /// </summary>
    /// <param name="id">Satıcı ID'si</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("{id}/products")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetProductsByVendor(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Vendor'ın aktif olup olmadığını kontrol et
        var vendor = await UnitOfWork.Vendors.Query()
            .Where(v => v.Id == id)
            .FirstOrDefaultAsync();

        if (vendor == null || !vendor.IsActive)
        {
            // Vendor bulunamadı veya pasif ise boş liste döndür
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
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundOrInactive", CurrentCulture)));
        }

        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Where(p => p.VendorId == id);

        IOrderedQueryable<Product> orderedQuery = query.OrderByDescending(p => p.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
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
            LocalizationService.GetLocalizedString(ResourceName, "VendorProductsRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Tüm ürünleri getirir (Debug endpoint)
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("debug/products")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetAllProducts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        IQueryable<Product> query = UnitOfWork.Products.Query();

        IOrderedQueryable<Product> orderedQuery = query.OrderByDescending(p => p.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
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
            LocalizationService.GetLocalizedString(ResourceName, "AllProductsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcıları arama ve filtreleme ile getirir
    /// </summary>
    /// <param name="request">Arama ve filtreleme parametreleri</param>
    /// <returns>Sayfalanmış satıcı listesi</returns>
    [HttpGet("search")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorDto>>>> Search(
        [FromQuery] VendorSearchRequestDto request)
    {
        IQueryable<Vendor> query = UnitOfWork.Vendors.Query()
            .Include(v => v.Orders);

        // IsActive filtresi - Sadece aktif vendor'ları getir
        query = query.Where(v => v.IsActive);

        // Text search - Case-insensitive search helper kullanımı
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            query = query.WhereContainsIgnoreCase(v => v.Name, request.Query);
            query = query.WhereContainsIgnoreCase(v => v.Address, request.Query);
        }

        // VendorType filter
        if (request.VendorType.HasValue)
        {
            query = query.Where(v => v.Type == request.VendorType.Value);
        }

        // City filter
        if (!string.IsNullOrWhiteSpace(request.City))
        {
            query = query.Where(v => v.City == request.City);
        }

        // Rating filter
        if (request.MinRating.HasValue)
        {
            query = query.Where(v => v.Rating.HasValue && v.Rating >= request.MinRating.Value);
        }

        // Distance filter (REQUIRED: user location must be provided)
        if (!request.UserLatitude.HasValue || !request.UserLongitude.HasValue)
        {
            // Kullanıcı konumu zorunlu - gönderilmediyse boş liste döndür
            var emptyResult = new PagedResultDto<VendorDto>
            {
                Items = new List<VendorDto>(),
                TotalCount = 0,
                Page = request.Page,
                PageSize = request.PageSize,
                TotalPages = 0
            };

            return Ok(new ApiResponse<PagedResultDto<VendorDto>>(
                emptyResult,
                LocalizationService.GetLocalizedString(ResourceName, "UserLocationRequiredForVendorSearch", CurrentCulture)));
        }

            var userLat = request.UserLatitude.Value;
            var userLon = request.UserLongitude.Value;

        // Filter: Is the user within the vendor's delivery radius?
        // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
        // Sadece yarıçap içindeki vendor'ları göster, dışındakileri gösterme
            query = query.Where(v => v.Latitude.HasValue && v.Longitude.HasValue &&
                                     GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value,
                                     v.Longitude!.Value) <= (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm));

            // Optional secondary filter: User's own max distance preference
            if (request.MaxDistanceInKm.HasValue)
            {
                var maxDistance = request.MaxDistanceInKm.Value;
            query = query.Where(v => GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value,
                                             v.Longitude!.Value) <= maxDistance);
        }

        // Sorting
        IOrderedQueryable<Vendor> orderedQuery = request.SortBy?.ToLower() switch
        {
            "name" => query.OrderBy(v => v.Name),
            "newest" => query.OrderByDescending(v => v.CreatedAt),
            "rating_desc" => query.OrderByDescending(v => v.Rating ?? 0),
            "popularity" => query.OrderByDescending(v => v.Orders.Count),
            "distance" when request.UserLatitude.HasValue && request.UserLongitude.HasValue =>
                query.OrderBy(v => v.Latitude.HasValue && v.Longitude.HasValue
                    ? GeoHelper.CalculateDistance(request.UserLatitude!.Value, request.UserLongitude!.Value,
                        v.Latitude!.Value, v.Longitude!.Value)
                    : double.MaxValue),
            _ => query.OrderBy(v => v.Name)
        };

        // Pagination - Gelişmiş query helper kullanımı
        var vendors = await orderedQuery
            .Paginate(request.Page, request.PageSize)
            .ToListAsync();

        // Calculate distance and map to DTOs
        var items = vendors.Select(v =>
        {
            var dto = new VendorDto
            {
                Id = v.Id,
                Type = v.Type,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Address = v.Address,
                City = v.City,
                Rating = v.Rating,
                RatingCount = v.RatingCount,
                // DeliveryRadiusInKm = 0 ise, 5 km olarak göster (default)
                DeliveryRadiusInKm = v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm,
                Latitude = v.Latitude,
                Longitude = v.Longitude
            };

            // Calculate distance if user location provided
            if (request.UserLatitude.HasValue && request.UserLongitude.HasValue &&
                v.Latitude.HasValue && v.Longitude.HasValue)
            {
                dto.DistanceInKm = GeoHelper.CalculateDistance(
                    request.UserLatitude.Value,
                    request.UserLongitude.Value,
                    v.Latitude.Value,
                    v.Longitude.Value);
            }

            return dto;
        }).ToList();

        // Total count hesapla
        var totalCount = await query.CountAsync();

        var result = new PagedResultDto<VendorDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize)
        };

        return Ok(new ApiResponse<PagedResultDto<VendorDto>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "VendorSearchResultsRetrievedSuccessfully",
                CurrentCulture)));
    }


    /// <summary>
    /// Satıcıların bulunduğu şehirleri getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış şehir listesi</returns>
    [HttpGet("cities")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<string>>>> GetCities(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Cache key: cities_all (tüm şehirler cache'lenir, pagination memory'de yapılır)
        var cacheKey = $"{_cacheOptions.CitiesKeyPrefix}_all";

        // Cache-aside pattern: Önce cache'den kontrol et
        var allCities = await _cacheService.GetOrSetAsync(
            cacheKey,
            async () =>
            {
                return await UnitOfWork.Vendors.Query()
                    .Where(v => v.IsActive && v.City != null)
                    .Select(v => v.City!)
                    .Distinct()
                    .OrderBy(c => c)
                    .ToListAsync();
            },
            _cacheOptions.CitiesCacheTTLMinutes
        );

        // Pagination (memory'de - tüm şehirler zaten cache'de)
        var totalCount = allCities.Count;
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        var pagedItems = allCities
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        var result = new PagedResultDto<string>
        {
            Items = pagedItems,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = totalPages
        };

        return Ok(new ApiResponse<PagedResultDto<string>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "CitiesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı adları için otomatik tamamlama sonuçları getirir
    /// </summary>
    /// <param name="query">Arama sorgusu</param>
    /// <returns>Otomatik tamamlama sonuçları</returns>
    [HttpGet("autocomplete")]
    public async Task<ActionResult<ApiResponse<List<AutocompleteResultDto>>>> Autocomplete(
        [FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(
                new List<AutocompleteResultDto>(),
                LocalizationService.GetLocalizedString(ResourceName, "EmptyQuery", CurrentCulture)));
        }

        var results = await UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Name.Contains(query))
            .Take(10)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                Type = "vendor"
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AutocompleteResultDto>>(
            results,
            LocalizationService.GetLocalizedString(ResourceName, "AutocompleteResultsRetrievedSuccessfully",
                CurrentCulture)));
    }
}

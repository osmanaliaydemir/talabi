using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class VendorsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// VendorsController constructor
    /// </summary>
    public VendorsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Tüm satıcıları getirir
    /// </summary>
    /// <param name="vendorType">Satıcı türü filtresi (opsiyonel)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış satıcı listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorDto>>>> GetVendors([FromQuery] Talabi.Core.Enums.VendorType? vendorType = null,
        [FromQuery] int page = 1, [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        IQueryable<Vendor> query = _unitOfWork.Vendors.Query();

        // IsActive filtresi - Sadece aktif vendor'ları getir
        query = query.Where(v => v.IsActive);

        // VendorType filtresi
        if (vendorType.HasValue)
        {
            query = query.Where(v => v.Type == vendorType.Value);
        }

        IOrderedQueryable<Vendor> orderedQuery = query.OrderBy(v => v.Name);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            v => new VendorDto
            {
                Id = v.Id,
                Type = v.Type,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Address = v.Address,
                City = v.City,
                Rating = v.Rating,
                RatingCount = v.RatingCount,
                Latitude = v.Latitude.HasValue ? (double)v.Latitude.Value : null,
                Longitude = v.Longitude.HasValue ? (double)v.Longitude.Value : null
            },
            page,
            pageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<VendorDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<VendorDto>>(result, "Satıcılar başarıyla getirildi"));
    }

    /// <summary>
    /// Yeni satıcı oluşturur
    /// </summary>
    /// <param name="dto">Satıcı bilgileri</param>
    /// <returns>Oluşturulan satıcı</returns>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<VendorDto>>> CreateVendor(CreateVendorDto dto)
    {
        var vendor = new Vendor
        {
            Name = dto.Name,
            ImageUrl = dto.ImageUrl,
            Address = dto.Address,
            OwnerId = "temp-user-id" // TODO: Get from User.Identity
        };

        await _unitOfWork.Vendors.AddAsync(vendor);
        await _unitOfWork.SaveChangesAsync();

        var vendorDto = new VendorDto
        {
            Id = vendor.Id,
            Name = vendor.Name,
            ImageUrl = vendor.ImageUrl,
            Address = vendor.Address,
            City = vendor.City,
            Rating = vendor.Rating,
            RatingCount = vendor.RatingCount
        };

        return CreatedAtAction(
            nameof(GetVendors),
            new { id = vendor.Id },
            new ApiResponse<VendorDto>(vendorDto, "Satıcı başarıyla oluşturuldu"));
    }

    /// <summary>
    /// Belirli bir satıcının ürünlerini getirir
    /// </summary>
    /// <param name="id">Satıcı ID'si</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("{id}/products")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetProductsByVendor(Guid id, [FromQuery] int page = 1, [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        // Vendor'ın aktif olup olmadığını kontrol et
        var vendor = await _unitOfWork.Vendors.Query()
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
            return Ok(new ApiResponse<PagedResultDto<ProductDto>>(emptyResult, "Satıcı bulunamadı veya pasif durumda"));
        }

        IQueryable<Product> query = _unitOfWork.Products.Query()
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

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result, "Satıcı ürünleri başarıyla getirildi"));
    }

    /// <summary>
    /// Tüm ürünleri getirir (Debug endpoint)
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet("debug/products")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetAllProducts([FromQuery] int page = 1, [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        IQueryable<Product> query = _unitOfWork.Products.Query();

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

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result, "Tüm ürünler başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcıları arama ve filtreleme ile getirir
    /// </summary>
    /// <param name="request">Arama ve filtreleme parametreleri</param>
    /// <returns>Sayfalanmış satıcı listesi</returns>
    [HttpGet("search")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorDto>>>> Search([FromQuery] VendorSearchRequestDto request)
    {
        IQueryable<Vendor> query = _unitOfWork.Vendors.Query()
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

        // Distance filter (if user location provided)
        if (request.UserLatitude.HasValue && request.UserLongitude.HasValue && request.MaxDistanceInKm.HasValue)
        {
            var userLat = request.UserLatitude.Value;
            var userLon = request.UserLongitude.Value;
            var maxDistance = request.MaxDistanceInKm.Value;

            query = query.Where(v => v.Latitude.HasValue && v.Longitude.HasValue &&
                CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <= maxDistance);
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
                    ? CalculateDistance(request.UserLatitude!.Value, request.UserLongitude!.Value,
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
                Latitude = v.Latitude,
                Longitude = v.Longitude
            };

            // Calculate distance if user location provided
            if (request.UserLatitude.HasValue && request.UserLongitude.HasValue &&
                v.Latitude.HasValue && v.Longitude.HasValue)
            {
                dto.DistanceInKm = CalculateDistance(
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

        return Ok(new ApiResponse<PagedResultDto<VendorDto>>(result, "Satıcı arama sonuçları başarıyla getirildi"));
    }

    // Haversine formula to calculate distance between two coordinates in kilometers
    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusKm = 6371.0;

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return earthRadiusKm * c;
    }

    private static double ToRadians(double degrees)
    {
        return degrees * Math.PI / 180.0;
    }

    /// <summary>
    /// Satıcıların bulunduğu şehirleri getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış şehir listesi</returns>
    [HttpGet("cities")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<string>>>> GetCities([FromQuery] int page = 1, [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        var cities = await _unitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.City != null)
            .Select(v => v.City!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        // Pagination
        var totalCount = cities.Count;
        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        var pagedItems = cities
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

        return Ok(new ApiResponse<PagedResultDto<string>>(result, "Şehirler başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcı adları için otomatik tamamlama sonuçları getirir
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

        var results = await _unitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Name.Contains(query))
            .Take(10)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                Type = "vendor"
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AutocompleteResultDto>>(results, "Otomatik tamamlama sonuçları başarıyla getirildi"));
    }
}

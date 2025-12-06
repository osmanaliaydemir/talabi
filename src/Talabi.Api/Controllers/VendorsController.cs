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
    /// <returns>Satıcı listesi</returns>
    /// <summary>
    /// Tüm satıcıları getirir
    /// </summary>
    /// <param name="vendorType">Satıcı türü filtresi (opsiyonel)</param>
    /// <returns>Satıcı listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<VendorDto>>>> GetVendors([FromQuery] Talabi.Core.Enums.VendorType? vendorType = null)
    {
        IQueryable<Vendor> query = _unitOfWork.Vendors.Query();

        // VendorType filtresi
        if (vendorType.HasValue)
        {
            query = query.Where(v => v.Type == vendorType.Value);
        }

        var vendors = await query
            .Select(v => new VendorDto
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
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<VendorDto>>(vendors, "Satıcılar başarıyla getirildi"));
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
    /// <returns>Ürün listesi</returns>
    [HttpGet("{id}/products")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetProductsByVendor(Guid id)
    {
        var products = await _unitOfWork.Products.Query()
            .Where(p => p.VendorId == id)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<ProductDto>>(products, "Satıcı ürünleri başarıyla getirildi"));
    }

    /// <summary>
    /// Tüm ürünleri getirir (Debug endpoint)
    /// </summary>
    /// <returns>Ürün listesi</returns>
    [HttpGet("debug/products")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetAllProducts()
    {
        var products = await _unitOfWork.Products.Query()
            .Select(p => new ProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<ProductDto>>(products, "Tüm ürünler başarıyla getirildi"));
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
    /// <returns>Şehir listesi</returns>
    [HttpGet("cities")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetCities()
    {
        var cities = await _unitOfWork.Vendors.Query()
            .Where(v => v.City != null)
            .Select(v => v.City!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        return Ok(new ApiResponse<List<string>>(cities, "Şehirler başarıyla getirildi"));
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
            .Where(v => v.Name.Contains(query))
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

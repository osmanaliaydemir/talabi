using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class VendorsController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public VendorsController(TalabiDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<VendorDto>>> GetVendors()
    {
        return await _context.Vendors
            .Select(v => new VendorDto
            {
                Id = v.Id,
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
    }

    [HttpPost]
    public async Task<ActionResult<VendorDto>> CreateVendor(CreateVendorDto dto)
    {
        var vendor = new Vendor
        {
            Name = dto.Name,
            ImageUrl = dto.ImageUrl,
            Address = dto.Address,
            OwnerId = "temp-user-id" // TODO: Get from User.Identity
        };

        _context.Vendors.Add(vendor);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetVendors), new { id = vendor.Id }, new VendorDto
        {
            Id = vendor.Id,
            Name = vendor.Name,
            ImageUrl = vendor.ImageUrl,
            Address = vendor.Address,
            City = vendor.City,
            Rating = vendor.Rating,
            RatingCount = vendor.RatingCount
        });
    }

    [HttpGet("{id}/products")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProductsByVendor(Guid id)
    {
        var products = await _context.Products
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

        return Ok(products);
    }

    [HttpGet("debug/products")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAllProducts()
    {
        var products = await _context.Products
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

        return Ok(products);
    }

    [HttpGet("search")]
    public async Task<ActionResult<PagedResultDto<VendorDto>>> Search([FromQuery] VendorSearchRequestDto request)
    {
        var query = _context.Vendors
            .Include(v => v.Orders)
            .AsQueryable();

        // Text search
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            query = query.Where(v => v.Name.Contains(request.Query) ||
                                    v.Address.Contains(request.Query));
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

        // Get total count before pagination
        var totalCount = await query.CountAsync();

        // Sorting
        query = request.SortBy?.ToLower() switch
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

        // Get vendors with order count for popularity
        var vendors = await query
            .Skip((request.Page - 1) * request.PageSize)
            .Take(request.PageSize)
            .ToListAsync();

        // Calculate distance and map to DTOs
        var items = vendors.Select(v =>
        {
            var dto = new VendorDto
            {
                Id = v.Id,
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

        return Ok(new PagedResultDto<VendorDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = request.Page,
            PageSize = request.PageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize)
        });
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

    [HttpGet("cities")]
    public async Task<ActionResult<List<string>>> GetCities()
    {
        var cities = await _context.Vendors
            .Where(v => v.City != null)
            .Select(v => v.City!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        return Ok(cities);
    }

    [HttpGet("autocomplete")]
    public async Task<ActionResult<List<AutocompleteResultDto>>> Autocomplete([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new List<AutocompleteResultDto>());
        }

        var results = await _context.Vendors
            .Where(v => v.Name.Contains(query))
            .Take(10)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                Type = "vendor"
            })
            .ToListAsync();

        return Ok(results);
    }
}

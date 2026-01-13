using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Core.Helpers;
using Talabi.Core.Entities;

namespace Talabi.Api.Controllers;

/// <summary>
/// Arama işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class SearchController : BaseController
{
    private const string ResourceName = "SearchResources";

    /// <summary>
    /// SearchController constructor
    /// </summary>
    public SearchController(
        IUnitOfWork unitOfWork,
        ILogger<SearchController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Ürün ve satıcılar için otomatik tamamlama sonuçları getirir (5 km yarıçap filtresi ile)
    /// </summary>
    /// <param name="query">Arama sorgusu</param>
    /// <param name="userLatitude">Kullanıcı enlemi (latitude) - 5 km yarıçap filtresi için</param>
    /// <param name="userLongitude">Kullanıcı boylamı (longitude) - 5 km yarıçap filtresi için</param>
    /// <returns>Otomatik tamamlama sonuçları</returns>
    [HttpGet("autocomplete")]
    public async Task<ActionResult<ApiResponse<List<AutocompleteResultDto>>>> Autocomplete(
        [FromQuery] string query,
        [FromQuery] double? userLatitude = null,
        [FromQuery] double? userLongitude = null)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Ok(new ApiResponse<List<AutocompleteResultDto>>(
                new List<AutocompleteResultDto>(),
                LocalizationService.GetLocalizedString(ResourceName, "EmptyQuery", CurrentCulture)));
        }

        // Query is sanitized by InputSanitizationActionFilter
        // Entity Framework uses parameterized queries, so SQL injection is protected
        // For XSS protection, the filter sanitizes HTML tags from the query
        var searchQuery = query.Trim();

        IQueryable<Product> productBaseQuery = UnitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.Name.Contains(searchQuery) && (p.Vendor == null || p.Vendor.IsActive));

        IQueryable<Vendor> vendorBaseQuery = UnitOfWork.Vendors.Query()
            .Where(v => v.IsActive && v.Name.Contains(searchQuery));

        // Apply radius filter if user location is provided
        if (userLatitude.HasValue && userLongitude.HasValue)
        {
            var userLat = userLatitude.Value;
            var userLon = userLongitude.Value;

            var allVendors = await UnitOfWork.Vendors.Query()
                .Where(v => v.IsActive && v.Latitude.HasValue && v.Longitude.HasValue)
                .ToListAsync();

            var vendorsInRadius = allVendors
                .Where(v => GeoHelper.CalculateDistance(userLat, userLon, v.Latitude!.Value, v.Longitude!.Value) <=
                           (v.DeliveryRadiusInKm == 0 ? 5 : v.DeliveryRadiusInKm))
                .Select(v => v.Id)
                .ToList();

            if (!vendorsInRadius.Any())
            {
                // No vendors in radius, return empty results for both products and vendors
                return Ok(new ApiResponse<List<AutocompleteResultDto>>(
                    new List<AutocompleteResultDto>(),
                    LocalizationService.GetLocalizedString(ResourceName, "NoVendorsInDeliveryRadius", CurrentCulture)));
            }

            productBaseQuery = productBaseQuery.Where(p => vendorsInRadius.Contains(p.VendorId));
            vendorBaseQuery = vendorBaseQuery.Where(v => vendorsInRadius.Contains(v.Id));
        }

        var productResults = await productBaseQuery
            .Take(5)
            .Select(p => new AutocompleteResultDto
            {
                Id = p.Id,
                Name = p.Name,
                ImageUrl = p.ImageUrl,
                Type = "product"
            })
            .ToListAsync();

        var vendorResults = await vendorBaseQuery
            .Take(5)
            .Select(v => new AutocompleteResultDto
            {
                Id = v.Id,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Type = "vendor"
            })
            .ToListAsync();

        var combined = productResults.Concat(vendorResults).ToList();
        return Ok(new ApiResponse<List<AutocompleteResultDto>>(
            combined,
            LocalizationService.GetLocalizedString(ResourceName, "AutocompleteResultsRetrievedSuccessfully",
                CurrentCulture)));
    }
}

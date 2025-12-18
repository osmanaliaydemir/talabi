using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using System.Globalization;

namespace Talabi.Api.Controllers;

[Route("api/vendor/delivery-zones")]
[ApiController]
[Authorize]
public class VendorDeliveryZoneController : BaseController
{
    private const string ResourceName = "VendorDeliveryZoneResources";
    private readonly ILocationService _locationService;

    public VendorDeliveryZoneController(
        IUnitOfWork unitOfWork,
        ILogger<VendorDeliveryZoneController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        ILocationService locationService)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _locationService = locationService;
    }

    /// <summary>
    /// gets delivery zones hierarchy. If CityId is null, returns list of cities.
    /// If CityId is provided, returns Districts and Localities for that city with selection state.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<object>>> GetZones([FromQuery] Guid? cityId)
    {
        var userId = UserContext.GetUserId();
        if (userId == null) return Unauthorized(new ApiResponse<object>(LocalizationService.GetLocalizedString("ErrorResources", "Unauthorized", CurrentCulture), "UNAUTHORIZED"));

        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null) return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString("VendorProfileResources", "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));

        // 1. If no city selected, return list of cities
        if (cityId == null)
        {
            var cities = await _locationService.GetCitiesAsync();
            return Ok(new ApiResponse<List<LocationItemDto>>(cities, LocalizationService.GetLocalizedString(ResourceName, "CitiesRetrievedSuccessfully", CurrentCulture)));
        }

        // 2. If city selected, get hierarchy and active zones
        var city = (await _locationService.GetCitiesAsync()).FirstOrDefault(c => c.Id == cityId);
        if (city == null) return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CityNotFound", CurrentCulture), "CITY_NOT_FOUND"));

        // Get Hierarchy
        var districtHierarchy = await _locationService.GetDistrictsWithLocalitiesAsync(cityId.Value);

        // Get Vendor's Active Localities for this City
        // Note: We filter by CityId to optimize, assuming CityId is populated in Entity. 
        // If not, we might need to filter by District.CityId via Join, but Entity has CityId.
        var activeLocalityIds = await UnitOfWork.VendorDeliveryZones.Query()
            .Where(z => z.VendorId == vendor.Id && z.CityId == cityId.Value && z.IsActive && z.LocalityId.HasValue)
            .Select(z => z.LocalityId.Value)
            .ToListAsync();

        var activeLocalitySet = new HashSet<Guid>(activeLocalityIds);

        // Map to Response DTO
        var response = new CityZoneDto
        {
            Id = city.Id,
            Name = city.Name,
            Districts = districtHierarchy.Select(d => new DistrictZoneDto
            {
                Id = d.Id,
                Name = d.Name,
                Localities = d.Localities.Select(l => new LocalityZoneDto
                {
                    Id = l.Id,
                    Name = l.Name,
                    IsSelected = activeLocalitySet.Contains(l.Id)
                }).ToList()
            }).ToList()
        };

        return Ok(new ApiResponse<CityZoneDto>(response, LocalizationService.GetLocalizedString(ResourceName, "ZonesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Syncs delivery zones for a specific city.
    /// Replaces all zones for the city with the provided list.
    /// </summary>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> SyncZones([FromBody] DeliveryZoneSyncDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null) return Unauthorized(new ApiResponse<object>(LocalizationService.GetLocalizedString("ErrorResources", "Unauthorized", CurrentCulture), "UNAUTHORIZED"));

        if (dto.CityId == Guid.Empty) return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidCityId", CurrentCulture), "INVALID_CITY_ID"));

        // Transactional Sync
        await UnitOfWork.BeginTransactionAsync();
        try
        {
            var vendor = await UnitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId);

            if (vendor == null) return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString("VendorProfileResources", "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));

            // 1. Delete Existing Zones for this City
            // "Nuclear Option" per CityScope
            await UnitOfWork.VendorDeliveryZones.ExecuteDeleteAsync(z => z.VendorId == vendor.Id && z.CityId == dto.CityId);

            // 2. Insert New Zones
            if (dto.LocalityIds != null && dto.LocalityIds.Any())
            {
                // We need DistrictIds for these Localities
                // This query requires accessing the Context or a Repository method.
                // Using Query() on Localities if available in UnitOfWork? UnitOfWork doesn't explicitly expose Localities Repo in Interface based on my cache, 
                // but checking IUnitOfWork file...

                // WAIT: IUnitOfWork.cs line 46: DbSet<Locality> Localities { get; set; } ?
                // Checking IUnitOfWork.cs content I read earlier...
                // IUnitOfWork only lists Repositories for specific entities. 
                // Line 46 in IUnitOfWork.cs (read in Step 1611) shows Carts, CartItems...
                // Line 162: VendorWorkingHours.
                // I don't see `Localities` in `IUnitOfWork`.
                // However, `ILocationService` uses `_dbContext.Localities`.
                // I cannot access `_dbContext` here nicely.
                // I should use `ILocationService`? No, that returns DTOs.
                // I need to fetch DistrictIds.

                // OPTION: Assuming IUnitOfWork has a generic accessor or I can cast repository?
                // Or maybe `UnitOfWork.Localities` exists but wasn't in the snippet I saw?
                // Let's re-read IUnitOfWork to be absolutely sure.
                // If not, I'll use `VendorDeliveryZones` repository (generic) if I can, but I need `Locality` table.

                // Workaround: Use `locationService` to get districts/localities map again? 
                // `GetDistrictsWithLocalitiesAsync` returns hierarchy. I can flatten it to find DistrictId for LocalityId.
                // This avoids direct DB access for Localities in Controller.

                var districtHierarchy = await _locationService.GetDistrictsWithLocalitiesAsync(dto.CityId);
                var localityDistrictMap = new Dictionary<Guid, Guid>();
                foreach (var d in districtHierarchy)
                {
                    foreach (var l in d.Localities)
                    {
                        localityDistrictMap[l.Id] = d.Id;
                    }
                }

                var newZones = new List<VendorDeliveryZone>();
                foreach (var locId in dto.LocalityIds)
                {
                    if (localityDistrictMap.TryGetValue(locId, out var distId))
                    {
                        newZones.Add(new VendorDeliveryZone
                        {
                            VendorId = vendor.Id,
                            CityId = dto.CityId,
                            DistrictId = distId,
                            LocalityId = locId,
                            DeliveryFee = dto.DeliveryFee,
                            MinimumOrderAmount = dto.MinimumOrderAmount,
                            IsActive = true
                        });
                    }
                }

                if (newZones.Any())
                {
                    await UnitOfWork.VendorDeliveryZones.AddRangeAsync(newZones);
                }
            }

            await UnitOfWork.SaveChangesAsync();
            await UnitOfWork.CommitTransactionAsync();

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "ZonesUpdatedSuccessfully", CurrentCulture)));
        }
        catch (Exception)
        {
            await UnitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
}

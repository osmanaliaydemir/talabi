using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class DeliveryZoneService : IDeliveryZoneService
{
    private readonly TalabiDbContext _dbContext;
    private readonly IUserContextService _userContextService;

    public DeliveryZoneService(TalabiDbContext dbContext, IUserContextService userContextService)
    {
        _dbContext = dbContext;
        _userContextService = userContextService;
    }

    private async Task<Guid?> GetVendorIdAsync(CancellationToken ct)
    {
        var userId = _userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return null;

        var vendor = await _dbContext.Vendors
            .Select(v => new { v.Id, v.OwnerId })
            .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

        return vendor?.Id;
    }
    
    private string GetLocalizedName(dynamic entity)
    {
        if (entity == null) return "-";
        var lang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
        return lang switch
        {
            "tr" => entity.NameTr,
            "en" => !string.IsNullOrEmpty(entity.NameEn) ? entity.NameEn : entity.NameTr,
            "ar" => !string.IsNullOrEmpty(entity.NameAr) ? entity.NameAr : entity.NameTr,
            _ => entity.NameTr
        };
    }

    public async Task<List<VendorDeliveryZoneDto>> GetVendorZonesAsync(CancellationToken ct = default)
    {
        var vendorId = await GetVendorIdAsync(ct);
        if (vendorId == null) return new List<VendorDeliveryZoneDto>();

        var zones = await _dbContext.VendorDeliveryZones
            .Include(z => z.District).ThenInclude(d => d.City)
            .Include(z => z.Locality)
            .Where(z => z.VendorId == vendorId.Value && z.IsActive)
            .ToListAsync(ct);

        return zones.Select(z => new VendorDeliveryZoneDto
            {
                Id = z.Id,
                LocalityId = z.LocalityId,
                CityName = z.District?.City != null ? GetLocalizedName(z.District.City) : "-",
                DistrictName = z.District != null ? GetLocalizedName(z.District) : "-",
                LocalityName = z.Locality != null ? GetLocalizedName(z.Locality) : "-",
                DeliveryFee = z.DeliveryFee,
                MinimumOrderAmount = z.MinimumOrderAmount,
                IsActive = z.IsActive
            })
            .OrderBy(z => z.CityName)
            .ThenBy(z => z.DistrictName)
            .ToList();
    }

    public async Task AddZonesAsync(CreateDeliveryZoneViewModel model, CancellationToken ct = default)
    {
        var vendorId = await GetVendorIdAsync(ct);
        if (vendorId == null) return;

        // If no localities selected, check if districts selected (backward compatibility or UI helper failed)
        // If districts selected but no localities, we might want to fetch all localities for those districts.
        // For now, let's assume UI sends SelectedLocalities.
        
        if (model.SelectedLocalities == null || !model.SelectedLocalities.Any())
        {
             // Fallback: If legacy SelectedDistricts present, maybe fetch all localities for them?
             // But user wants Locality persistence. Let's do explicit check.
             if (model.SelectedDistricts != null && model.SelectedDistricts.Any())
             {
                 var localitiesInDistricts = await _dbContext.Localities
                    .Where(l => model.SelectedDistricts.Contains(l.DistrictId))
                    .Select(l => l.Id)
                    .ToListAsync(ct);
                    
                 model.SelectedLocalities = localitiesInDistricts;
             }
        }

        if (model.SelectedLocalities == null || !model.SelectedLocalities.Any()) return;

        // Fetch Localities to get DistrictId and check existence
        var localitiesToAdd = await _dbContext.Localities
            .Where(l => model.SelectedLocalities.Contains(l.Id))
            .ToListAsync(ct);

        var existingZoneLocalityIds = await _dbContext.VendorDeliveryZones
            .Where(z => z.VendorId == vendorId.Value && z.IsActive && z.LocalityId.HasValue)
            .Select(z => z.LocalityId.Value)
            .ToListAsync(ct);

        var newZones = new List<VendorDeliveryZone>();

        foreach (var locality in localitiesToAdd)
        {
            if (existingZoneLocalityIds.Contains(locality.Id)) continue; 

            newZones.Add(new VendorDeliveryZone
            {
                VendorId = vendorId.Value,
                CityId = model.CityId, // Or locality.District.CityId if we include it
                DistrictId = locality.DistrictId,
                LocalityId = locality.Id,
                DeliveryFee = model.DeliveryFee,
                MinimumOrderAmount = model.MinimumOrderAmount,
                IsActive = true
            });
        }

        if (newZones.Any())
        {
            await _dbContext.VendorDeliveryZones.AddRangeAsync(newZones, ct);
            await _dbContext.SaveChangesAsync(ct);
        }
    }

    public async Task<bool> DeleteZoneAsync(Guid id, CancellationToken ct = default)
    {
        var vendorId = await GetVendorIdAsync(ct);
        if (vendorId == null) return false;

        var zone = await _dbContext.VendorDeliveryZones
            .FirstOrDefaultAsync(z => z.Id == id && z.VendorId == vendorId.Value, ct);

        if (zone == null) return false;

        _dbContext.VendorDeliveryZones.Remove(zone);
        await _dbContext.SaveChangesAsync(ct);
        return true;
    }

    public async Task<bool> UpdateZoneAsync(VendorDeliveryZoneDto dto, CancellationToken ct = default)
    {
        var vendorId = await GetVendorIdAsync(ct);
        if (vendorId == null) return false;

        var zone = await _dbContext.VendorDeliveryZones
            .FirstOrDefaultAsync(z => z.Id == dto.Id && z.VendorId == vendorId.Value, ct);

        if (zone == null) return false;

        zone.DeliveryFee = dto.DeliveryFee;
        zone.MinimumOrderAmount = dto.MinimumOrderAmount;
        
        await _dbContext.SaveChangesAsync(ct);
        return true;
    }
}

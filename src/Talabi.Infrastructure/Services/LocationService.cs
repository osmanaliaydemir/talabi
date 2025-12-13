using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class LocationService : ILocationService
{
    private readonly TalabiDbContext _dbContext;

    public LocationService(TalabiDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    private string GetLocalizedName(dynamic entity)
    {
        var lang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
        return lang switch
        {
            "tr" => entity.NameTr,
            "en" => !string.IsNullOrEmpty(entity.NameEn) ? entity.NameEn : entity.NameTr,
            "ar" => !string.IsNullOrEmpty(entity.NameAr) ? entity.NameAr : entity.NameTr,
            _ => entity.NameTr
        };
    }

    public async Task<List<LocationItemDto>> GetCountriesAsync()
    {
        var countries = await _dbContext.Countries.ToListAsync();
        return countries.Select(c => new LocationItemDto
        {
            Id = c.Id,
            Name = GetLocalizedName(c)
        }).OrderBy(x => x.Name).ToList();
    }

    public async Task<List<LocationItemDto>> GetCitiesAsync(Guid? countryId = null)
    {
        var query = _dbContext.Cities.Include(c => c.Country).AsQueryable();
        
        if (countryId.HasValue)
        {
            query = query.Where(c => c.CountryId == countryId.Value);
        }

        var cities = await query.ToListAsync();
        return cities.Select(c => new LocationItemDto
        {
            Id = c.Id,
            Name = GetLocalizedName(c)
        }).OrderBy(x => x.Name).ToList();
    }

    public async Task<List<LocationItemDto>> GetDistrictsAsync(Guid cityId)
    {
        var districts = await _dbContext.Districts
            .Where(d => d.CityId == cityId)
            .ToListAsync();
            
        return districts.Select(d => new LocationItemDto
        {
            Id = d.Id,
            Name = GetLocalizedName(d)
        }).OrderBy(x => x.Name).ToList();
    }
    
    public async Task<List<LocationItemDto>> GetLocalitiesAsync(Guid districtId)
    {
        var localities = await _dbContext.Localities
            .Where(l => l.DistrictId == districtId)
            .ToListAsync();
            
        return localities.Select(l => new LocationItemDto
        {
            Id = l.Id,
            Name = GetLocalizedName(l)
        }).OrderBy(x => x.Name).ToList();
    }

    public async Task<List<DistrictWithLocalitiesDto>> GetDistrictsWithLocalitiesAsync(Guid cityId)
    {
        var districts = await _dbContext.Districts
            .Where(d => d.CityId == cityId)
            .Include(d => d.Localities)
            .ToListAsync();

        return districts.Select(d => new DistrictWithLocalitiesDto
        {
            Id = d.Id,
            Name = GetLocalizedName(d),
            Localities = d.Localities.Select(l => new LocationItemDto
            {
                Id = l.Id,
                Name = GetLocalizedName(l)
            }).OrderBy(x => x.Name).ToList()
        }).OrderBy(x => x.Name).ToList();
    }
}

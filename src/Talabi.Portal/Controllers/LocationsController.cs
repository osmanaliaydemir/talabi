using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Portal.Controllers;

[Authorize] // Should be [Authorize(Roles = "Admin")] but simplified for now per instructions
public class LocationsController : Controller
{
    private readonly TalabiDbContext _context;

    public LocationsController(TalabiDbContext context)
    {
        _context = context;
    }

    // --- COUNTRIES ---
    public async Task<IActionResult> Index()
    {
        return View(await _context.Countries.ToListAsync());
    }

    [HttpGet]
    public async Task<IActionResult> GetCountry(Guid id)
    {
        var country = await _context.Countries.FindAsync(id);
        if (country == null) return NotFound();
        return Json(country);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCountry(Country country)
    {
        if (ModelState.IsValid)
        {
            _context.Countries.Add(country);
            await _context.SaveChangesAsync();
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> EditCountry(Country country)
    {
        // Simple update logic
        var existing = await _context.Countries.FindAsync(country.Id);
        if (existing != null)
        {
            existing.NameTr = country.NameTr;
            existing.NameEn = country.NameEn;
            existing.NameAr = country.NameAr;
            existing.Code = country.Code;
            await _context.SaveChangesAsync();
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> DeleteCountry(Guid id)
    {
        var country = await _context.Countries.FindAsync(id);
        if (country != null)
        {
            _context.Countries.Remove(country);
            await _context.SaveChangesAsync();
        }
        return RedirectToAction(nameof(Index));
    }

    // --- CITIES ---
    public async Task<IActionResult> CountryDetails(Guid id)
    {
        var country = await _context.Countries
            .Include(c => c.Cities)
            .FirstOrDefaultAsync(c => c.Id == id);
            
        if (country == null) return NotFound();
        return View(country);
    }

    [HttpGet]
    public async Task<IActionResult> GetCity(Guid id)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city == null) return NotFound();
        return Json(city);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCity(City city)
    {
        _context.Cities.Add(city);
        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(CountryDetails), new { id = city.CountryId });
    }

    [HttpPost]
    public async Task<IActionResult> EditCity(City city)
    {
        var existing = await _context.Cities.FindAsync(city.Id);
        if (existing != null)
        {
            existing.NameTr = city.NameTr;
            existing.NameEn = city.NameEn;
            existing.NameAr = city.NameAr;
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(CountryDetails), new { id = existing.CountryId });
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> DeleteCity(Guid id)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city != null)
        {
            _context.Cities.Remove(city);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(CountryDetails), new { id = city.CountryId });
        }
        return RedirectToAction(nameof(Index));
    }

    // --- DISTRICTS ---
    public async Task<IActionResult> CityDetails(Guid id)
    {
        var city = await _context.Cities
            .Include(c => c.Country)
            .Include(c => c.Districts)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (city == null) return NotFound();
        return View(city);
    }

    [HttpGet]
    public async Task<IActionResult> GetDistrict(Guid id)
    {
        var district = await _context.Districts.FindAsync(id);
        if (district == null) return NotFound();
        return Json(district);
    }

    [HttpPost]
    public async Task<IActionResult> CreateDistrict(District district)
    {
        _context.Districts.Add(district);
        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(CityDetails), new { id = district.CityId });
    }

    [HttpPost]
    public async Task<IActionResult> EditDistrict(District district)
    {
        var existing = await _context.Districts.FindAsync(district.Id);
        if (existing != null)
        {
            existing.NameTr = district.NameTr;
            existing.NameEn = district.NameEn;
            existing.NameAr = district.NameAr;
            await _context.SaveChangesAsync();
             return RedirectToAction(nameof(CityDetails), new { id = existing.CityId });
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> DeleteDistrict(Guid id)
    {
        var district = await _context.Districts.FindAsync(id);
        if (district != null)
        {
            _context.Districts.Remove(district);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(CityDetails), new { id = district.CityId });
        }
        return RedirectToAction(nameof(Index));
    }

    // --- LOCALITIES ---
    public async Task<IActionResult> DistrictDetails(Guid id)
    {
        var district = await _context.Districts
            .Include(d => d.City).ThenInclude(c => c.Country) 
            .Include(d => d.Localities)
            .FirstOrDefaultAsync(d => d.Id == id);

        if (district == null) return NotFound();
        return View(district);
    }

    [HttpGet]
    public async Task<IActionResult> GetLocality(Guid id)
    {
        var locality = await _context.Localities.FindAsync(id);
        if (locality == null) return NotFound();
        return Json(locality);
    }

    [HttpPost]
    public async Task<IActionResult> CreateLocality(Locality locality)
    {
        _context.Localities.Add(locality);
        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(DistrictDetails), new { id = locality.DistrictId });
    }

     [HttpPost]
    public async Task<IActionResult> EditLocality(Locality locality)
    {
        var existing = await _context.Localities.FindAsync(locality.Id);
        if (existing != null)
        {
             existing.NameTr = locality.NameTr;
            existing.NameEn = locality.NameEn;
            existing.NameAr = locality.NameAr;
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(DistrictDetails), new { id = existing.DistrictId });
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> DeleteLocality(Guid id)
    {
        var locality = await _context.Localities.FindAsync(id);
        if (locality != null)
        {
            _context.Localities.Remove(locality);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(DistrictDetails), new { id = locality.DistrictId });
        }
        return RedirectToAction(nameof(Index));
    }
}

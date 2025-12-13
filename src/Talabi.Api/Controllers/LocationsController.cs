using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class LocationsController : ControllerBase
{
    private readonly ILocationService _locationService;

    public LocationsController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet("countries")]
    public async Task<IActionResult> GetCountries()
    {
        var countries = await _locationService.GetCountriesAsync();
        return Ok(countries);
    }

    [HttpGet("cities/{countryId}")]
    public async Task<IActionResult> GetCities(Guid countryId)
    {
        var cities = await _locationService.GetCitiesAsync(countryId);
        return Ok(cities);
    }

    [HttpGet("districts/{cityId}")]
    public async Task<IActionResult> GetDistricts(Guid cityId)
    {
        var districts = await _locationService.GetDistrictsAsync(cityId);
        return Ok(districts);
    }

    [HttpGet("localities/{districtId}")]
    public async Task<IActionResult> GetLocalities(Guid districtId)
    {
        var localities = await _locationService.GetLocalitiesAsync(districtId);
        return Ok(localities);
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Core.Interfaces;
using Talabi.Core.DTOs;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class DeliveryZonesController : Controller
{
    private readonly IDeliveryZoneService _deliveryZoneService;
    private readonly ILocationService _locationService;

    public DeliveryZonesController(IDeliveryZoneService deliveryZoneService, ILocationService locationService)
    {
        _deliveryZoneService = deliveryZoneService;
        _locationService = locationService;
    }

    public async Task<IActionResult> Index(Guid? cityId)
    {
        var cities = await _locationService.GetCitiesAsync();
        
        // Default to first city if not provided
        var selectedCityId = cityId ?? cities.FirstOrDefault()?.Id ?? Guid.Empty;
        
        var zones = await _deliveryZoneService.GetVendorZonesAsync();
        var availableDistricts = selectedCityId != Guid.Empty 
            ? await _locationService.GetDistrictsAsync(selectedCityId) 
            : new List<LocationItemDto>();

        var model = new DeliveryZonesViewModel
        {
            Zones = zones,
            SelectedCityId = selectedCityId,
            Cities = cities,
            AvailableDistricts = availableDistricts
        };

        return View(model);
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateDeliveryZoneViewModel model)
    {
        if (ModelState.IsValid)
        {
            await _deliveryZoneService.AddZonesAsync(model);
            return RedirectToAction(nameof(Index), new { cityId = model.CityId });
        }
        
        return RedirectToAction(nameof(Index), new { cityId = model.CityId });
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _deliveryZoneService.DeleteZoneAsync(id);
        return RedirectToAction(nameof(Index));
    }
}

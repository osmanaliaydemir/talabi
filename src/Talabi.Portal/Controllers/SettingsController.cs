using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class SettingsController : Controller
{
    private readonly ISettingsService _settingsService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<SettingsController> _logger;

    public SettingsController(
        ISettingsService settingsService,
        ILocalizationService localizationService,
        ILogger<SettingsController> logger)
    {
        _settingsService = settingsService;
        _localizationService = localizationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var vendorSettings = await _settingsService.GetVendorSettingsAsync();
        var systemSettings = await _settingsService.GetSystemSettingsAsync();

        var viewModel = new SettingsViewModel
        {
            Vendor = vendorSettings ?? new VendorSettingsDto(),
            System = systemSettings ?? new SystemSettingsDto()
        };

        return View(viewModel);
    }

    [HttpPost]
    public async Task<IActionResult> UpdateVendor([FromBody] VendorSettingsDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var success = await _settingsService.UpdateVendorSettingsAsync(dto);
        if (success)
            return Json(new { success = true, message = "Restoran ayarları güncellendi." });

        return Json(new { success = false, message = "Güncelleme başarısız." });
    }

    [HttpPost]
    public async Task<IActionResult> UpdateSystem([FromBody] SystemSettingsDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var success = await _settingsService.UpdateSystemSettingsAsync(dto);
        if (success)
            return Json(new { success = true, message = "Sistem ayarları güncellendi." });

        return Json(new { success = false, message = "Güncelleme başarısız." });
    }
}

using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin")]
public class SystemSettingsController : Controller
{
    private readonly ISystemSettingsService _settingsService;

    public SystemSettingsController(ISystemSettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var settings = await _settingsService.GetSettingsListAsync(ct);
        return Json(new { data = settings });
    }

    [HttpGet]
    public async Task<IActionResult> Get(string key, CancellationToken ct)
    {
        var value = await _settingsService.GetSettingAsync(key, ct);
        return Json(new { success = true, value });
    }
    
    [HttpGet]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        var all = await _settingsService.GetSettingsListAsync(ct);
        var setting = all.FirstOrDefault(s => s.Id == id);
        
        if (setting == null) return Json(new { success = false, message = "Not found" });
        return Json(new { success = true, data = setting });
    }

    [HttpPost]
    public async Task<IActionResult> Save([FromBody] SystemSetting setting, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return Json(new { success = false, message = "Invalid data" });

        await _settingsService.SaveSettingAsync(setting, ct);
        return Json(new { success = true });
    }

    [HttpPost]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        await _settingsService.DeleteSettingAsync(id, ct);
        return Json(new { success = true });
    }
}

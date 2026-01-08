using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

[ApiController]
[Route("api/system-settings")]
public class SystemSettingsController : BaseController
{
    private readonly ISystemSettingsService _settingsService;

    public SystemSettingsController(
        ISystemSettingsService settingsService,
        IUnitOfWork unitOfWork,
        ILogger<SystemSettingsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _settingsService = settingsService;
    }

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<Dictionary<string, string>>> GetSettings(CancellationToken ct)
    {
        var settings = await _settingsService.GetAllSettingsAsync(ct);
        return Ok(settings);
    }

    [HttpGet("{key}")]
    [AllowAnonymous]
    public async Task<ActionResult<string>> GetSetting(string key, [FromQuery] string? lang = null,
        CancellationToken ct = default)
    {
        var languageCode = GetLanguageFromRequest(lang);

        // Try localized key first (e.g. MyKey_tr)
        var localizedKey = $"{key}_{languageCode}";
        var value = await _settingsService.GetSettingAsync(localizedKey, ct);

        // Fallback to original key if localized not found
        if (value == null)
        {
            value = await _settingsService.GetSettingAsync(key, ct);
        }

        if (value == null) return NotFound();
        return Ok(new { key, value });
    }

    [HttpGet("version-check")]
    [AllowAnonymous]
    public async Task<ActionResult<MobileVersionSettingsDto>> GetVersionSettings(CancellationToken ct)
    {
        var allSettings = await _settingsService.GetSettingsListAsync(ct);
        var versionSettings = allSettings
            .Where(s => s.Group == "MobileAppForceUpdate")
            .ToDictionary(s => s.Key, s => s.Value);

        var dto = new MobileVersionSettingsDto
        {
            ForceUpdate = versionSettings.TryGetValue("ForceUpdate", out var force) &&
                          bool.TryParse(force, out var b) && b,
            MinVersionAndroid = versionSettings.GetValueOrDefault("MinVersionAndroid", "1.0.0"),
            MinVersionIOS = versionSettings.GetValueOrDefault("MinVersionIOS", "1.0.0"),
            Title_TR = versionSettings.GetValueOrDefault("ForceUpdate_TR_Title", "Güncelleme Mevcut"),
            Title_EN = versionSettings.GetValueOrDefault("ForceUpdate_EN_Title", "Update Available"),
            Title_AR = versionSettings.GetValueOrDefault("ForceUpdate_AR_Title", "تحديث متاح"),
            Body_TR =
                versionSettings.GetValueOrDefault("ForceUpdate_TR_Text", "Uygulamanın yeni versiyonu yayınlandı."),
            Body_EN = versionSettings.GetValueOrDefault("ForceUpdate_EN_Text",
                "The new version of the app has been released."),
            Body_AR = versionSettings.GetValueOrDefault("ForceUpdate_AR_Text", "تم إصدار النسخة الجديدة من التطبيق.")
        };

        return Ok(dto);
    }
}

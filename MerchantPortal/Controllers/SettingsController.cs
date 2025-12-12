using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class SettingsController : Controller
{
    private readonly ILogger<SettingsController> _logger;
    private readonly ISettingsService _settingsService;
    private readonly IAuthService _authService;

    /// <summary>
    /// SettingsController constructor
    /// </summary>
    /// <param name="logger">Logger instance</param>
    /// <param name="settingsService">Ayarlar servisi</param>
    /// <param name="authService">Kimlik doğrulama servisi</param>
    public SettingsController(ILogger<SettingsController> logger, ISettingsService settingsService, IAuthService authService)
    {
        _logger = logger;
        _settingsService = settingsService;
        _authService = authService;
    }

    /// <summary>
    /// Ayarlar sayfasını göster
    /// </summary>
    /// <returns>Ayarlar sayfası</returns>
    public IActionResult Index()
    {
        return View();
    }

    /// <summary>
    /// Bildirim tercihleri sayfasını göster
    /// </summary>
    /// <returns>Bildirim tercihleri sayfası</returns>
    [HttpGet]
    public async Task<IActionResult> Notifications()
    {
        try
        {
            // Get current preferences from API/database
            var preferences = await _settingsService.GetNotificationPreferencesAsync();
            
            // Pass to view (optional - can also load via AJAX)
            ViewBag.Preferences = preferences;
            
            return View();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading notification preferences");
            return View(); // Show view with default settings
        }
    }

    /// <summary>
    /// Bildirim tercihlerini getir
    /// </summary>
    /// <returns>JSON bildirim tercihleri</returns>
    [HttpGet("preferences")]
    public async Task<IActionResult> GetNotificationPreferences()
    {
        try
        {
            var preferences = await _settingsService.GetNotificationPreferencesAsync();
            
            if (preferences == null)
            {
                return Json(new { success = false, message = "Tercihler bulunamadı" });
            }
            
            return Json(new { success = true, data = preferences });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting notification preferences");
            return Json(new { success = false, message = "Tercihler alınamadı: " + ex.Message });
        }
    }

    /// <summary>
    /// Bildirim tercihlerini kaydet
    /// </summary>
    /// <param name="preferences">Bildirim tercihleri</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    public async Task<IActionResult> SaveNotificationPreferences([FromBody] UpdateNotificationPreferencesDto preferences)
    {
        try
        {
            var success = await _settingsService.UpdateNotificationPreferencesAsync(preferences);
            
            if (success)
            {
                _logger.LogInformation("Notification preferences updated successfully");
                return Json(new { success = true, message = "Bildirim tercihleri başarıyla kaydedildi" });
            }
            else
            {
                return Json(new { success = false, message = "Tercihler kaydedilemedi" });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving notification preferences");
            return Json(new { success = false, message = "Tercihler kaydedilemedi: " + ex.Message });
        }
    }

    /// <summary>
    /// Şifre değiştir
    /// </summary>
    /// <param name="model">Şifre değiştirme bilgileri</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordModel model)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Geçersiz veri" });
            }

            if (model.NewPassword != model.ConfirmPassword)
            {
                return Json(new { success = false, message = "Yeni şifreler eşleşmiyor" });
            }

            var success = await _authService.ChangePasswordAsync(
                model.CurrentPassword, 
                model.NewPassword);

            if (success)
            {
                _logger.LogInformation("Password changed successfully");
                return Json(new { success = true, message = "Şifreniz başarıyla değiştirildi" });
            }
            else
            {
                return Json(new { success = false, message = "Şifre değiştirilemedi. Lütfen mevcut şifrenizi kontrol edin." });
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password");
            return Json(new { success = false, message = "Bir hata oluştu: " + ex.Message });
        }
    }
}

/// <summary>
/// Şifre değiştirme modeli
/// </summary>
public class ChangePasswordModel
{
    public string CurrentPassword { get; set; } = default!;
    public string NewPassword { get; set; } = default!;
    public string ConfirmPassword { get; set; } = default!;
}

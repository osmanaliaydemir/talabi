using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ISettingsService
{   
    /// <summary>
    /// Bildirim tercihlerini getirir.
    /// </summary>
    /// <returns>Bildirim tercihleri</returns>
    Task<MerchantNotificationPreferencesDto?> GetNotificationPreferencesAsync();
    /// <summary>
    /// Bildirim tercihlerini günceller.
    /// </summary>
    /// <param name="preferences">Bildirim tercihleri</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> UpdateNotificationPreferencesAsync(UpdateNotificationPreferencesDto preferences);
}


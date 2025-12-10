using System.Globalization;

namespace Talabi.Core.Interfaces;

/// <summary>
/// Lokalizasyon servisi interface'i
/// Resource dosyalarından lokalize metinleri getirir
/// </summary>
public interface ILocalizationService
{
    /// <summary>
    /// Resource dosyasından lokalize metin getirir
    /// </summary>
    /// <param name="resourceName">Resource dosyası adı (örn: "VendorOrderResources")</param>
    /// <param name="key">Resource key</param>
    /// <param name="culture">Culture bilgisi</param>
    /// <param name="args">String format parametreleri</param>
    /// <returns>Lokalize edilmiş metin</returns>
    string GetLocalizedString(string resourceName, string key, CultureInfo culture, params object[] args);

    /// <summary>
    /// Resource dosyasından lokalize metin getirir (languageCode ile)
    /// </summary>
    /// <param name="resourceName">Resource dosyası adı (örn: "VendorOrderResources")</param>
    /// <param name="key">Resource key</param>
    /// <param name="languageCode">Dil kodu (tr, en, ar)</param>
    /// <param name="args">String format parametreleri</param>
    /// <returns>Lokalize edilmiş metin</returns>
    string GetLocalizedString(string resourceName, string key, string languageCode, params object[] args);
}


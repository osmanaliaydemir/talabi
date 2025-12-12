using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.Localization;

namespace Talabi.Portal.Services;

/// <summary>
/// JSON tabanlı yerelleştirme servisi
/// </summary>
public interface ILocalizationService
{
    /// <summary>
    /// Çeviri metnini getir
    /// </summary>
    /// <param name="key">Çeviri anahtarı</param>
    /// <returns>Çeviri metni</returns>
    string GetString(string key);
    /// <summary>
    /// Belirtilen kültür için çeviri metnini getir
    /// </summary>
    /// <param name="key">Çeviri anahtarı</param>
    /// <param name="culture">Kültür kodu</param>
    /// <returns>Çeviri metni</returns>
    string GetString(string key, string culture);
    /// <summary>
    /// Çevirileri yükle
    /// </summary>
    /// <returns>Yükleme işlemi</returns>
    Task LoadTranslationsAsync();
}

public class LocalizationService : ILocalizationService
{
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<LocalizationService> _logger;
    private Dictionary<string, Dictionary<string, string>> _translations = new();
    private readonly object _lock = new();

    /// <summary>
    /// LocalizationService constructor
    /// </summary>
    /// <param name="environment">Web host environment</param>
    /// <param name="logger">Logger instance</param>
    public LocalizationService(IWebHostEnvironment environment, ILogger<LocalizationService> logger)
    {
        _environment = environment;
        _logger = logger;
    }

    /// <summary>
    /// Çevirileri yükle
    /// </summary>
    /// <returns>Yükleme işlemi</returns>
    public async Task LoadTranslationsAsync()
    {
        lock (_lock)
        {
            try
            {
                var jsonPath = Path.Combine(_environment.ContentRootPath, "Resources", "localization.json");

                if (!File.Exists(jsonPath))
                {
                    _logger.LogWarning("Localization file not found: {Path}", jsonPath);
                    return;
                }

                var jsonContent = File.ReadAllText(jsonPath);
                _translations = JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, string>>>(jsonContent)
                    ?? new Dictionary<string, Dictionary<string, string>>();

                _logger.LogInformation("Loaded {Count} cultures with {TotalKeys} total keys",
                    _translations.Count,
                    _translations.Values.Sum(x => x.Count));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load localization file");
            }
        }
        await Task.CompletedTask;
    }

    /// <summary>
    /// Çeviri metnini getir
    /// </summary>
    /// <param name="key">Çeviri anahtarı</param>
    /// <returns>Çeviri metni</returns>
    public string GetString(string key)
    {
        var culture = CultureInfo.CurrentUICulture.Name;
        return GetString(key, culture);
    }

    /// <summary>
    /// Belirtilen kültür için çeviri metnini getir
    /// </summary>
    /// <param name="key">Çeviri anahtarı</param>
    /// <param name="culture">Kültür kodu</param>
    /// <returns>Çeviri metni</returns>
    public string GetString(string key, string culture)
    {
        // Ensure translations are loaded
        if (_translations.Count == 0)
        {
            LoadTranslationsAsync().Wait();
        }

        // Format: Key -> Culture -> Value
        // Check if key exists
        if (_translations.TryGetValue(key, out var cultureDict))
        {
            // Try requested culture
            if (cultureDict.TryGetValue(culture, out var value))
            {
                return value;
            }

            // Fallback to tr-TR
            if (cultureDict.TryGetValue("tr-TR", out var fallbackValue))
            {
                return fallbackValue;
            }
        }

        return key; // Return key as fallback
    }
}

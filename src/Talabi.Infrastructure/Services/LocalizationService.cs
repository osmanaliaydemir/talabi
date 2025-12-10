using System.Globalization;
using System.Resources;
using Talabi.Core.Interfaces;
using Microsoft.Extensions.Logging;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Lokalizasyon servisi implementasyonu
/// Resource dosyalarından lokalize metinleri getirir ve cache'ler
/// </summary>
public class LocalizationService : ILocalizationService
{
    private readonly ILogger<LocalizationService> _logger;
    private readonly Dictionary<string, ResourceManager> _resourceManagers = new();
    private readonly object _lock = new();

    public LocalizationService(ILogger<LocalizationService> logger)
    {
        _logger = logger;
    }

    public string GetLocalizedString(string resourceName, string key, CultureInfo culture, params object[] args)
    {
        var resourceManager = GetResourceManager(resourceName);
        
        if (resourceManager == null)
        {
            _logger.LogWarning("Resource manager not found for: {ResourceName}, key: {Key}", resourceName, key);
            return key; // Fallback to key name
        }

        // Try to get localized string
        var value = resourceManager.GetString(key, culture);
        
        // Fallback to Turkish if not found
        if (string.IsNullOrEmpty(value))
        {
            value = resourceManager.GetString(key, new CultureInfo("tr"));
        }

        // Fallback to English if still not found
        if (string.IsNullOrEmpty(value))
        {
            value = resourceManager.GetString(key, new CultureInfo("en"));
        }

        // Final fallback to key name
        if (string.IsNullOrEmpty(value))
        {
            _logger.LogWarning("Localized string not found for key: {Key} in resource: {ResourceName}", key, resourceName);
            return key;
        }

        // Format string if args provided
        return args.Length > 0 ? string.Format(value, args) : value;
    }

    public string GetLocalizedString(string resourceName, string key, string languageCode, params object[] args)
    {
        try
        {
            var culture = new CultureInfo(languageCode);
            return GetLocalizedString(resourceName, key, culture, args);
        }
        catch
        {
            var culture = new CultureInfo("tr"); // Fallback to Turkish
            return GetLocalizedString(resourceName, key, culture, args);
        }
    }

    private ResourceManager? GetResourceManager(string resourceName)
    {
        // Check cache first
        if (_resourceManagers.TryGetValue(resourceName, out var cachedManager))
        {
            return cachedManager;
        }

        // Lock to prevent multiple initializations
        lock (_lock)
        {
            // Double-check after lock
            if (_resourceManagers.TryGetValue(resourceName, out cachedManager))
            {
                return cachedManager;
            }

            // Try to load resource from Talabi.Api assembly
            try
            {
                var apiAssembly = AppDomain.CurrentDomain.GetAssemblies()
                    .FirstOrDefault(a => a.GetName().Name == "Talabi.Api");

                if (apiAssembly != null)
                {
                    var fullResourceName = $"Talabi.Api.Resources.{resourceName}";
                    var resourceManager = new ResourceManager(fullResourceName, apiAssembly);
                    
                    _resourceManagers[resourceName] = resourceManager;
                    return resourceManager;
                }
                else
                {
                    _logger.LogError("Talabi.Api assembly not found");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load resource manager for: {ResourceName}", resourceName);
                return null;
            }
        }
    }
}


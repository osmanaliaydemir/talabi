using Talabi.Core.Interfaces;
using Talabi.Core.Options;

namespace Talabi.Core.Extensions;

/// <summary>
/// Extension methods for ICacheService to provide cache invalidation helpers
/// </summary>
public static class CacheServiceExtensions
{
    /// <summary>
    /// Invalidates all category cache entries
    /// </summary>
    public static void InvalidateCategoriesCache(this ICacheService cacheService, CacheOptions cacheOptions)
    {
        cacheService.RemoveByPattern($"{cacheOptions.CategoriesKeyPrefix}_*");
    }

    /// <summary>
    /// Invalidates all banner cache entries
    /// </summary>
    public static void InvalidateBannersCache(this ICacheService cacheService, CacheOptions cacheOptions)
    {
        cacheService.RemoveByPattern($"{cacheOptions.BannersKeyPrefix}_*");
    }

    /// <summary>
    /// Invalidates category cache for a specific vendor type and language
    /// </summary>
    public static void InvalidateCategoryCache(this ICacheService cacheService, CacheOptions cacheOptions, string? vendorType = null, string? languageCode = null)
    {
        if (vendorType != null && languageCode != null)
        {
            // Remove specific cache entry
            var specificKey = $"{cacheOptions.CategoriesKeyPrefix}_{vendorType}_{languageCode}_*";
            cacheService.RemoveByPattern(specificKey);
        }
        else
        {
            // Remove all category cache entries
            cacheService.InvalidateCategoriesCache(cacheOptions);
        }
    }

    /// <summary>
    /// Invalidates banner cache for a specific vendor type and language
    /// </summary>
    public static void InvalidateBannerCache(this ICacheService cacheService, CacheOptions cacheOptions, string? vendorType = null, string? languageCode = null)
    {
        if (vendorType != null && languageCode != null)
        {
            // Remove specific cache entry
            var specificKey = $"{cacheOptions.BannersKeyPrefix}_{vendorType}_{languageCode}";
            cacheService.Remove(specificKey);
        }
        else
        {
            // Remove all banner cache entries
            cacheService.InvalidateBannersCache(cacheOptions);
        }
    }

    /// <summary>
    /// Invalidates all legal document cache entries
    /// </summary>
    public static void InvalidateLegalDocumentsCache(this ICacheService cacheService, CacheOptions cacheOptions)
    {
        cacheService.RemoveByPattern($"{cacheOptions.LegalDocumentsKeyPrefix}_*");
    }

    /// <summary>
    /// Invalidates all cities cache entries
    /// </summary>
    public static void InvalidateCitiesCache(this ICacheService cacheService, CacheOptions cacheOptions)
    {
        cacheService.RemoveByPattern($"{cacheOptions.CitiesKeyPrefix}_*");
    }

    /// <summary>
    /// Invalidates all popular products cache entries
    /// </summary>
    public static void InvalidatePopularProductsCache(this ICacheService cacheService, CacheOptions cacheOptions)
    {
        cacheService.RemoveByPattern($"{cacheOptions.PopularProductsKeyPrefix}_*");
    }
}


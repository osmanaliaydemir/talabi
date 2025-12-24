using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Cache service implementation using IMemoryCache
/// </summary>
public class CacheService : ICacheService
{
    private readonly IMemoryCache _memoryCache;
    private readonly CacheOptions _cacheOptions;
    private readonly ILogger<CacheService> _logger;
    private readonly HashSet<string> _cacheKeys; // Track cache keys for pattern removal

    public CacheService(
        IMemoryCache memoryCache,
        IOptions<CacheOptions> cacheOptions,
        ILogger<CacheService> logger)
    {
        _memoryCache = memoryCache;
        _cacheOptions = cacheOptions.Value;
        _logger = logger;
        _cacheKeys = new HashSet<string>();
    }

    public T? Get<T>(string key) where T : class
    {
        try
        {
            if (_memoryCache.TryGetValue(key, out T? cachedValue))
            {
                _logger.LogDebug("Cache hit for key: {Key}", key);
                return cachedValue;
            }

            _logger.LogDebug("Cache miss for key: {Key}", key);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cache value for key: {Key}", key);
            return null;
        }
    }

    public async Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, int? expirationMinutes = null) where T : class
    {
        // Try to get from cache first
        var cachedValue = Get<T>(key);
        if (cachedValue != null)
        {
            return cachedValue;
        }

        // If not in cache, execute factory and cache the result
        var value = await factory();
        if (value != null)
        {
            Set(key, value, expirationMinutes);
        }

        return value;
    }

    public void Set<T>(string key, T value, int? expirationMinutes = null) where T : class
    {
        try
        {
            var expiration = expirationMinutes ?? _cacheOptions.DefaultCacheTTLMinutes;
            var cacheOptions = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(expiration),
                Priority = CacheItemPriority.Normal
            };

            _memoryCache.Set(key, value, cacheOptions);
            _cacheKeys.Add(key); // Track key for pattern removal
            _logger.LogDebug("Cached value for key: {Key} with expiration: {Expiration} minutes", key, expiration);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting cache value for key: {Key}", key);
        }
    }

    public void Remove(string key)
    {
        try
        {
            _memoryCache.Remove(key);
            _cacheKeys.Remove(key);
            _logger.LogDebug("Removed cache entry for key: {Key}", key);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing cache entry for key: {Key}", key);
        }
    }

    public void RemoveByPattern(string pattern)
    {
        try
        {
            // Simple pattern matching: supports * wildcard at the end
            var keysToRemove = new List<string>();

            if (pattern.EndsWith("*"))
            {
                var prefix = pattern.Substring(0, pattern.Length - 1);
                keysToRemove = _cacheKeys.Where(k => k.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)).ToList();
            }
            else
            {
                // Exact match
                if (_cacheKeys.Contains(pattern))
                {
                    keysToRemove.Add(pattern);
                }
            }

            foreach (var key in keysToRemove)
            {
                _memoryCache.Remove(key);
                _cacheKeys.Remove(key);
            }

            _logger.LogInformation("Removed {Count} cache entries matching pattern: {Pattern}", keysToRemove.Count, pattern);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing cache entries by pattern: {Pattern}", pattern);
        }
    }

    public void Clear()
    {
        try
        {
            // MemoryCache doesn't have a Clear method, so we need to remove all tracked keys
            var keysToRemove = _cacheKeys.ToList();
            foreach (var key in keysToRemove)
            {
                _memoryCache.Remove(key);
            }
            _cacheKeys.Clear();
            _logger.LogInformation("Cleared all cache entries ({Count} entries)", keysToRemove.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing cache");
        }
    }
}


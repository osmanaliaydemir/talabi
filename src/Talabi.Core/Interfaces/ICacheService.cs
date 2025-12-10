namespace Talabi.Core.Interfaces;

/// <summary>
/// Cache service interface for managing application cache
/// </summary>
public interface ICacheService
{
    /// <summary>
    /// Gets a value from cache by key
    /// </summary>
    /// <typeparam name="T">Type of the cached value</typeparam>
    /// <param name="key">Cache key</param>
    /// <returns>Cached value or default if not found</returns>
    T? Get<T>(string key) where T : class;

    /// <summary>
    /// Gets a value from cache by key, or sets it if not found (cache-aside pattern)
    /// </summary>
    /// <typeparam name="T">Type of the cached value</typeparam>
    /// <param name="key">Cache key</param>
    /// <param name="factory">Factory function to create value if not cached</param>
    /// <param name="expirationMinutes">Optional expiration time in minutes (uses default if null)</param>
    /// <returns>Cached or newly created value</returns>
    Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory, int? expirationMinutes = null) where T : class;

    /// <summary>
    /// Sets a value in cache with optional expiration
    /// </summary>
    /// <typeparam name="T">Type of the value to cache</typeparam>
    /// <param name="key">Cache key</param>
    /// <param name="value">Value to cache</param>
    /// <param name="expirationMinutes">Optional expiration time in minutes (uses default if null)</param>
    void Set<T>(string key, T value, int? expirationMinutes = null) where T : class;

    /// <summary>
    /// Removes a value from cache by key
    /// </summary>
    /// <param name="key">Cache key</param>
    void Remove(string key);

    /// <summary>
    /// Removes all cache entries that match the key pattern
    /// </summary>
    /// <param name="pattern">Key pattern (e.g., "categories_*")</param>
    void RemoveByPattern(string pattern);

    /// <summary>
    /// Clears all cache entries
    /// </summary>
    void Clear();
}


using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Email verification code security service implementation
/// Protects against brute force attacks on verification codes
/// </summary>
public class VerificationCodeSecurityService : IVerificationCodeSecurityService
{
    private readonly IMemoryCache _memoryCache;
    private readonly ILogger<VerificationCodeSecurityService> _logger;
    private readonly VerificationCodeSecurityOptions _options;

    // Cache key prefixes
    private const string AttemptsKeyPrefix = "verification_attempts_";
    private const string LockoutKeyPrefix = "verification_lockout_";

    public VerificationCodeSecurityService(
        IMemoryCache memoryCache,
        ILogger<VerificationCodeSecurityService> logger,
        IOptions<VerificationCodeSecurityOptions> options)
    {
        _memoryCache = memoryCache;
        _logger = logger;
        _options = options.Value;
    }

    public Task<bool> CanAttemptVerificationAsync(string email)
    {
        var lockoutKey = $"{LockoutKeyPrefix}{email}";
        
        // Check if email is locked out
        if (_memoryCache.TryGetValue(lockoutKey, out DateTime lockoutExpiration))
        {
            if (lockoutExpiration > DateTime.UtcNow)
            {
                _logger.LogWarning("Verification attempt blocked for locked email: {Email}, Lockout expires: {Expiration}", 
                    email, lockoutExpiration);
                return Task.FromResult(false);
            }
            else
            {
                // Lockout expired, remove it
                _memoryCache.Remove(lockoutKey);
            }
        }

        var attemptsKey = $"{AttemptsKeyPrefix}{email}";
        
        // Check current attempts
        if (_memoryCache.TryGetValue(attemptsKey, out int attempts))
        {
            if (attempts >= _options.MaxFailedAttempts)
            {
                // Too many attempts, lock out
                var lockoutDuration = TimeSpan.FromMinutes(_options.LockoutDurationMinutes);
                var expiration = DateTime.UtcNow.Add(lockoutDuration);
                
                _memoryCache.Set(lockoutKey, expiration, lockoutDuration);
                _memoryCache.Remove(attemptsKey); // Clear attempts
                
                _logger.LogWarning("Email verification locked due to too many failed attempts: {Email}, Lockout until: {Expiration}", 
                    email, expiration);
                
                return Task.FromResult(false);
            }
        }

        return Task.FromResult(true);
    }

    public Task RecordFailedAttemptAsync(string email)
    {
        var attemptsKey = $"{AttemptsKeyPrefix}{email}";
        
        // Get current attempts or start from 0
        if (!_memoryCache.TryGetValue(attemptsKey, out int attempts))
        {
            attempts = 0;
        }

        attempts++;

        // Store attempts with sliding expiration
        var cacheOptions = new MemoryCacheEntryOptions
        {
            SlidingExpiration = TimeSpan.FromMinutes(_options.AttemptWindowMinutes),
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(_options.AttemptWindowMinutes + 5)
        };

        _memoryCache.Set(attemptsKey, attempts, cacheOptions);

        _logger.LogInformation("Failed verification attempt recorded for {Email}, Total attempts: {Attempts}", 
            email, attempts);

        // If max attempts reached, lock out
        if (attempts >= _options.MaxFailedAttempts)
        {
            var lockoutKey = $"{LockoutKeyPrefix}{email}";
            var lockoutDuration = TimeSpan.FromMinutes(_options.LockoutDurationMinutes);
            var expiration = DateTime.UtcNow.Add(lockoutDuration);
            
            _memoryCache.Set(lockoutKey, expiration, lockoutDuration);
            _memoryCache.Remove(attemptsKey);
            
            _logger.LogWarning("Email verification locked after {Attempts} failed attempts: {Email}, Lockout until: {Expiration}", 
                attempts, email, expiration);
        }

        return Task.CompletedTask;
    }

    public Task RecordSuccessAsync(string email)
    {
        // Clear all tracking for successful verification
        var attemptsKey = $"{AttemptsKeyPrefix}{email}";
        var lockoutKey = $"{LockoutKeyPrefix}{email}";
        
        _memoryCache.Remove(attemptsKey);
        _memoryCache.Remove(lockoutKey);

        _logger.LogInformation("Successful verification recorded for {Email}, tracking cleared", email);

        return Task.CompletedTask;
    }

    public Task<int> GetRemainingAttemptsAsync(string email)
    {
        var attemptsKey = $"{AttemptsKeyPrefix}{email}";
        
        if (_memoryCache.TryGetValue(attemptsKey, out int attempts))
        {
            var remaining = Math.Max(0, _options.MaxFailedAttempts - attempts);
            return Task.FromResult(remaining);
        }

        return Task.FromResult(_options.MaxFailedAttempts);
    }

    public Task<DateTime?> GetLockoutExpirationAsync(string email)
    {
        var lockoutKey = $"{LockoutKeyPrefix}{email}";
        
        if (_memoryCache.TryGetValue(lockoutKey, out DateTime expiration))
        {
            if (expiration > DateTime.UtcNow)
            {
                return Task.FromResult<DateTime?>(expiration);
            }
            else
            {
                // Lockout expired
                _memoryCache.Remove(lockoutKey);
            }
        }

        return Task.FromResult<DateTime?>(null);
    }
}

/// <summary>
/// Verification code security options
/// </summary>
public class VerificationCodeSecurityOptions
{
    /// <summary>
    /// Maximum number of failed verification attempts before lockout
    /// </summary>
    public int MaxFailedAttempts { get; set; } = 5;

    /// <summary>
    /// Lockout duration in minutes after max attempts reached
    /// </summary>
    public int LockoutDurationMinutes { get; set; } = 15;

    /// <summary>
    /// Time window in minutes for tracking attempts
    /// </summary>
    public int AttemptWindowMinutes { get; set; } = 10;
}


using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// User activity logging için service - Hangfire background job kullanır
/// </summary>
public class ActivityLoggingService : IActivityLoggingService
{
    private readonly ILogger<ActivityLoggingService> _logger;
    private static IServiceProvider? _serviceProvider;

    public ActivityLoggingService(ILogger<ActivityLoggingService> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Service provider'ı set eder (Program.cs'den çağrılır)
    /// </summary>
    public static void SetServiceProvider(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    /// <summary>
    /// User activity log'unu asenkron olarak kaydeder (Hangfire background job)
    /// </summary>
    public void LogActivityAsync(
        string? userId,
        string? userEmail,
        string? phoneNumber,
        string path,
        string method,
        string? queryString,
        string? requestBody,
        string? responseBody,
        int statusCode,
        long durationMs,
        string? ipAddress,
        string? userAgent,
        string? exception)
    {
        // Hangfire background job olarak çalıştır - fire-and-forget
        BackgroundJob.Enqueue(() => SaveLogAsync(
            userId,
            userEmail,
            phoneNumber,
            path,
            method,
            queryString,
            requestBody,
            responseBody,
            statusCode,
            durationMs,
            ipAddress,
            userAgent,
            exception));
    }

    /// <summary>
    /// Log kaydını database'e yazar (Hangfire tarafından çağrılır - static method)
    /// </summary>
    [AutomaticRetry(Attempts = 3, DelaysInSeconds = new[] { 5, 10, 30 })]
    public static async Task SaveLogAsync(
        string? userId,
        string? userEmail,
        string? phoneNumber,
        string path,
        string method,
        string? queryString,
        string? requestBody,
        string? responseBody,
        int statusCode,
        long durationMs,
        string? ipAddress,
        string? userAgent,
        string? exception)
    {
        if (_serviceProvider == null)
        {
            throw new InvalidOperationException("Service provider is not set. Call ActivityLoggingService.SetServiceProvider() in Program.cs");
        }

        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<ActivityLoggingService>>();

        try
        {
            // Database bağlantısını kontrol et
            if (!await dbContext.Database.CanConnectAsync())
            {
                logger.LogWarning("Cannot connect to database! Skipping log save for path: {Path}", path);
                return;
            }

            var log = new UserActivityLog
            {
                UserId = userId,
                UserEmail = userEmail,
                PhoneNumber = phoneNumber,
                Path = path,
                Method = method,
                QueryString = queryString,
                RequestBody = requestBody,
                ResponseBody = responseBody,
                StatusCode = statusCode,
                DurationMs = durationMs,
                IpAddress = ipAddress,
                UserAgent = userAgent,
                CreatedAt = DateTime.UtcNow,
                Exception = exception
            };

            dbContext.UserActivityLogs.Add(log);
            await dbContext.SaveChangesAsync();

            logger.LogDebug("User activity logged: {Path} {Method} {StatusCode} {DurationMs}ms",
                log.Path, log.Method, log.StatusCode, log.DurationMs);
        }
        catch (Exception ex)
        {
            logger.LogError(ex,
                "Error saving user activity log for path: {Path}, method: {Method}, statusCode: {StatusCode}",
                path, method, statusCode);
            throw; // Hangfire retry mekanizması için throw et
        }
    }
}


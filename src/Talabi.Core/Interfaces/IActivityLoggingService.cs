namespace Talabi.Core.Interfaces;

/// <summary>
/// User activity logging için service interface
/// </summary>
public interface IActivityLoggingService
{
    /// <summary>
    /// User activity log'unu asenkron olarak kaydeder (Hangfire background job)
    /// </summary>
    void LogActivityAsync(
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
        string? exception);
}


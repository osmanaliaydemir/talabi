using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Entities;
using Talabi.Core.Services;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Error log kayıtları için service - Hangfire background job kullanır
/// </summary>
public class ErrorLoggingService
{
    private static IServiceProvider? _serviceProvider;

    /// <summary>
    /// Service provider'ı set eder (Program.cs'den çağrılır)
    /// </summary>
    public static void SetServiceProvider(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Error log kayıtlarını database'e yazar (Hangfire tarafından çağrılır - static method)
    /// </summary>
    [AutomaticRetry(Attempts = 3, DelaysInSeconds = new[] { 5, 10, 30 })]
    public static async Task SaveErrorLogsAsync(List<ErrorLogItemDto> logs)
    {
        if (_serviceProvider == null)
        {
            throw new InvalidOperationException("Service provider is not set. Call ErrorLoggingService.SetServiceProvider() in Program.cs");
        }

        using var scope = _serviceProvider.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<ErrorLoggingService>>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        try
        {
            // Database bağlantısını kontrol et
            if (!await dbContext.Database.CanConnectAsync())
            {
                logger.LogWarning("Cannot connect to database! Skipping error log save");
                return;
            }

            var errorLogs = logs.Select(log => new ErrorLog
            {
                Id = Guid.NewGuid(),
                LogId = log.Id,
                Level = log.Level,
                Message = log.Message,
                Error = log.Error,
                StackTrace = log.StackTrace,
                Timestamp = log.Timestamp,
                Metadata = log.Metadata != null ? System.Text.Json.JsonSerializer.Serialize(log.Metadata) : null,
                UserId = log.UserId,
                DeviceInfo = log.DeviceInfo,
                AppVersion = log.AppVersion,
                CreatedAt = DateTime.UtcNow
            }).ToList();

            await dbContext.ErrorLogs.AddRangeAsync(errorLogs);
            await dbContext.SaveChangesAsync();

            logger.LogInformation("Successfully saved {Count} error logs from mobile app", errorLogs.Count);

            // Kritik hatalar için admin'e email gönder (fatal ve error seviyesi)
            var sendEmailForErrors = configuration.GetValue<bool>("ErrorLogging:SendEmailForErrors", true);
            var sendEmailForFatalOnly = configuration.GetValue<bool>("ErrorLogging:SendEmailForFatalOnly", false);

            if (sendEmailForErrors)
            {
                var criticalLogs = errorLogs.Where(log =>
                    sendEmailForFatalOnly
                        ? log.Level.Equals("fatal", StringComparison.OrdinalIgnoreCase)
                        : log.Level.Equals("fatal", StringComparison.OrdinalIgnoreCase) ||
                          log.Level.Equals("error", StringComparison.OrdinalIgnoreCase)).ToList();

                if (criticalLogs.Any())
                {
                    // Hangfire üzerinden email gönder - asenkron, performansı etkilemez
                    BackgroundJob.Enqueue(() => SendErrorNotificationEmailAsync(
                        criticalLogs.Count,
                        criticalLogs.First().Message,
                        criticalLogs.First().Level,
                        criticalLogs.First().Timestamp
                    ));
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error saving error logs");
            throw; // Hangfire retry mekanizması için throw et
        }
    }

    /// <summary>
    /// Admin'e error notification email gönderir (Hangfire tarafından çağrılır)
    /// </summary>
    [AutomaticRetry(Attempts = 2, DelaysInSeconds = new[] { 30, 60 })]
    public static async Task SendErrorNotificationEmailAsync(
        int errorCount,
        string firstErrorMessage,
        string logLevel,
        DateTime timestamp)
    {
        if (_serviceProvider == null)
        {
            throw new InvalidOperationException("Service provider is not set.");
        }

        using var scope = _serviceProvider.CreateScope();
        var emailSender = scope.ServiceProvider.GetRequiredService<IEmailSender>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<ErrorLoggingService>>();

        try
        {
            // Admin email adresini configuration'dan al
            var adminEmail = configuration["ErrorLogging:AdminEmail"]
                ?? configuration["Email:AdminEmail"]
                ?? "admin@talabi.com"; // Fallback

            var baseUrl = configuration["AppSettings:BaseUrl"] ?? "https://talabi.runasp.net";

            // Badge class'ını log seviyesine göre belirle
            var badgeClass = logLevel.Equals("fatal", StringComparison.OrdinalIgnoreCase) 
                ? "badge-fatal" 
                : "badge-error";

            // Email gönder
            await emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = adminEmail,
                Subject = $"[Talabi] {errorCount} Kritik Hata Bildirimi - {logLevel.ToUpper()}",
                TemplateName = "ErrorNotification",
                Variables = new Dictionary<string, string>
                {
                    { "ErrorCount", errorCount.ToString() },
                    { "LogLevel", logLevel.ToUpper() },
                    { "BadgeClass", badgeClass },
                    { "FirstErrorMessage", firstErrorMessage.Length > 200 
                        ? firstErrorMessage.Substring(0, 200) + "..." 
                        : firstErrorMessage },
                    { "Timestamp", timestamp.ToString("yyyy-MM-dd HH:mm:ss") },
                    { "ViewLogsUrl", $"{baseUrl}/api/logs/errors" }
                },
                LanguageCode = "tr"
            });

            logger.LogInformation("Error notification email sent to {AdminEmail}", adminEmail);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send error notification email");
            // Email gönderim hatası kritik değil, throw etme
        }
    }
}


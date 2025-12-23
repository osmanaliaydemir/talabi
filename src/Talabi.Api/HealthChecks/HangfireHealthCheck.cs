using Hangfire;
using Hangfire.Storage;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Talabi.Api.HealthChecks;

/// <summary>
/// Hangfire background job servisi için health check
/// </summary>
public class HangfireHealthCheck(ILogger<HangfireHealthCheck> logger) : IHealthCheck
{
    private readonly ILogger<HangfireHealthCheck> _logger = logger;

    /// <summary>
    /// Hangfire bağlantısını ve durumunu kontrol eder
    /// </summary>
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            // JobStorage'un null olup olmadığını kontrol et
            if (JobStorage.Current == null)
            {
                _logger.LogWarning("Hangfire health check failed: JobStorage.Current is null");
                return Task.FromResult(HealthCheckResult.Unhealthy("Hangfire JobStorage yapılandırılmamış",
                    data: new Dictionary<string, object>
                    {
                        { "Service", "Hangfire" },
                        { "Status", "Unhealthy" }
                    }));
            }

            // Hangfire bağlantısını test et
            using var connection = JobStorage.Current.GetConnection();

            if (connection == null)
            {
                _logger.LogWarning("Hangfire health check failed: Cannot get connection");
                return Task.FromResult(HealthCheckResult.Unhealthy("Hangfire bağlantısı alınamadı",
                    data: new Dictionary<string, object>
                    {
                        { "Service", "Hangfire" },
                        { "Status", "Unhealthy" }
                    }));
            }

            // Hangfire sunucularının durumunu kontrol et - JobStorage üzerinden
            var monitoringApi = JobStorage.Current.GetMonitoringApi();
            var servers = monitoringApi.Servers();
            var activeServers = servers.Count(s => s.Heartbeat != null &&
                DateTime.UtcNow - s.Heartbeat.Value < TimeSpan.FromMinutes(1));

            _logger.LogDebug("Hangfire health check passed. Active servers: {Count}", activeServers);
            return Task.FromResult(HealthCheckResult.Healthy($"Hangfire çalışıyor (Aktif sunucu sayısı: {activeServers})",
                data: new Dictionary<string, object>
                {
                    { "Service", "Hangfire" },
                    { "Status", "Healthy" },
                    { "ActiveServers", activeServers },
                    { "TotalServers", servers.Count }
                }));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Hangfire health check failed with exception");
            // Production'da exception detaylarını gizle
            var isDevelopment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development";

            return Task.FromResult(HealthCheckResult.Unhealthy(
                "Hangfire sağlık kontrolü başarısız",
                // Production'da exception'ı geçme, sadece development'ta
                isDevelopment ? ex : null,
                data: new Dictionary<string, object>
                {
                    { "Service", "Hangfire" },
                    { "Status", "Unhealthy" }
                    // Error mesajını production'da gizle
                }));
        }
    }
}


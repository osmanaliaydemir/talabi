using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Talabi.Api.HealthChecks;

/// <summary>
/// Sistem bellek kullanımı için health check
/// </summary>
public class MemoryHealthCheck : IHealthCheck
{
    private readonly ILogger<MemoryHealthCheck> _logger;
    private readonly long _thresholdBytes;

    /// <summary>
    /// MemoryHealthCheck constructor
    /// </summary>
    /// <param name="logger">Logger instance</param>
    /// <param name="thresholdBytes">Uyarı eşiği (bytes) - Varsayılan: 1GB</param>
    public MemoryHealthCheck(ILogger<MemoryHealthCheck> logger, long thresholdBytes = 1073741824)
    {
        _logger = logger;
        _thresholdBytes = thresholdBytes;
    }

    /// <summary>
    /// Sistem bellek kullanımını kontrol eder
    /// </summary>
    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var process = System.Diagnostics.Process.GetCurrentProcess();
            var workingSet = process.WorkingSet64;
            var privateMemory = process.PrivateMemorySize64;

            var isHealthy = workingSet < _thresholdBytes;
            var status = isHealthy ? HealthStatus.Healthy : HealthStatus.Degraded;

            var message = isHealthy
                ? $"Bellek kullanımı normal (Çalışma seti: {FormatBytes(workingSet)})"
                : $"Bellek kullanımı yüksek (Çalışma seti: {FormatBytes(workingSet)}, Eşik: {FormatBytes(_thresholdBytes)})";

            _logger.LogDebug("Memory health check: {Status}, WorkingSet: {WorkingSet}, PrivateMemory: {PrivateMemory}",
                status, FormatBytes(workingSet), FormatBytes(privateMemory));

            return Task.FromResult(new HealthCheckResult(
                status,
                message,
                data: new Dictionary<string, object>
                {
                    { "WorkingSetBytes", workingSet },
                    { "WorkingSetFormatted", FormatBytes(workingSet) },
                    { "PrivateMemoryBytes", privateMemory },
                    { "PrivateMemoryFormatted", FormatBytes(privateMemory) },
                    { "ThresholdBytes", _thresholdBytes },
                    { "ThresholdFormatted", FormatBytes(_thresholdBytes) },
                    { "Status", status.ToString() }
                }));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Memory health check failed with exception");
            return Task.FromResult(HealthCheckResult.Unhealthy(
                "Bellek sağlık kontrolü başarısız",
                ex,
                data: new Dictionary<string, object>
                {
                    { "Error", ex.Message }
                }));
        }
    }

    private static string FormatBytes(long bytes)
    {
        string[] sizes = { "B", "KB", "MB", "GB", "TB" };
        double len = bytes;
        int order = 0;
        while (len >= 1024 && order < sizes.Length - 1)
        {
            order++;
            len = len / 1024;
        }
        return $"{len:0.##} {sizes[order]}";
    }
}


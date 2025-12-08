using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.HealthChecks;

/// <summary>
/// Veritabanı bağlantısı için health check
/// </summary>
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<DatabaseHealthCheck> _logger;

    /// <summary>
    /// DatabaseHealthCheck constructor
    /// </summary>
    public DatabaseHealthCheck(TalabiDbContext context, ILogger<DatabaseHealthCheck> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Veritabanı bağlantısını kontrol eder
    /// </summary>
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            // Veritabanı bağlantısını test et
            var canConnect = await _context.Database.CanConnectAsync(cancellationToken);

            if (!canConnect)
            {
                _logger.LogWarning("Database health check failed: Cannot connect to database");
                return HealthCheckResult.Unhealthy(
                    "Veritabanına bağlanılamıyor",
                    data: new Dictionary<string, object>
                    {
                        { "Database", "TalabiDbContext" },
                        { "Status", "Unhealthy" }
                    });
            }

            // Basit bir query çalıştırarak bağlantıyı doğrula
            await _context.Database.ExecuteSqlRawAsync("SELECT 1", cancellationToken);

            _logger.LogDebug("Database health check passed");
            return HealthCheckResult.Healthy("Veritabanı bağlantısı başarılı",
                data: new Dictionary<string, object>
                {
                    { "Database", "TalabiDbContext" },
                    { "Status", "Healthy" }
                });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database health check failed with exception");
            return HealthCheckResult.Unhealthy("Veritabanı sağlık kontrolü başarısız",
                ex,
                data: new Dictionary<string, object>
                {
                    { "Database", "TalabiDbContext" },
                    { "Status", "Unhealthy" },
                    { "Error", ex.Message }
                });
        }
    }
}


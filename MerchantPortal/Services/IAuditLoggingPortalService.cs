using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IAuditLoggingPortalService
{
    Task<List<UserActivityLogResponse>> GetUserActivityLogsAsync(UserActivityQueryRequestModel request, CancellationToken ct = default);
    Task<List<SystemChangeLogResponse>> GetSystemChangeLogsAsync(SystemChangeQueryRequestModel request, CancellationToken ct = default);
    Task<List<SecurityEventLogResponse>> GetSecurityEventLogsAsync(SecurityEventQueryRequestModel request, CancellationToken ct = default);
    Task<AuditLogAnalyticsResponse?> GetAuditAnalyticsAsync(AuditLogAnalyticsRequestModel request, CancellationToken ct = default);
    Task<List<LogAnalysisReportResponse>> GetLogAnalysisReportsAsync(CancellationToken ct = default);
    Task<LogAnalysisReportResponse?> RegenerateReportAsync(Guid reportId, CancellationToken ct = default);
    Task<bool> CleanupUserActivitiesAsync(DateTime cutoffDate, CancellationToken ct = default);
    Task<bool> CleanupSystemChangesAsync(DateTime cutoffDate, CancellationToken ct = default);
    Task<bool> CleanupSecurityEventsAsync(DateTime cutoffDate, CancellationToken ct = default);
    Task<bool> CleanupAnalysisReportsAsync(CancellationToken ct = default);
    Task<byte[]?> ExportReportAsync(Guid reportId, string format = "PDF", CancellationToken ct = default);
}



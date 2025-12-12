using System.Globalization;
using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.WebUtilities;

namespace Getir.MerchantPortal.Services;

public class AuditLoggingPortalService : IAuditLoggingPortalService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<AuditLoggingPortalService> _logger;

    public AuditLoggingPortalService(IApiClient apiClient, ILogger<AuditLoggingPortalService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<UserActivityLogResponse>> GetUserActivityLogsAsync(UserActivityQueryRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/user-activity", BuildUserActivityQuery(request));
            var response = await _apiClient.GetAsync<List<UserActivityLogResponse>>(url, ct);
            return response ?? new List<UserActivityLogResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch user activity logs");
            return new List<UserActivityLogResponse>();
        }
    }

    public async Task<List<SystemChangeLogResponse>> GetSystemChangeLogsAsync(SystemChangeQueryRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/system-change", BuildSystemChangeQuery(request));
            var response = await _apiClient.GetAsync<List<SystemChangeLogResponse>>(url, ct);
            return response ?? new List<SystemChangeLogResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch system change logs");
            return new List<SystemChangeLogResponse>();
        }
    }

    public async Task<List<SecurityEventLogResponse>> GetSecurityEventLogsAsync(SecurityEventQueryRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/security-event", BuildSecurityEventQuery(request));
            var response = await _apiClient.GetAsync<List<SecurityEventLogResponse>>(url, ct);
            return response ?? new List<SecurityEventLogResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch security event logs");
            return new List<SecurityEventLogResponse>();
        }
    }

    public async Task<AuditLogAnalyticsResponse?> GetAuditAnalyticsAsync(AuditLogAnalyticsRequestModel request, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.PostAsync<AuditLogAnalyticsResponse>("api/AuditLogging/analytics/audit-log", request, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch audit analytics");
            return null;
        }
    }

    public async Task<List<LogAnalysisReportResponse>> GetLogAnalysisReportsAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<List<LogAnalysisReportResponse>>("api/AuditLogging/analysis-report", ct);
            return response ?? new List<LogAnalysisReportResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch analysis reports");
            return new List<LogAnalysisReportResponse>();
        }
    }

    public async Task<LogAnalysisReportResponse?> RegenerateReportAsync(Guid reportId, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/AuditLogging/analysis-report/{reportId}/regenerate";
            return await _apiClient.PostAsync<LogAnalysisReportResponse>(endpoint, new { }, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to regenerate analysis report {ReportId}", reportId);
            return null;
        }
    }

    public async Task<bool> CleanupUserActivitiesAsync(DateTime cutoffDate, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/user-activity/cleanup", new Dictionary<string, string?>
            {
                ["cutoffDate"] = FormatDate(cutoffDate)
            });
            return await _apiClient.DeleteAsync(url, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup user activities");
            return false;
        }
    }

    public async Task<bool> CleanupSystemChangesAsync(DateTime cutoffDate, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/system-change/cleanup", new Dictionary<string, string?>
            {
                ["cutoffDate"] = FormatDate(cutoffDate)
            });
            return await _apiClient.DeleteAsync(url, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup system change logs");
            return false;
        }
    }

    public async Task<bool> CleanupSecurityEventsAsync(DateTime cutoffDate, CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl("api/AuditLogging/security-event/cleanup", new Dictionary<string, string?>
            {
                ["cutoffDate"] = FormatDate(cutoffDate)
            });
            return await _apiClient.DeleteAsync(url, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup security events");
            return false;
        }
    }

    public async Task<bool> CleanupAnalysisReportsAsync(CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.DeleteAsync("api/AuditLogging/analysis-report/cleanup", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cleanup analysis reports");
            return false;
        }
    }

    public async Task<byte[]?> ExportReportAsync(Guid reportId, string format = "PDF", CancellationToken ct = default)
    {
        try
        {
            var url = BuildQueryUrl($"api/AuditLogging/analysis-report/{reportId}/export", new Dictionary<string, string?>
            {
                ["format"] = format
            });
            return await _apiClient.GetByteArrayAsync(url, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to export analysis report {ReportId}", reportId);
            return null;
        }
    }

    private static string BuildQueryUrl(string basePath, Dictionary<string, string?> parameters)
    {
        var filtered = new Dictionary<string, string?>(StringComparer.OrdinalIgnoreCase);

        foreach (var kv in parameters)
        {
            if (!string.IsNullOrWhiteSpace(kv.Value))
            {
                filtered[kv.Key] = kv.Value;
            }
        }

        return filtered.Count == 0
            ? basePath
            : QueryHelpers.AddQueryString(basePath, filtered);
    }

    private static Dictionary<string, string?> BuildUserActivityQuery(UserActivityQueryRequestModel request)
    {
        return new Dictionary<string, string?>
        {
            ["startDate"] = FormatDate(request.StartDate),
            ["endDate"] = FormatDate(request.EndDate),
            ["userId"] = request.UserId?.ToString(),
            ["userName"] = request.UserName,
            ["activityType"] = request.ActivityType,
            ["entityType"] = request.EntityType,
            ["entityId"] = request.EntityId,
            ["deviceType"] = request.DeviceType,
            ["browser"] = request.Browser,
            ["operatingSystem"] = request.OperatingSystem,
            ["isSuccess"] = request.IsSuccess?.ToString(),
            ["pageNumber"] = request.PageNumber.ToString(CultureInfo.InvariantCulture),
            ["pageSize"] = request.PageSize.ToString(CultureInfo.InvariantCulture),
            ["sortBy"] = request.SortBy,
            ["sortDirection"] = request.SortDirection
        };
    }

    private static Dictionary<string, string?> BuildSystemChangeQuery(SystemChangeQueryRequestModel request)
    {
        return new Dictionary<string, string?>
        {
            ["startDate"] = FormatDate(request.StartDate),
            ["endDate"] = FormatDate(request.EndDate),
            ["changeType"] = request.ChangeType,
            ["entityType"] = request.EntityType,
            ["entityId"] = request.EntityId,
            ["changedByUserId"] = request.ChangedByUserId?.ToString(),
            ["changedByUserName"] = request.ChangedByUserName,
            ["changeSource"] = request.ChangeSource,
            ["severity"] = request.Severity,
            ["isSuccess"] = request.IsSuccess?.ToString(),
            ["pageNumber"] = request.PageNumber.ToString(CultureInfo.InvariantCulture),
            ["pageSize"] = request.PageSize.ToString(CultureInfo.InvariantCulture),
            ["sortBy"] = request.SortBy,
            ["sortDirection"] = request.SortDirection
        };
    }

    private static Dictionary<string, string?> BuildSecurityEventQuery(SecurityEventQueryRequestModel request)
    {
        return new Dictionary<string, string?>
        {
            ["startDate"] = FormatDate(request.StartDate),
            ["endDate"] = FormatDate(request.EndDate),
            ["eventType"] = request.EventType,
            ["severity"] = request.Severity,
            ["riskLevel"] = request.RiskLevel,
            ["userId"] = request.UserId?.ToString(),
            ["userName"] = request.UserName,
            ["userRole"] = request.UserRole,
            ["ipAddress"] = request.IpAddress,
            ["source"] = request.Source,
            ["category"] = request.Category,
            ["isResolved"] = request.IsResolved?.ToString(),
            ["requiresInvestigation"] = request.RequiresInvestigation?.ToString(),
            ["isFalsePositive"] = request.IsFalsePositive?.ToString(),
            ["pageNumber"] = request.PageNumber.ToString(CultureInfo.InvariantCulture),
            ["pageSize"] = request.PageSize.ToString(CultureInfo.InvariantCulture),
            ["sortBy"] = request.SortBy,
            ["sortDirection"] = request.SortDirection
        };
    }

    private static string FormatDate(DateTime date)
        => date.ToString("O", CultureInfo.InvariantCulture);

    private static string? FormatDate(DateTime? date)
        => date?.ToString("O", CultureInfo.InvariantCulture);
}



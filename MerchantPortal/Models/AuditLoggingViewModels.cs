using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

public class AuditLoggingDashboardViewModel
{
    public List<UserActivityLogResponse> UserActivities { get; set; } = new();
    public List<SystemChangeLogResponse> SystemChanges { get; set; } = new();
    public List<SecurityEventLogResponse> SecurityEvents { get; set; } = new();
    public AuditLogAnalyticsResponse? Analytics { get; set; }
    public List<LogAnalysisReportResponse> Reports { get; set; } = new();
    public AuditLoggingFilterViewModel Filter { get; set; } = new();
    public DateTime DefaultStartDate { get; set; }
    public DateTime DefaultEndDate { get; set; }
}

public class AuditLoggingFilterViewModel
{
    [Display(Name = "Start Date")]
    public DateTime? StartDate { get; set; }

    [Display(Name = "End Date")]
    public DateTime? EndDate { get; set; }

    [Display(Name = "User Name")]
    public string? UserName { get; set; }

    [Display(Name = "Activity Type")]
    public string? ActivityType { get; set; }

    [Display(Name = "Entity Type")]
    public string? EntityType { get; set; }

    [Display(Name = "Severity")]
    public string? Severity { get; set; }

    [Display(Name = "Risk Level")]
    public string? RiskLevel { get; set; }

    public int PageSize { get; set; } = 20;
}



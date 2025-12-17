namespace Talabi.Core.DTOs;

public class WorkingHourDto
{
    public int DayOfWeek { get; set; } // 0 = Sunday, 1 = Monday...
    public string DayName { get; set; } = string.Empty; // Localized name: "Pazartesi"
    public string? StartTime { get; set; } // "09:00"
    public string? EndTime { get; set; } // "18:00"
    public bool IsClosed { get; set; }
}

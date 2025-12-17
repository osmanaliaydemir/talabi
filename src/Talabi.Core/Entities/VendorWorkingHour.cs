using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class VendorWorkingHour : BaseEntity
{
    public Guid VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    public DayOfWeek DayOfWeek { get; set; }

    // If null, implies "24 Hours Open" or "Full Day" if IsClosed is false
    // Format: "HH:mm"
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }

    public bool IsClosed { get; set; } = false;
}

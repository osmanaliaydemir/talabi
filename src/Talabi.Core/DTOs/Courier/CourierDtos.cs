namespace Talabi.Core.DTOs.Courier;

public class CourierProfileDto
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public bool IsActive { get; set; }

    public string Status { get; set; } = string.Empty;
    public int MaxActiveOrders { get; set; }
    public int CurrentActiveOrders { get; set; }

    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LastLocationUpdate { get; set; }

    public decimal TotalEarnings { get; set; }
    public decimal CurrentDayEarnings { get; set; }

    public int TotalDeliveries { get; set; }
    public double AverageRating { get; set; }

    public TimeSpan? WorkingHoursStart { get; set; }
    public TimeSpan? WorkingHoursEnd { get; set; }
    public bool IsWithinWorkingHours { get; set; }
}

public class UpdateCourierProfileDto
{
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public int MaxActiveOrders { get; set; } = 3;
    public TimeSpan? WorkingHoursStart { get; set; }
    public TimeSpan? WorkingHoursEnd { get; set; }
    public bool IsWithinWorkingHours { get; set; } = true;
}

public class UpdateCourierStatusDto
{
    public string Status { get; set; } = string.Empty; // "Offline", "Available", "Busy", "Break"
}

public class UpdateCourierLocationDto
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class CourierStatisticsDto
{
    public int TotalDeliveries { get; set; }
    public int TodayDeliveries { get; set; }
    public int WeekDeliveries { get; set; }
    public int MonthDeliveries { get; set; }

    public decimal TotalEarnings { get; set; }
    public decimal TodayEarnings { get; set; }
    public decimal WeekEarnings { get; set; }
    public decimal MonthEarnings { get; set; }

    public double AverageRating { get; set; }
    public int ActiveOrders { get; set; }
    public int TotalRatings { get; set; }
}

public class CourierNotificationDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = "general";
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReadAt { get; set; }
    public Guid? OrderId { get; set; }
}

public class CourierNotificationResponseDto
{
    public IEnumerable<CourierNotificationDto> Items { get; set; } = new List<CourierNotificationDto>();
    public int UnreadCount { get; set; }
}
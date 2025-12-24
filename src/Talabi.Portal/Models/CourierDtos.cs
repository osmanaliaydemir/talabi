using Talabi.Core.Enums;

namespace Talabi.Portal.Models;

public class CourierListDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class CourierDetailDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public int TotalDeliveries { get; set; }
    public double AverageRating { get; set; }
    public decimal TotalEarnings { get; set; }
}

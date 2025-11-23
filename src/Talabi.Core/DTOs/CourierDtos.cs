namespace Talabi.Core.DTOs;

public class CourierDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? VehicleType { get; set; }
    public double? CurrentLatitude { get; set; }
    public double? CurrentLongitude { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
    public bool IsActive { get; set; }
}

public class UpdateCourierLocationDto
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class CourierLocationDto
{
    public int CourierId { get; set; }
    public string CourierName { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime LastUpdate { get; set; }
}


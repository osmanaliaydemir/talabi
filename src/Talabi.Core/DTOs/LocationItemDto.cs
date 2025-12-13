namespace Talabi.Core.DTOs;

public class LocationItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class DistrictWithLocalitiesDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<LocationItemDto> Localities { get; set; } = new();
}

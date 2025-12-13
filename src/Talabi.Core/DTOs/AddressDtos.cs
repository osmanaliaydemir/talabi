namespace Talabi.Core.DTOs;

public class AddressDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public Guid? CityId { get; set; }
    public string? CityName { get; set; }
    public Guid? DistrictId { get; set; }
    public string? DistrictName { get; set; }
    public Guid? LocalityId { get; set; }
    public string? LocalityName { get; set; }
    public string? PostalCode { get; set; }
    public bool IsDefault { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class CreateAddressDto
{
    public string Title { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public Guid? CityId { get; set; }
    public Guid? DistrictId { get; set; }
    public Guid? LocalityId { get; set; }
    public string? PostalCode { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

public class UpdateAddressDto
{
    public string Title { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public Guid? CityId { get; set; }
    public Guid? DistrictId { get; set; }
    public Guid? LocalityId { get; set; }
    public string? PostalCode { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

using System.Text.Json.Serialization;

namespace Talabi.Core.DTOs;

public class DeliveryZoneSyncDto
{
    [JsonPropertyName("cityId")]
    public Guid CityId { get; set; }

    [JsonPropertyName("localityIds")]
    public List<Guid> LocalityIds { get; set; } = new();

    [JsonPropertyName("deliveryFee")]
    public decimal? DeliveryFee { get; set; }

    [JsonPropertyName("minimumOrderAmount")]
    public decimal? MinimumOrderAmount { get; set; }
}

public class CityZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<DistrictZoneDto> Districts { get; set; } = new();
}

public class DistrictZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<LocalityZoneDto> Localities { get; set; } = new();
}

public class LocalityZoneDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsSelected { get; set; }
}

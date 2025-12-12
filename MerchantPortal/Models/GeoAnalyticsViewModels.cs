namespace Getir.MerchantPortal.Models;

public class GeoAnalyticsViewModel
{
    public LocationAnalyticsResponseModel? Analytics { get; set; }
    public DeliveryZoneCoverageResponseModel? Coverage { get; set; }
    public List<NearbyMerchantResponse> NearbyMerchants { get; set; } = new();
    public List<UserLocationResponseModel> LocationHistory { get; set; } = new();
    public GeoAnalyticsFilterViewModel Filter { get; set; } = new();
}

public class GeoAnalyticsFilterViewModel
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double RadiusKm { get; set; } = 5;
    public int? CategoryType { get; set; }
}



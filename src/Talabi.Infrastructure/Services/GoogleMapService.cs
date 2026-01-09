using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Text.Json;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;

namespace Talabi.Infrastructure.Services;

public class GoogleMapService : IMapService
{
    private readonly HttpClient _httpClient;
    private readonly GoogleMapsOptions _options;
    private readonly ILogger<GoogleMapService> _logger;

    public GoogleMapService(HttpClient httpClient, IOptions<GoogleMapsOptions> options, ILogger<GoogleMapService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<double> GetRoadDistanceAsync(double lat1, double lon1, double lat2, double lon2)
    {
        if (string.IsNullOrEmpty(_options.ApiKey))
        {
            _logger.LogWarning("Google Maps API Key is not configured. Falling back to 0 distance.");
            return 0;
        }

        try
        {
            var url = $"https://maps.googleapis.com/maps/api/distancematrix/json?origins={lat1},{lon1}&destinations={lat2},{lon2}&key={_options.ApiKey}";

            var response = await _httpClient.GetAsync(url);
            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(content);
            var root = doc.RootElement;

            if (root.GetProperty("status").GetString() != "OK")
            {
                var status = root.GetProperty("status").GetString();
                _logger.LogError("Google Maps API Error Status: {Status}", status);
                return -1;
            }

            var elements = root.GetProperty("rows")[0].GetProperty("elements");
            if (elements.GetArrayLength() == 0) return -1;

            var element = elements[0];
            var elementStatus = element.GetProperty("status").GetString();

            if (elementStatus != "OK")
            {
                _logger.LogWarning("Google Maps Element Error Status: {Status} for coordinates ({Lat1},{Lon1}) to ({Lat2},{Lon2})", 
                    elementStatus, lat1, lon1, lat2, lon2);
                return -1;
            }

            var distanceInMeters = element.GetProperty("distance").GetProperty("value").GetDouble();
            return distanceInMeters / 1000.0; // Convert to KM
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred while calculating road distance via Google Maps API.");
            return -1;
        }
    }
}

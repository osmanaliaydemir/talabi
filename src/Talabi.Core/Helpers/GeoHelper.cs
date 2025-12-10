namespace Talabi.Core.Helpers;

/// <summary>
/// Coğrafi hesaplamalar için helper class
/// </summary>
public static class GeoHelper
{
    /// <summary>
    /// Dünya yarıçapı (kilometre cinsinden)
    /// </summary>
    private const double EarthRadiusKm = 6371.0;

    /// <summary>
    /// Haversine formülü kullanarak iki koordinat arasındaki mesafeyi kilometre cinsinden hesaplar
    /// </summary>
    /// <param name="lat1">İlk noktanın enlemi (latitude)</param>
    /// <param name="lon1">İlk noktanın boylamı (longitude)</param>
    /// <param name="lat2">İkinci noktanın enlemi (latitude)</param>
    /// <param name="lon2">İkinci noktanın boylamı (longitude)</param>
    /// <returns>İki nokta arasındaki mesafe (kilometre cinsinden)</returns>
    public static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return EarthRadiusKm * c;
    }

    /// <summary>
    /// Dereceyi radyana çevirir
    /// </summary>
    /// <param name="degrees">Derece cinsinden açı</param>
    /// <returns>Radyan cinsinden açı</returns>
    private static double ToRadians(double degrees)
    {
        return degrees * Math.PI / 180.0;
    }
}


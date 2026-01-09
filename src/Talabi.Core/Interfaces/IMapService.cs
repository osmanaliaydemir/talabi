namespace Talabi.Core.Interfaces;

public interface IMapService
{
    /// <summary>
    /// Harita API kullanarak iki nokta arasındaki gerçek yol mesafesini kilometre cinsinden hesaplar
    /// </summary>
    Task<double> GetRoadDistanceAsync(double lat1, double lon1, double lat2, double lon2);
}

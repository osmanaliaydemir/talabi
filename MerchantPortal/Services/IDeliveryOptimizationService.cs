using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IDeliveryOptimizationService
{
	Task<DeliveryCapacityResponse?> CreateCapacityAsync(DeliveryCapacityRequest request, CancellationToken ct = default);
	Task<DeliveryCapacityResponse?> UpdateCapacityAsync(Guid capacityId, DeliveryCapacityRequest request, CancellationToken ct = default);
	Task<DeliveryCapacityResponse?> GetCapacityAsync(Guid merchantId, Guid? deliveryZoneId = null, CancellationToken ct = default);
	Task<DeliveryCapacityCheckResponse?> CheckCapacityAsync(DeliveryCapacityCheckRequest request, CancellationToken ct = default);
	Task<RouteOptimizationResponse?> GetAlternativeRoutesAsync(RouteOptimizationRequest request, CancellationToken ct = default);
	Task<DeliveryRouteResponse?> SelectBestRouteAsync(RouteOptimizationRequest request, bool? avoidTollRoads = null, string? travelMode = null, CancellationToken ct = default);
}



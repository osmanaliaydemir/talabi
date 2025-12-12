using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IDeliveryZoneService
{
	Task<List<DeliveryZoneResponse>?> GetZonesByMerchantAsync(Guid merchantId, CancellationToken ct = default);
	Task<DeliveryZoneResponse?> GetZoneAsync(Guid id, CancellationToken ct = default);
	Task<DeliveryZoneResponse?> CreateZoneAsync(CreateDeliveryZoneRequest request, CancellationToken ct = default);
	Task<DeliveryZoneResponse?> UpdateZoneAsync(Guid id, UpdateDeliveryZoneRequest request, CancellationToken ct = default);
	Task<bool> DeleteZoneAsync(Guid id, CancellationToken ct = default);
}



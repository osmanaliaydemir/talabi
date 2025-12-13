using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IDeliveryZoneService
{
    Task<List<VendorDeliveryZoneDto>> GetVendorZonesAsync(CancellationToken ct = default);
    Task AddZonesAsync(CreateDeliveryZoneViewModel model, CancellationToken ct = default);
    Task<bool> DeleteZoneAsync(Guid id, CancellationToken ct = default);
    Task<bool> UpdateZoneAsync(VendorDeliveryZoneDto dto, CancellationToken ct = default);
}

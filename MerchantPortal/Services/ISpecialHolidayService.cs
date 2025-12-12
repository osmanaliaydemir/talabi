using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ISpecialHolidayService
{
    Task<List<SpecialHolidayResponse>?> GetHolidaysAsync(Guid merchantId, bool includeInactive = false, CancellationToken ct = default);
    Task<List<SpecialHolidayResponse>?> GetUpcomingAsync(Guid merchantId, CancellationToken ct = default);
    Task<SpecialHolidayResponse?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<MerchantAvailabilityResponse?> CheckAvailabilityAsync(Guid merchantId, DateTime? date = null, CancellationToken ct = default);
    Task<SpecialHolidayResponse?> CreateAsync(CreateSpecialHolidayRequest request, CancellationToken ct = default);
    Task<SpecialHolidayResponse?> UpdateAsync(Guid id, UpdateSpecialHolidayRequest request, CancellationToken ct = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken ct = default);
    Task<bool> ToggleStatusAsync(Guid id, CancellationToken ct = default);
}


using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface ISettingsService
{
    Task<VendorSettingsDto?> GetVendorSettingsAsync(CancellationToken ct = default);
    Task<bool> UpdateVendorSettingsAsync(VendorSettingsDto dto, CancellationToken ct = default);

    Task<SystemSettingsDto?> GetSystemSettingsAsync(CancellationToken ct = default);
    Task<bool> UpdateSystemSettingsAsync(SystemSettingsDto dto, CancellationToken ct = default);
}

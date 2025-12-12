using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IHomeService
{
    Task<VendorProfileDto?> GetProfileAsync(CancellationToken ct = default);
}

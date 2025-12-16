using Talabi.Core.Entities;
using Talabi.Portal.Models;
using Talabi.Core.Helpers;
namespace Talabi.Portal.Services;

public interface IVendorService
{
    Task<PagedResult<VendorListDto>> GetVendorsAsync(int page, int pageSize, string? search, string? sortColumn, string? sortDirection);
    Task<VendorDetailDto?> GetVendorByIdAsync(string id);
    Task<bool> UpdateVendorStatusAsync(string id, bool isActive);
    Task<bool> ApproveVendorAsync(string id);
    Task<bool> RejectVendorAsync(string id);
}

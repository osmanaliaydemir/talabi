using Talabi.Core.Entities;
using Talabi.Core.Helpers;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface ICourierService
{
    Task<PagedResult<CourierListDto>> GetCouriersAsync(int page, int pageSize, string? search, string? sortColumn, string? sortDirection);
    Task<CourierDetailDto?> GetCourierByIdAsync(string id);
    Task<bool> UpdateCourierStatusAsync(string id, bool isActive);
    Task<bool> ApproveCourierAsync(string id);
    Task<bool> RejectCourierAsync(string id);
}

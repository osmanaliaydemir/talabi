using Talabi.Core.Enums;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IOrderService
{
    Task<PagedResultDto<VendorOrderDto>?> GetOrdersAsync(int page = 1, int pageSize = 10, OrderStatus? status = null, 
        string? search = null, string? sortBy = null, string sortOrder = "desc", CancellationToken ct = default);

    Task<VendorOrderDetailDto?> GetOrderAsync(Guid id, CancellationToken ct = default);
    Task<bool> UpdateOrderStatusAsync(Guid id, OrderStatus status, CancellationToken ct = default);
}

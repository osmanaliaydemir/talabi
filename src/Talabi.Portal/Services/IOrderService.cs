using Talabi.Core.Enums;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IOrderService
{
    Task<PagedResultDto<VendorOrderDto>?> GetOrdersAsync(int page = 1, int pageSize = 10, OrderStatus? status = null, 
        string? search = null, string? sortBy = null, string sortOrder = "desc", 
        DateTime? startDate = null, DateTime? endDate = null, decimal? minAmount = null, decimal? maxAmount = null,
        CancellationToken ct = default);

    Task<VendorOrderDetailDto?> GetOrderAsync(Guid id, CancellationToken ct = default);
    Task<bool> UpdateOrderStatusAsync(Guid id, OrderStatus status, CancellationToken ct = default);
    Task<bool> RejectOrderAsync(Guid id, string reason, CancellationToken ct = default);
    Task<bool> AssignCourierAsync(Guid id, Guid courierId, CancellationToken ct = default);
    Task<List<AvailableCourierDto>> GetAvailableCouriersAsync(Guid orderId, CancellationToken ct = default);
}

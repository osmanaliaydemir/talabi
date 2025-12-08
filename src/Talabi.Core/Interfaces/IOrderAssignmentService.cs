using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

public interface IOrderAssignmentService
{
    Task<Courier?> FindBestCourierAsync(Order order);
    Task<bool> AssignOrderToCourierAsync(Guid orderId, Guid courierId);
    Task<bool> AcceptOrderAsync(Guid orderId, Guid courierId);
    Task<bool> RejectOrderAsync(Guid orderId, Guid courierId, string reason);
    Task<bool> PickUpOrderAsync(Guid orderId, Guid courierId);
    Task<bool> DeliverOrderAsync(Guid orderId, Guid courierId);
    Task<List<Order>> GetActiveOrdersForCourierAsync(Guid courierId);
    Task<List<OrderCourier>> GetOrderCourierHistoryAsync(Guid orderId);
}

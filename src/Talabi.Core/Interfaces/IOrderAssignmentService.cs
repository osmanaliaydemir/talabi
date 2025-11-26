using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

public interface IOrderAssignmentService
{
    Task<Courier?> FindBestCourierAsync(Order order);
    Task<bool> AssignOrderToCourierAsync(int orderId, int courierId);
    Task<bool> AcceptOrderAsync(int orderId, int courierId);
    Task<bool> RejectOrderAsync(int orderId, int courierId);
    Task<bool> PickUpOrderAsync(int orderId, int courierId);
    Task<bool> DeliverOrderAsync(int orderId, int courierId);
    Task<List<Order>> GetActiveOrdersForCourierAsync(int courierId);
}

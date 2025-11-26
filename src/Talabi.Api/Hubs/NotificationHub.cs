using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Talabi.Api.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    public async Task JoinCourierGroup(int courierId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"courier_{courierId}");
    }

    public async Task JoinOrderTrackingGroup(int orderId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"order_tracking_{orderId}");
    }

    public async Task UpdateLocation(int courierId, double latitude, double longitude)
    {
        // Broadcast to anyone tracking this courier (e.g. admins)
        await Clients.Group($"courier_{courierId}").SendAsync("LocationUpdated", courierId, latitude, longitude);

        // TODO: In a real app, we would find active orders for this courier and broadcast to those specific order tracking groups
        // For now, we can assume the client (mobile app) might send the orderId they are currently delivering for, 
        // or we just broadcast to the courier group and let listeners filter.
    }

    public async Task UpdateOrderLocation(int orderId, double latitude, double longitude)
    {
        await Clients.Group($"order_tracking_{orderId}").SendAsync("OrderLocationUpdated", orderId, latitude, longitude);
    }

    // Notify courier about new order assignment
    public async Task NotifyOrderAssignment(int courierId, int orderId, string vendorName, string deliveryAddress)
    {
        await Clients.Group($"courier_{courierId}").SendAsync("NewOrderAssigned", new
        {
            OrderId = orderId,
            VendorName = vendorName,
            DeliveryAddress = deliveryAddress,
            Timestamp = DateTime.UtcNow
        });
    }

    // Notify customer about order status change
    public async Task NotifyOrderStatusChange(int orderId, string status, string message)
    {
        await Clients.Group($"order_tracking_{orderId}").SendAsync("OrderStatusChanged", new
        {
            OrderId = orderId,
            Status = status,
            Message = message,
            Timestamp = DateTime.UtcNow
        });
    }

    // Notify courier about order cancellation
    public async Task NotifyCourierOrderCancelled(int courierId, int orderId, string reason)
    {
        await Clients.Group($"courier_{courierId}").SendAsync("OrderCancelled", new
        {
            OrderId = orderId,
            Reason = reason,
            Timestamp = DateTime.UtcNow
        });
    }

    // Admin notifications
    public async Task JoinAdminGroup()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, "admin");
    }

    public async Task NotifyAdminNewOrder(int orderId, string customerName, string vendorName)
    {
        await Clients.Group("admin").SendAsync("NewOrderCreated", new
        {
            OrderId = orderId,
            CustomerName = customerName,
            VendorName = vendorName,
            Timestamp = DateTime.UtcNow
        });
    }

    // Vendor notifications
    public async Task JoinVendorGroup(int vendorId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"vendor_{vendorId}");
    }

    public async Task LeaveVendorGroup(int vendorId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"vendor_{vendorId}");
    }

    public async Task NotifyVendorNewOrder(int vendorId, int orderId, string customerName, decimal totalAmount)
    {
        await Clients.Group($"vendor_{vendorId}").SendAsync("NewOrder", new
        {
            OrderId = orderId,
            CustomerName = customerName,
            TotalAmount = totalAmount,
            Timestamp = DateTime.UtcNow
        });
    }

    public async Task NotifyVendorOrderStatusChanged(int vendorId, int orderId, string status)
    {
        await Clients.Group($"vendor_{vendorId}").SendAsync("OrderStatusChanged", new
        {
            OrderId = orderId,
            Status = status,
            Timestamp = DateTime.UtcNow
        });
    }

    public async Task NotifyVendorNewReview(int vendorId, int reviewId, string customerName, int rating)
    {
        await Clients.Group($"vendor_{vendorId}").SendAsync("NewReview", new
        {
            ReviewId = reviewId,
            CustomerName = customerName,
            Rating = rating,
            Timestamp = DateTime.UtcNow
        });
    }
}

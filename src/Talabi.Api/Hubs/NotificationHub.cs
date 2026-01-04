using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Talabi.Api.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    public async Task JoinCourierGroup(string courierId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"courier_{courierId}");
    }

    public async Task JoinOrderTrackingGroup(string orderId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"order_tracking_{orderId}");
    }

    public async Task UpdateLocation(string courierId, double latitude, double longitude)
    {
        // Broadcast to anyone tracking this courier (e.g. admins)
        await Clients.Group($"courier_{courierId}").SendAsync("LocationUpdated", courierId, latitude, longitude);
    }

    public async Task UpdateOrderLocation(string orderId, double latitude, double longitude)
    {
        await Clients.Group($"order_tracking_{orderId}")
            .SendAsync("OrderLocationUpdated", orderId, latitude, longitude);
    }

    // Notify courier about new order assignment
    public async Task NotifyOrderAssignment(string courierId, string orderId, string vendorName, string deliveryAddress)
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
    public async Task NotifyOrderStatusChange(string orderId, string status, string message)
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
    public async Task NotifyCourierOrderCancelled(string courierId, string orderId, string reason)
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

    public async Task NotifyAdminNewOrder(string orderId, string customerName, string vendorName)
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
    public async Task JoinVendorGroup(string vendorId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"vendor_{vendorId}");
    }

    public async Task LeaveVendorGroup(string vendorId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"vendor_{vendorId}");
    }

    public async Task NotifyVendorNewOrder(string vendorId, string orderId, string customerName, decimal totalAmount)
    {
        await Clients.Group($"vendor_{vendorId}").SendAsync("NewOrder", new
        {
            OrderId = orderId,
            CustomerName = customerName,
            TotalAmount = totalAmount,
            Timestamp = DateTime.UtcNow
        });
    }

    public async Task NotifyVendorOrderStatusChanged(string vendorId, string orderId, string status)
    {
        await Clients.Group($"vendor_{vendorId}").SendAsync("OrderStatusChanged", new
        {
            OrderId = orderId,
            Status = status,
            Timestamp = DateTime.UtcNow
        });
    }

    public async Task NotifyVendorNewReview(string vendorId, string reviewId, string customerName, int rating)
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

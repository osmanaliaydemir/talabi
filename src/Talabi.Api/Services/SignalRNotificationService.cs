using Microsoft.AspNetCore.SignalR;
using Talabi.Api.Hubs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Services;

public class SignalRNotificationService : INotificationService
{
    private readonly IHubContext<NotificationHub> _hubContext;

    public SignalRNotificationService(IHubContext<NotificationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task SendOrderAssignmentNotificationAsync(string userId, int orderId)
    {
        await _hubContext.Clients.User(userId).SendAsync("ReceiveOrderAssignment", orderId);
    }

    public async Task SendOrderStatusUpdateNotificationAsync(string userId, int orderId, string status)
    {
        await _hubContext.Clients.User(userId).SendAsync("ReceiveOrderStatusUpdate", orderId, status);
    }
}

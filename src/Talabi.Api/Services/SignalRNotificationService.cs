using Microsoft.AspNetCore.SignalR;
using Talabi.Api.Hubs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Services;

public class SignalRNotificationService(IHubContext<NotificationHub> hubContext) : ISignalRNotificationService
{
    public async Task SendNotificationAsync(string token, string title, string body, object? data = null)
    {
        // SignalR uses userId instead of token, so we'll treat token as userId
        await hubContext.Clients.User(token).SendAsync("ReceiveNotification", new
        {
            title,
            body,
            data
        });
    }

    public async Task SendMulticastNotificationAsync(List<string> tokens, string title, string body,
        object? data = null)
    {
        // Send to multiple users
        foreach (var token in tokens)
        {
            await SendNotificationAsync(token, title, body, data);
        }
    }

    public Task RegisterDeviceTokenAsync(string userId, string token, string deviceType)
    {
        // SignalR doesn't need device token registration, connections are managed automatically
        // This is a no-op for SignalR implementation
        return Task.CompletedTask;
    }

    public async Task SendOrderAssignmentNotificationAsync(string userId, Guid orderId, string? languageCode = null)
    {
        await hubContext.Clients.User(userId).SendAsync("ReceiveOrderAssignment", new
        {
            orderId,
            languageCode
        });
    }

    public async Task SendOrderStatusUpdateNotificationAsync(string userId, Guid orderId, string status,
        string? languageCode = null)
    {
        await hubContext.Clients.User(userId).SendAsync("ReceiveOrderStatusUpdate", new
        {
            orderId,
            status,
            languageCode
        });
    }

    public async Task SendNewOrderNotificationAsync(string userId, Guid orderId, string? languageCode = null)
    {
        await hubContext.Clients.User(userId).SendAsync("ReceiveNewOrder", new
        {
            orderId,
            languageCode
        });
    }

    public async Task SendCourierAcceptedNotificationAsync(string userId, Guid orderId, string? languageCode = null)
    {
        await hubContext.Clients.User(userId).SendAsync("ReceiveCourierAccepted", new
        {
            orderId,
            languageCode
        });
    }
}

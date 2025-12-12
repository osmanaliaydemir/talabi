using Microsoft.AspNetCore.SignalR.Client;

namespace Getir.MerchantPortal.Services;

public interface ISignalRService
{
    /// <summary>
    /// Sipariş hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Sipariş hub bağlantısı</returns>
    Task<HubConnection> CreateOrderHubConnectionAsync(string token);
    /// <summary>
    /// Notification hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Notification hub bağlantısı</returns>
    Task<HubConnection> CreateNotificationHubConnectionAsync(string token);
    /// <summary>
    /// Courier hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Courier hub bağlantısı</returns>
    Task<HubConnection> CreateCourierHubConnectionAsync(string token);
    /// <summary>
    /// SignalR bağlantısını başlatır.
    /// </summary>
    /// <param name="connection">SignalR bağlantısı</param>
    Task StartConnectionAsync(HubConnection connection);
    /// <summary>
    /// SignalR bağlantısını durdurur.
    /// </summary>
    /// <param name="connection">SignalR bağlantısı</param>
    /// </summary>
    Task StopConnectionAsync(HubConnection connection);
}


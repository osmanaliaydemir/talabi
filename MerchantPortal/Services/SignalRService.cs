using Microsoft.AspNetCore.SignalR.Client;

namespace Getir.MerchantPortal.Services;

public class SignalRService : ISignalRService
{
    private readonly ApiSettings _apiSettings;
    private readonly ILogger<SignalRService> _logger;

    public SignalRService(ApiSettings apiSettings, ILogger<SignalRService> logger)
    {
        _apiSettings = apiSettings;
        _logger = logger;
    }

    /// <summary>
    /// Sipariş hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Sipariş hub bağlantısı</returns>
    public Task<HubConnection> CreateOrderHubConnectionAsync(string token)
    {
        var hubUrl = $"{_apiSettings.SignalRHubUrl}/orders";
        var connection = BuildConnection(hubUrl, token);
        return Task.FromResult(connection);
    }

    /// <summary>
    /// Notification hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Notification hub bağlantısı</returns>
    public Task<HubConnection> CreateNotificationHubConnectionAsync(string token)
    {
        var hubUrl = $"{_apiSettings.SignalRHubUrl}/notifications";
        var connection = BuildConnection(hubUrl, token);
        return Task.FromResult(connection);
    }

    /// <summary>
    /// Courier hub bağlantısı oluşturur.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Courier hub bağlantısı</returns>
    public Task<HubConnection> CreateCourierHubConnectionAsync(string token)
    {
        var hubUrl = $"{_apiSettings.SignalRHubUrl}/courier";
        var connection = BuildConnection(hubUrl, token);
        return Task.FromResult(connection);
    }

    /// <summary>
    /// SignalR bağlantısını başlatır.
    /// </summary>
    /// <param name="connection">SignalR bağlantısı</param>
    public async Task StartConnectionAsync(HubConnection connection)
    {
        try
        {
            if (connection.State == HubConnectionState.Disconnected)
            {
                await connection.StartAsync();
                _logger.LogInformation("SignalR connection started successfully");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting SignalR connection");
            throw;
        }
    }

    /// <summary>
    /// SignalR bağlantısını durdurur.
    /// </summary>
    /// <param name="connection">SignalR bağlantısı</param>
    public async Task StopConnectionAsync(HubConnection connection)
    {
        try
        {
            if (connection.State == HubConnectionState.Connected)
            {
                await connection.StopAsync();
                _logger.LogInformation("SignalR connection stopped successfully");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error stopping SignalR connection");
        }
    }

    /// <summary>
    /// SignalR bağlantısı oluşturur.
    /// </summary>
    /// <param name="hubUrl">Hub URL</param>
    /// <param name="token">Token</param>
    /// <returns>SignalR bağlantısı</returns>
    private HubConnection BuildConnection(string hubUrl, string token)
    {
        return new HubConnectionBuilder()
            .WithUrl(hubUrl, options =>
            {
                options.AccessTokenProvider = () => Task.FromResult<string?>(token);
                options.Headers.Add("Authorization", $"Bearer {token}");
            })
            .WithAutomaticReconnect(new[] { TimeSpan.Zero, TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(5), TimeSpan.FromSeconds(10) })
            .Build();
    }
}


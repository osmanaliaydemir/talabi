using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class OrderService : IOrderService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<OrderService> _logger;

    public OrderService(IApiClient apiClient, ILogger<OrderService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    /// <summary>
    /// Siparişleri getirir.
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="status">Sipariş durumu</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Siparişler</returns>
    public async Task<PagedResult<OrderResponse>?> GetOrdersAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/v1/merchants/merchantorder?page={page}&pageSize={pageSize}";
            if (!string.IsNullOrEmpty(status))
            {
                endpoint += $"&status={status}";
            }

            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<OrderResponse>>>(endpoint, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting orders");
            return null;
        }
    }

    /// <summary>
    /// Sipariş detaylarını getirir.
    /// </summary>
    /// <param name="orderId">Sipariş ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Sipariş detayları</returns>
    public async Task<OrderDetailsResponse?> GetOrderDetailsAsync(Guid orderId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<OrderDetailsResponse>>(
                $"api/v1/merchants/merchantorder/{orderId}",
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting order details {OrderId}", orderId);
            return null;
        }
    }

    /// <summary>
    /// Sipariş durumunu günceller.
    /// </summary>
    /// <param name="orderId">Sipariş ID</param>
    /// <param name="request">Sipariş durum güncelleme isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> UpdateOrderStatusAsync(Guid orderId, UpdateOrderStatusRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<OrderResponse>>(
                $"api/v1/merchants/merchantorder/{orderId}/status",
                request,
                ct);

            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order status {OrderId}", orderId);
            return false;
        }
    }

    /// <summary>
    /// Bekleyen siparişleri getirir.
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Bekleyen siparişler</returns>
    public async Task<PagedResult<OrderResponse>?> GetPendingOrdersAsync(int page = 1, int pageSize = 20, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<OrderResponse>>>(
                $"api/v1/merchants/merchantorder/pending?page={page}&pageSize={pageSize}",
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting pending orders");
            return null;
        }
    }
}


using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IOrderService
{
    /// <summary>
    /// Siparişleri getirir.
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="status">Sipariş durumu</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Siparişler</returns>
    Task<PagedResult<OrderResponse>?> GetOrdersAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default);
    /// <summary>
    /// Sipariş detaylarını getirir.
    /// </summary>
    /// <param name="orderId">Sipariş ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Sipariş detayları</returns>
    Task<OrderDetailsResponse?> GetOrderDetailsAsync(Guid orderId, CancellationToken ct = default);
    /// <summary>
    /// Sipariş durumunu günceller.
    /// </summary>
    /// <param name="orderId">Sipariş ID</param>
    /// <param name="request">Sipariş durum güncelleme isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> UpdateOrderStatusAsync(Guid orderId, UpdateOrderStatusRequest request, CancellationToken ct = default);
    /// <summary>
    /// Bekleyen siparişleri getirir.
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Bekleyen siparişler</returns>
    Task<PagedResult<OrderResponse>?> GetPendingOrdersAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
}


using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

/// <summary>
/// Sipariş işlemleri için service interface
/// </summary>
public interface IOrderService
{
    /// <summary>
    /// Benzersiz müşteri sipariş ID'si oluşturur
    /// </summary>
    Task<string> GenerateUniqueCustomerOrderIdAsync();

    /// <summary>
    /// Benzersiz müşteri sipariş ürün ID'si oluşturur
    /// </summary>
    Task<string> GenerateUniqueCustomerOrderItemIdAsync();

    /// <summary>
    /// Yeni sipariş oluşturur
    /// </summary>
    /// <param name="dto">Sipariş bilgileri</param>
    /// <param name="customerId">Müşteri ID'si</param>
    /// <param name="culture">Kültür bilgisi (localization için)</param>
    /// <returns>Oluşturulan sipariş</returns>
    Task<Order> CreateOrderAsync(CreateOrderDto dto, string customerId, System.Globalization.CultureInfo culture);

    /// <summary>
    /// Siparişi iptal eder
    /// </summary>
    /// <param name="orderId">Sipariş ID'si</param>
    /// <param name="userId">Kullanıcı ID'si</param>
    /// <param name="dto">İptal bilgileri</param>
    /// <param name="culture">Kültür bilgisi (localization için)</param>
    /// <returns>İşlem başarılı mı</returns>
    Task<bool> CancelOrderAsync(Guid orderId, string? userId, CancelOrderDto dto, System.Globalization.CultureInfo culture);

    /// <summary>
    /// Sipariş durumunu günceller
    /// </summary>
    /// <param name="orderId">Sipariş ID'si</param>
    /// <param name="dto">Güncellenecek durum bilgileri</param>
    /// <param name="userId">Kullanıcı ID'si (status history için)</param>
    /// <param name="culture">Kültür bilgisi (localization için)</param>
    /// <returns>İşlem başarılı mı</returns>
    Task<bool> UpdateOrderStatusAsync(Guid orderId, UpdateOrderStatusDto dto, string? userId, System.Globalization.CultureInfo culture);

    /// <summary>
    /// Sipariş tutarlarını hesaplar
    /// </summary>
    /// <param name="dto">Hesaplama kriterleri</param>
    /// <param name="userId">Kullanıcı ID'si (opsiyonel)</param>
    /// <param name="culture">Kültür bilgisi</param>
    /// <returns>Hesaplama sonucu</returns>
    Task<OrderCalculationResultDto> CalculateOrderAsync(CalculateOrderDto dto, string? userId, System.Globalization.CultureInfo culture);
}


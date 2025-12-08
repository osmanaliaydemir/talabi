using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Extensions;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Müşteri bildirim işlemleri için controller
/// </summary>
[Route("api/customer/notifications")]
[ApiController]
[Authorize]
public class CustomerNotificationsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<AppUser> _userManager;
    private readonly ILogger<CustomerNotificationsController> _logger;

    /// <summary>
    /// CustomerNotificationsController constructor
    /// </summary>
    public CustomerNotificationsController(IUnitOfWork unitOfWork, UserManager<AppUser> userManager, ILogger<CustomerNotificationsController> logger)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Customer?> GetCurrentCustomerAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var customer = await _unitOfWork.Customers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (customer == null && createIfMissing)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return null;
            }

            customer = new Customer
            {
                UserId = user.Id,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Customers.AddAsync(customer);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Customer profile auto-created for notifications. UserId: {UserId}", userId);
        }

        return customer;
    }

    /// <summary>
    /// Müşterinin bildirimlerini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20, maksimum: 100)</param>
    /// <returns>Bildirim listesi ve okunmamış sayısı</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<CustomerNotificationResponseDto>>> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            _logger.LogWarning("Customer not found for notifications (UserId: {UserId})", GetUserId());
            var emptyResponse = new CustomerNotificationResponseDto
            {
                Items = Array.Empty<CustomerNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<CustomerNotificationResponseDto>(emptyResponse, "Müşteri profili bulunamadı, boş bildirim listesi döndürülüyor"));
        }

        await EnsureWelcomeNotificationAsync(customer.Id);

        IQueryable<CustomerNotification> query = _unitOfWork.CustomerNotifications.Query()
            .Where(n => n.CustomerId == customer.Id);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        IOrderedQueryable<CustomerNotification> orderedQuery = query.OrderByDescending(n => n.CreatedAt);

        // Gelişmiş query helper kullanımı - Pagination
        var notifications = await orderedQuery
            .Paginate(page, pageSize)
            .Select(n => new CustomerNotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                Type = n.Type,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt,
                ReadAt = n.ReadAt,
                OrderId = n.OrderId
            })
            .ToListAsync();

        var response = new CustomerNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        };

        return Ok(new ApiResponse<CustomerNotificationResponseDto>(response, "Bildirimler başarıyla getirildi"));
    }

    /// <summary>
    /// Belirli bir bildirimi okundu olarak işaretler
    /// </summary>
    /// <param name="id">Bildirim ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/read")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAsRead(Guid id)
    {
        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            return NotFound(new ApiResponse<object>("Müşteri profili bulunamadı", "CUSTOMER_PROFILE_NOT_FOUND"));
        }

        var notification = await _unitOfWork.CustomerNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.CustomerId == customer.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>("Bildirim bulunamadı", "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CustomerNotifications.Update(notification);
            await _unitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { }, "Bildirim okundu olarak işaretlendi"));
    }

    /// <summary>
    /// Tüm bildirimleri okundu olarak işaretler
    /// </summary>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("read-all")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAllAsRead()
    {
        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            return NotFound(new ApiResponse<object>("Müşteri profili bulunamadı", "CUSTOMER_PROFILE_NOT_FOUND"));
        }

        var unreadNotifications = await _unitOfWork.CustomerNotifications.Query()
            .Where(n => n.CustomerId == customer.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new ApiResponse<object>(new { }, "Tüm bildirimler zaten okunmuş"));
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CustomerNotifications.Update(notification);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Tüm bildirimler okundu olarak işaretlendi"));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid customerId)
    {
        var hasNotification = await _unitOfWork.CustomerNotifications.Query()
            .AnyAsync(n => n.CustomerId == customerId);

        if (!hasNotification)
        {
            await _unitOfWork.CustomerNotifications.AddAsync(new CustomerNotification
            {
                CustomerId = customerId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Sipariş durumları ve özel teklifler hakkında buradan bildirim alacaksın.",
                Type = "info"
            });

            await _unitOfWork.SaveChangesAsync();
        }
    }
}


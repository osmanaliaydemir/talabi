using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
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
public class CustomerNotificationsController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private const string ResourceName = "CustomerNotificationResources";

    /// <summary>
    /// CustomerNotificationsController constructor
    /// </summary>
    public CustomerNotificationsController(
        IUnitOfWork unitOfWork,
        ILogger<CustomerNotificationsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        UserManager<AppUser> userManager)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
    }

    private async Task<Customer?> GetCurrentCustomerAsync(bool createIfMissing = false)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return null;
        }

        var customer = await UnitOfWork.Customers.Query()
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

            await UnitOfWork.Customers.AddAsync(customer);
            await UnitOfWork.SaveChangesAsync();

            Logger.LogInformation("Customer profile auto-created for notifications. UserId: {UserId}", userId);
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
    public async Task<ActionResult<ApiResponse<CustomerNotificationResponseDto>>> GetNotifications(
        [FromQuery] int page = 1, 
        [FromQuery] int pageSize = 20)
    {
        
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            var userId = UserContext.GetUserId();
            Logger.LogWarning("Customer not found for notifications (UserId: {UserId})", userId);
            var emptyResponse = new CustomerNotificationResponseDto
            {
                Items = Array.Empty<CustomerNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<CustomerNotificationResponseDto>(
                emptyResponse, 
                LocalizationService.GetLocalizedString(ResourceName, "CustomerProfileNotFoundEmptyList", CurrentCulture)));
        }

        await EnsureWelcomeNotificationAsync(customer.Id);

        IQueryable<CustomerNotification> query = UnitOfWork.CustomerNotifications.Query()
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

        return Ok(new ApiResponse<CustomerNotificationResponseDto>(
            response, 
            LocalizationService.GetLocalizedString(ResourceName, "NotificationsRetrievedSuccessfully", CurrentCulture)));
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
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CustomerProfileNotFound", CurrentCulture), 
                "CUSTOMER_PROFILE_NOT_FOUND"));
        }

        var notification = await UnitOfWork.CustomerNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.CustomerId == customer.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "NotificationNotFound", CurrentCulture), 
                "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.CustomerNotifications.Update(notification);
            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "NotificationMarkedAsRead", CurrentCulture)));
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
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CustomerProfileNotFound", CurrentCulture), 
                "CUSTOMER_PROFILE_NOT_FOUND"));
        }

        var unreadNotifications = await UnitOfWork.CustomerNotifications.Query()
            .Where(n => n.CustomerId == customer.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new ApiResponse<object>(
                new { }, 
                LocalizationService.GetLocalizedString(ResourceName, "AllNotificationsAlreadyRead", CurrentCulture)));
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.CustomerNotifications.Update(notification);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "AllNotificationsMarkedAsRead", CurrentCulture)));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid customerId)
    {
        var hasNotification = await UnitOfWork.CustomerNotifications.Query()
            .AnyAsync(n => n.CustomerId == customerId);

        if (!hasNotification)
        {
            await UnitOfWork.CustomerNotifications.AddAsync(new CustomerNotification
            {
                CustomerId = customerId,
                Title = LocalizationService.GetLocalizedString(ResourceName, "WelcomeTitle", CurrentCulture),
                Message = LocalizationService.GetLocalizedString(ResourceName, "WelcomeMessage", CurrentCulture),
                Type = "info"
            });

            await UnitOfWork.SaveChangesAsync();
        }
    }
}


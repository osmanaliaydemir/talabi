using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kurye bildirim işlemleri için controller
/// </summary>
[Route("api/courier/notifications")]
[ApiController]
[Authorize(Roles = "Courier")]
public class CourierNotificationsController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private const string ResourceName = "CourierNotificationResources";

    /// <summary>
    /// CourierNotificationsController constructor
    /// </summary>
    public CourierNotificationsController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<CourierNotificationsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
    }

    private async Task<Courier?> GetCurrentCourierAsync(bool createIfMissing = false)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }
        var courier = await UnitOfWork.Couriers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (courier == null && createIfMissing)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return null;
            }

            courier = new Courier
            {
                UserId = user.Id,
                Name = user.FullName ?? user.Email ?? "Courier",
                PhoneNumber = user.PhoneNumber,
                IsActive = true,
                Status = CourierStatus.Offline,
                CreatedAt = DateTime.UtcNow
            };

            await UnitOfWork.Couriers.AddAsync(courier);
            await UnitOfWork.SaveChangesAsync();

            Logger.LogInformation("Courier profile auto-created for notifications. UserId: {UserId}", userId);
        }

        return courier;
    }

    /// <summary>
    /// Kuryenin bildirimlerini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20, maksimum: 100)</param>
    /// <returns>Bildirim listesi ve okunmamış sayısı</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<CourierNotificationResponseDto>>> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            var userId = UserContext.GetUserId();
            Logger.LogWarning("Courier not found for notifications (UserId: {UserId})", userId);
            var emptyResponse = new CourierNotificationResponseDto
            {
                Items = Array.Empty<CourierNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<CourierNotificationResponseDto>(emptyResponse, LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFoundReturningEmpty", CurrentCulture)));
        }

        await EnsureWelcomeNotificationAsync(courier.Id);

        IQueryable<CourierNotification> query = UnitOfWork.CourierNotifications.Query()
            .Where(n => n.CourierId == courier.Id);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        IOrderedQueryable<CourierNotification> orderedQuery = query.OrderByDescending(n => n.CreatedAt);

        // Gelişmiş query helper kullanımı - Pagination
        var notifications = await orderedQuery
            .Paginate(page, pageSize)
            .Select(n => new CourierNotificationDto
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

        var response = new CourierNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        };

        return Ok(new ApiResponse<CourierNotificationResponseDto>(response, LocalizationService.GetLocalizedString(ResourceName, "NotificationsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir bildirimi okundu olarak işaretler
    /// </summary>
    /// <param name="id">Bildirim ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/read")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAsRead(Guid id)
    {
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var notification = await UnitOfWork.CourierNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.CourierId == courier.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotificationNotFound", CurrentCulture), "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.CourierNotifications.Update(notification);
            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "NotificationMarkedAsRead", CurrentCulture)));
    }

    /// <summary>
    /// Tüm bildirimleri okundu olarak işaretler
    /// </summary>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("read-all")]
    public async Task<ActionResult<ApiResponse<object>>> MarkAllAsRead()
    {
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var unreadNotifications = await UnitOfWork.CourierNotifications.Query()
            .Where(n => n.CourierId == courier.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "AllNotificationsAreAlreadyRead", CurrentCulture)));
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.CourierNotifications.Update(notification);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "AllNotificationsMarkedAsRead", CurrentCulture)));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid courierId)
    {
        var hasNotification = await UnitOfWork.CourierNotifications.Query()
            .AnyAsync(n => n.CourierId == courierId);

        if (!hasNotification)
        {
            await UnitOfWork.CourierNotifications.AddAsync(new CourierNotification
            {
                CourierId = courierId,
                Title = LocalizationService.GetLocalizedString(ResourceName, "WelcomeTitle", CurrentCulture),
                Message = LocalizationService.GetLocalizedString(ResourceName, "WelcomeMessage", CurrentCulture),
                Type = "info"
            });

            await UnitOfWork.SaveChangesAsync();
        }
    }
}


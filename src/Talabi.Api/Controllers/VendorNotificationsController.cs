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
/// Satıcı bildirim işlemleri için controller
/// </summary>
[Route("api/vendor/notifications")]
[ApiController]
[Authorize(Roles = "Vendor")]
public class VendorNotificationsController(
    IUnitOfWork unitOfWork,
    ILogger<VendorNotificationsController> logger,
    ILocalizationService localizationService,
    IUserContextService userContext,
    UserManager<AppUser> userManager)
    : BaseController(unitOfWork, logger, localizationService, userContext)
{
    private readonly UserManager<AppUser> _userManager = userManager;
    private const string ResourceName = "VendorNotificationResources";

    private async Task<Vendor?> GetCurrentVendorAsync(bool createIfMissing = false)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return null;
        }

        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null && createIfMissing)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return null;
            }

            // Vendor profile should already exist, but if not, we can't auto-create it
            // as it requires business information
            Logger.LogWarning("Vendor profile not found for notifications (UserId: {UserId})", userId);
        }

        return vendor;
    }

    /// <summary>
    /// Satıcının bildirimlerini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20, maksimum: 100)</param>
    /// <returns>Bildirim listesi ve okunmamış sayısı</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<VendorNotificationResponseDto>>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            var userId = UserContext.GetUserId();
            Logger.LogWarning("Vendor not found for notifications (UserId: {UserId})", userId);
            var emptyResponse = new VendorNotificationResponseDto
            {
                Items = Array.Empty<VendorNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<VendorNotificationResponseDto>(
                emptyResponse,
                LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFoundEmptyList", CurrentCulture)));
        }

        await EnsureWelcomeNotificationAsync(vendor.Id);

        IQueryable<VendorNotification> query = UnitOfWork.VendorNotifications.Query()
            .Where(n => n.VendorId == vendor.Id);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        IOrderedQueryable<VendorNotification> orderedQuery = query.OrderByDescending(n => n.CreatedAt);

        // Gelişmiş query helper kullanımı - Pagination
        var notifications = await orderedQuery
            .Paginate(page, pageSize)
            .Select(n => new VendorNotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                Type = n.Type,
                IsRead = n.IsRead,
                RelatedEntityId = n.RelatedEntityId,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();

        var response = new VendorNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        };

        return Ok(new ApiResponse<VendorNotificationResponseDto>(
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
        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var notification = await UnitOfWork.VendorNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.VendorId == vendor.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "NotificationNotFound", CurrentCulture),
                "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.VendorNotifications.Update(notification);
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
        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var unreadNotifications = await UnitOfWork.VendorNotifications.Query()
            .Where(n => n.VendorId == vendor.Id && !n.IsRead)
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
            notification.UpdatedAt = DateTime.UtcNow;
            UnitOfWork.VendorNotifications.Update(notification);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "AllNotificationsMarkedAsRead", CurrentCulture)));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid vendorId)
    {
        var hasNotification = await UnitOfWork.VendorNotifications.Query()
            .AnyAsync(n => n.VendorId == vendorId);

        if (!hasNotification)
        {
            await UnitOfWork.VendorNotifications.AddAsync(new VendorNotification
            {
                VendorId = vendorId,
                Title = LocalizationService.GetLocalizedString(ResourceName, "WelcomeTitle", CurrentCulture),
                Message = LocalizationService.GetLocalizedString(ResourceName, "WelcomeMessage", CurrentCulture),
                Type = "info"
            });

            await UnitOfWork.SaveChangesAsync();
        }
    }
}


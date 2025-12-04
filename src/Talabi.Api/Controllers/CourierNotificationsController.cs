using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
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
public class CourierNotificationsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<AppUser> _userManager;
    private readonly ILogger<CourierNotificationsController> _logger;

    /// <summary>
    /// CourierNotificationsController constructor
    /// </summary>
    public CourierNotificationsController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<CourierNotificationsController> logger)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Courier?> GetCurrentCourierAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var courier = await _unitOfWork.Couriers.Query()
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

            await _unitOfWork.Couriers.AddAsync(courier);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Courier profile auto-created for notifications. UserId: {UserId}", userId);
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
    public async Task<ActionResult<ApiResponse<CourierNotificationResponseDto>>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            _logger.LogWarning("Courier not found for notifications (UserId: {UserId})", GetUserId());
            var emptyResponse = new CourierNotificationResponseDto
            {
                Items = Array.Empty<CourierNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<CourierNotificationResponseDto>(emptyResponse, "Kurye profili bulunamadı, boş bildirim listesi döndürülüyor"));
        }

        await EnsureWelcomeNotificationAsync(courier.Id);

        IQueryable<CourierNotification> query = _unitOfWork.CourierNotifications.Query()
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

        return Ok(new ApiResponse<CourierNotificationResponseDto>(response, "Bildirimler başarıyla getirildi"));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var notification = await _unitOfWork.CourierNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.CourierId == courier.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>("Bildirim bulunamadı", "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.CourierNotifications.Update(notification);
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
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var unreadNotifications = await _unitOfWork.CourierNotifications.Query()
            .Where(n => n.CourierId == courier.Id && !n.IsRead)
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
            _unitOfWork.CourierNotifications.Update(notification);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Tüm bildirimler okundu olarak işaretlendi"));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid courierId)
    {
        var hasNotification = await _unitOfWork.CourierNotifications.Query()
            .AnyAsync(n => n.CourierId == courierId);

        if (!hasNotification)
        {
            await _unitOfWork.CourierNotifications.AddAsync(new CourierNotification
            {
                CourierId = courierId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Yeni siparişler aldıkça buradan bildirim alacaksın.",
                Type = "info"
            });

            await _unitOfWork.SaveChangesAsync();
        }
    }
}


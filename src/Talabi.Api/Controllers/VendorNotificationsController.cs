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
/// Satıcı bildirim işlemleri için controller
/// </summary>
[Route("api/vendor/notifications")]
[ApiController]
[Authorize(Roles = "Vendor")]
public class VendorNotificationsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<AppUser> _userManager;
    private readonly ILogger<VendorNotificationsController> _logger;

    /// <summary>
    /// VendorNotificationsController constructor
    /// </summary>
    public VendorNotificationsController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<VendorNotificationsController> logger)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Vendor?> GetCurrentVendorAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var vendor = await _unitOfWork.Vendors.Query()
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
            _logger.LogWarning("Vendor profile not found for notifications (UserId: {UserId})", userId);
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
    public async Task<ActionResult<ApiResponse<VendorNotificationResponseDto>>> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            _logger.LogWarning("Vendor not found for notifications (UserId: {UserId})", GetUserId());
            var emptyResponse = new VendorNotificationResponseDto
            {
                Items = Array.Empty<VendorNotificationDto>(),
                UnreadCount = 0
            };
            return Ok(new ApiResponse<VendorNotificationResponseDto>(emptyResponse, "Satıcı profili bulunamadı, boş bildirim listesi döndürülüyor"));
        }

        await EnsureWelcomeNotificationAsync(vendor.Id);

        IQueryable<VendorNotification> query = _unitOfWork.VendorNotifications.Query()
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

        return Ok(new ApiResponse<VendorNotificationResponseDto>(response, "Bildirimler başarıyla getirildi"));
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
            return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_NOT_FOUND"));
        }

        var notification = await _unitOfWork.VendorNotifications.Query()
            .FirstOrDefaultAsync(n => n.Id == id && n.VendorId == vendor.Id);

        if (notification == null)
        {
            return NotFound(new ApiResponse<object>("Bildirim bulunamadı", "NOTIFICATION_NOT_FOUND"));
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.VendorNotifications.Update(notification);
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
        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_NOT_FOUND"));
        }

        var unreadNotifications = await _unitOfWork.VendorNotifications.Query()
            .Where(n => n.VendorId == vendor.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new ApiResponse<object>(new { }, "Tüm bildirimler zaten okunmuş"));
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.VendorNotifications.Update(notification);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Tüm bildirimler okundu olarak işaretlendi"));
    }

    private async Task EnsureWelcomeNotificationAsync(Guid vendorId)
    {
        var hasNotification = await _unitOfWork.VendorNotifications.Query()
            .AnyAsync(n => n.VendorId == vendorId);

        if (!hasNotification)
        {
            await _unitOfWork.VendorNotifications.AddAsync(new VendorNotification
            {
                VendorId = vendorId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Yeni siparişler ve güncellemeler buradan bildirim alacaksın.",
                Type = "info"
            });

            await _unitOfWork.SaveChangesAsync();
        }
    }
}


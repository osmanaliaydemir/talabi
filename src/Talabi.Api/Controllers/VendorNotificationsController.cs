using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/notifications")]
[ApiController]
[Authorize(Roles = "Vendor")]
public class VendorNotificationsController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<VendorNotificationsController> _logger;

    public VendorNotificationsController(
        TalabiDbContext context,
        ILogger<VendorNotificationsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Vendor?> GetCurrentVendorAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var vendor = await _context.Vendors.FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null && createIfMissing)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
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

    [HttpGet]
    public async Task<ActionResult<VendorNotificationResponseDto>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            _logger.LogWarning("Vendor not found for notifications (UserId: {UserId})", GetUserId());
            return Ok(new VendorNotificationResponseDto
            {
                Items = Array.Empty<VendorNotificationDto>(),
                UnreadCount = 0
            });
        }

        await EnsureWelcomeNotificationAsync(vendor.Id);

        var query = _context.VendorNotifications
            .Where(n => n.VendorId == vendor.Id)
            .OrderByDescending(n => n.CreatedAt);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        var notifications = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
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

        return Ok(new VendorNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        });
    }

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            return NotFound(new { Message = "Vendor profile not found" });
        }

        var notification = await _context.VendorNotifications
            .FirstOrDefaultAsync(n => n.Id == id && n.VendorId == vendor.Id);

        if (notification == null)
        {
            return NotFound(new { Message = "Notification not found" });
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        return Ok(new { Message = "Notification marked as read" });
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var vendor = await GetCurrentVendorAsync(createIfMissing: false);
        if (vendor == null)
        {
            return NotFound(new { Message = "Vendor profile not found" });
        }

        var unreadNotifications = await _context.VendorNotifications
            .Where(n => n.VendorId == vendor.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new { Message = "All notifications are already read" });
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return Ok(new { Message = "All notifications marked as read" });
    }

    private async Task EnsureWelcomeNotificationAsync(int vendorId)
    {
        var hasNotification = await _context.VendorNotifications
            .AnyAsync(n => n.VendorId == vendorId);

        if (!hasNotification)
        {
            _context.VendorNotifications.Add(new VendorNotification
            {
                VendorId = vendorId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Yeni siparişler ve güncellemeler buradan bildirim alacaksın.",
                Type = "info"
            });

            await _context.SaveChangesAsync();
        }
    }
}


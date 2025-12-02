using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/courier/notifications")]
[ApiController]
[Authorize(Roles = "Courier")]
public class CourierNotificationsController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<CourierNotificationsController> _logger;

    public CourierNotificationsController(
        TalabiDbContext context,
        ILogger<CourierNotificationsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Courier?> GetCurrentCourierAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var courier = await _context.Couriers.FirstOrDefaultAsync(c => c.UserId == userId);

        if (courier == null && createIfMissing)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
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
                Status = Core.Enums.CourierStatus.Offline,
                CreatedAt = DateTime.UtcNow
            };

            _context.Couriers.Add(courier);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Courier profile auto-created for notifications. UserId: {UserId}", userId);
        }

        return courier;
    }

    [HttpGet]
    public async Task<ActionResult<CourierNotificationResponseDto>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            _logger.LogWarning("Courier not found for notifications (UserId: {UserId})", GetUserId());
            return Ok(new CourierNotificationResponseDto
            {
                Items = Array.Empty<CourierNotificationDto>(),
                UnreadCount = 0
            });
        }

        await EnsureWelcomeNotificationAsync(courier.Id);

        var query = _context.CourierNotifications
            .Where(n => n.CourierId == courier.Id)
            .OrderByDescending(n => n.CreatedAt);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        var notifications = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
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

        return Ok(new CourierNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        });
    }

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new { Message = "Courier profile not found" });
        }

        var notification = await _context.CourierNotifications
            .FirstOrDefaultAsync(n => n.Id == id && n.CourierId == courier.Id);

        if (notification == null)
        {
            return NotFound(new { Message = "Notification not found" });
        }

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        return Ok(new { Message = "Notification marked as read" });
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new { Message = "Courier profile not found" });
        }

        var unreadNotifications = await _context.CourierNotifications
            .Where(n => n.CourierId == courier.Id && !n.IsRead)
            .ToListAsync();

        if (unreadNotifications.Count == 0)
        {
            return Ok(new { Message = "All notifications are already read" });
        }

        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            notification.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return Ok(new { Message = "All notifications marked as read" });
    }

    private async Task EnsureWelcomeNotificationAsync(Guid courierId)
    {
        var hasNotification = await _context.CourierNotifications
            .AnyAsync(n => n.CourierId == courierId);

        if (!hasNotification)
        {
            _context.CourierNotifications.Add(new CourierNotification
            {
                CourierId = courierId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Yeni siparişler aldıkça buradan bildirim alacaksın.",
                Type = "info"
            });

            await _context.SaveChangesAsync();
        }
    }
}


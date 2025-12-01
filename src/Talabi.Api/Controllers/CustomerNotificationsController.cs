using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/customer/notifications")]
[ApiController]
[Authorize]
public class CustomerNotificationsController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<CustomerNotificationsController> _logger;

    public CustomerNotificationsController(
        TalabiDbContext context,
        ILogger<CustomerNotificationsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private string GetUserId() =>
        User.FindFirstValue(ClaimTypes.NameIdentifier) ??
        throw new UnauthorizedAccessException();

    private async Task<Customer?> GetCurrentCustomerAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var customer = await _context.Customers.FirstOrDefaultAsync(c => c.UserId == userId);

        if (customer == null && createIfMissing)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                return null;
            }

            customer = new Customer
            {
                UserId = user.Id,
                CreatedAt = DateTime.UtcNow
            };

            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Customer profile auto-created for notifications. UserId: {UserId}", userId);
        }

        return customer;
    }

    [HttpGet]
    public async Task<ActionResult<CustomerNotificationResponseDto>> GetNotifications(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            _logger.LogWarning("Customer not found for notifications (UserId: {UserId})", GetUserId());
            return Ok(new CustomerNotificationResponseDto
            {
                Items = Array.Empty<CustomerNotificationDto>(),
                UnreadCount = 0
            });
        }

        await EnsureWelcomeNotificationAsync(customer.Id);

        var query = _context.CustomerNotifications
            .Where(n => n.CustomerId == customer.Id)
            .OrderByDescending(n => n.CreatedAt);

        var unreadCount = await query.CountAsync(n => !n.IsRead);

        var notifications = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
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

        return Ok(new CustomerNotificationResponseDto
        {
            Items = notifications,
            UnreadCount = unreadCount
        });
    }

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            return NotFound(new { Message = "Customer profile not found" });
        }

        var notification = await _context.CustomerNotifications
            .FirstOrDefaultAsync(n => n.Id == id && n.CustomerId == customer.Id);

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
        var customer = await GetCurrentCustomerAsync(createIfMissing: true);
        if (customer == null)
        {
            return NotFound(new { Message = "Customer profile not found" });
        }

        var unreadNotifications = await _context.CustomerNotifications
            .Where(n => n.CustomerId == customer.Id && !n.IsRead)
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

    private async Task EnsureWelcomeNotificationAsync(int customerId)
    {
        var hasNotification = await _context.CustomerNotifications
            .AnyAsync(n => n.CustomerId == customerId);

        if (!hasNotification)
        {
            _context.CustomerNotifications.Add(new CustomerNotification
            {
                CustomerId = customerId,
                Title = "Talabi'ye Hoş Geldin!",
                Message = "Sipariş durumları ve özel teklifler hakkında buradan bildirim alacaksın.",
                Type = "info"
            });

            await _context.SaveChangesAsync();
        }
    }
}


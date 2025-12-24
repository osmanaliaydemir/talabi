using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Interfaces;
using Talabi.Portal.Services;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Portal.Controllers;

[Authorize]
public class NotificationsController : Controller
{
    private readonly IDashboardNotificationService _notificationService;
    private readonly IDeliveryZoneService _deliveryZoneService; // Hack to get vendorId via its helper method or just use UserContext
    // The DeliveryZoneService has GetVendorIdAsync but it is private.
    // I should use IUserContextService directly if possible or repeat the logic.
    // Looking at other controllers... OrderService uses IUserContextService.
    
    // I will duplicate the GetVendorId logic using IUserContextService + DbContext if needed, 
    // or better, rely on the fact that DashboardNotificationService needs VendorId.
    // Wait, DashboardNotificationService is in Infrastructure, so it doesn't know about HttpContext.
    // I must pass vendorId to it.
    
    private readonly Talabi.Infrastructure.Data.TalabiDbContext _dbContext;
    private readonly IUserContextService _userContextService;

    public NotificationsController(
        IDashboardNotificationService notificationService, 
        Talabi.Infrastructure.Data.TalabiDbContext dbContext,
        IUserContextService userContextService)
    {
        _notificationService = notificationService;
        _dbContext = dbContext;
        _userContextService = userContextService;
    }

    private Guid? GetVendorId()
    {
        var userId = _userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return null;

        var vendorId = _dbContext.Vendors
            .Where(v => v.OwnerId == userId)
            .Select(v => v.Id)
            .FirstOrDefault();
            
        return vendorId == Guid.Empty ? null : vendorId;
    }

    public async Task<IActionResult> Index()
    {
        var vendorId = GetVendorId();
        if (vendorId == null) return View(new List<Talabi.Core.Entities.VendorNotification>());

        var notifications = await _notificationService.GetAllNotificationsAsync(vendorId.Value);
        return View(notifications);
    }

    [HttpGet]
    public async Task<IActionResult> UnreadCount()
    {
        var vendorId = GetVendorId();
        if (vendorId == null) return Json(new { count = 0 });

        var count = await _notificationService.GetUnreadCountAsync(vendorId.Value);
        return Json(new { count });
    }

    [HttpGet]
    public async Task<IActionResult> GetRecent()
    {
        var vendorId = GetVendorId();
        if (vendorId == null) return PartialView("_NotificationDropdown", new List<Talabi.Core.Entities.VendorNotification>());

        var notifications = await _notificationService.GetRecentNotificationsAsync(vendorId.Value);
        return PartialView("_NotificationDropdown", notifications);
    }

    [HttpPost]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var vendorId = GetVendorId();
        if (vendorId != null)
        {
            await _notificationService.MarkAsReadAsync(id, vendorId.Value);
        }
        return Ok();
    }

    [HttpPost]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var vendorId = GetVendorId();
        if (vendorId != null)
        {
            await _notificationService.MarkAllAsReadAsync(vendorId.Value);
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> MarkAllAsReadAjax()
    {
        var vendorId = GetVendorId();
        if (vendorId != null)
        {
            await _notificationService.MarkAllAsReadAsync(vendorId.Value);
        }
        return Ok();
    }

    [HttpGet]
    public async Task<IActionResult> ReadAndRedirect(Guid id)
    {
        var vendorId = GetVendorId();
        if (vendorId != null)
        {
            var notification = await _dbContext.VendorNotifications
                .FirstOrDefaultAsync(n => n.Id == id && n.VendorId == vendorId.Value);

            if (notification != null)
            {
                if (!notification.IsRead)
                {
                    notification.IsRead = true;
                    await _dbContext.SaveChangesAsync();
                }

                if (notification.RelatedEntityId.HasValue)
                {
                    switch (notification.Type)
                    {
                        case "NewOrder":
                        case "OrderStatusChanged":
                            return RedirectToAction("Details", "Orders", new { id = notification.RelatedEntityId });
                        case "NewReview":
                            // Assuming Reviews controller has Index or Details. Index is safer if Details doesn't exist.
                            return RedirectToAction("Index", "Reviews"); 
                    }
                }
            }
        }
        return RedirectToAction(nameof(Index));
    }
}

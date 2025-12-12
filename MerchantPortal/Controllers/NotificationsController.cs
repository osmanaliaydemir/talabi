using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class NotificationsController : Controller
{
	private readonly INotificationService _notificationService;
	private readonly ILogger<NotificationsController> _logger;

	public NotificationsController(INotificationService notificationService, ILogger<NotificationsController> logger)
	{
		_notificationService = notificationService;
		_logger = logger;
	}

	public async Task<IActionResult> Index(int page = 1)
	{
		var list = await _notificationService.GetMyNotificationsAsync(page, 20);
		return View(list ?? new PagedResult<NotificationResponse>());
	}

	[HttpGet]
	public async Task<IActionResult> UnreadCount()
	{
		var list = await _notificationService.GetMyNotificationsAsync(1, 50);
		var count = list?.Items.Count(x => !x.IsRead) ?? 0;
		return Json(new { count });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> MarkAsRead(List<Guid> ids)
	{
		var ok = await _notificationService.MarkAsReadAsync(ids);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Bildirimler okundu" : "İşlem başarısız";
		return RedirectToAction(nameof(Index));
	}

	[HttpGet]
	public async Task<IActionResult> Preferences()
	{
		var prefs = await _notificationService.GetPreferencesAsync();
		return View(prefs ?? new NotificationPreferencesResponse());
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Preferences(UpdateNotificationPreferencesRequest model)
	{
		var ok = await _notificationService.UpdatePreferencesAsync(model);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Tercihler güncellendi" : "İşlem başarısız";
		return RedirectToAction(nameof(Preferences));
	}
}



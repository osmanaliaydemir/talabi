using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class DeliveryOptimizationController : Controller
{
	private readonly IDeliveryOptimizationService _optimizationService;
	private readonly IMerchantService _merchantService;
	private readonly ILogger<DeliveryOptimizationController> _logger;

	public DeliveryOptimizationController(IDeliveryOptimizationService optimizationService, IMerchantService merchantService, ILogger<DeliveryOptimizationController> logger)
	{
		_optimizationService = optimizationService;
		_merchantService = merchantService;
		_logger = logger;
	}

	[HttpGet]
	public async Task<IActionResult> Capacity()
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var capacity = await _optimizationService.GetCapacityAsync(me.Id);
		return View(capacity ?? new DeliveryCapacityResponse { MerchantId = me.Id, MaxActiveDeliveries = 0, MaxDailyDeliveries = 0 });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Capacity(DeliveryCapacityRequest model)
	{
		if (!ModelState.IsValid) return View(model);
		var created = await _optimizationService.CreateCapacityAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Kapasite kaydedilemedi");
			return View(model);
		}
		TempData["SuccessMessage"] = "Kapasite kaydedildi";
		return RedirectToAction(nameof(Capacity));
	}

	[HttpGet]
	public async Task<IActionResult> Routes()
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var model = new RouteOptimizationRequest { MerchantId = me.Id, Waypoints = new List<RouteWaypoint>() };
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> BestRoute(RouteOptimizationRequest model)
	{
		if (!ModelState.IsValid) return View("Routes", model);
		var result = await _optimizationService.SelectBestRouteAsync(model);
		ViewBag.BestRoute = result;
		return View("Routes", model);
	}
}



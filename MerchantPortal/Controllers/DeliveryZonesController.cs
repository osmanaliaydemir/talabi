using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class DeliveryZonesController : Controller
{
	private readonly IDeliveryZoneService _zoneService;
	private readonly IMerchantService _merchantService;
	private readonly ILogger<DeliveryZonesController> _logger;

	public DeliveryZonesController(IDeliveryZoneService zoneService, IMerchantService merchantService, ILogger<DeliveryZonesController> logger)
	{
		_zoneService = zoneService;
		_merchantService = merchantService;
		_logger = logger;
	}

	public async Task<IActionResult> Index()
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var zones = await _zoneService.GetZonesByMerchantAsync(me.Id);
		ViewBag.MerchantId = me.Id;
		return View(zones ?? new List<DeliveryZoneResponse>());
	}

	[HttpGet]
	public IActionResult Create(Guid merchantId)
	{
		return View(new CreateDeliveryZoneRequest { MerchantId = merchantId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Create(CreateDeliveryZoneRequest model)
	{
		if (!ModelState.IsValid) return View(model);
		var created = await _zoneService.CreateZoneAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Bölge oluşturulamadı");
			return View(model);
		}
		TempData["SuccessMessage"] = "Bölge oluşturuldu";
		return RedirectToAction(nameof(Index));
	}

	[HttpGet]
	public async Task<IActionResult> Edit(Guid id)
	{
		var zone = await _zoneService.GetZoneAsync(id);
		if (zone == null) return NotFound();
		var model = new UpdateDeliveryZoneRequest
		{
			MerchantId = zone.MerchantId,
			Name = zone.Name,
			PolygonGeoJson = zone.PolygonGeoJson,
			DeliveryFee = zone.DeliveryFee,
			EstimatedMinutes = zone.EstimatedMinutes,
			IsActive = zone.IsActive
		};
		ViewBag.ZoneId = id;
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Edit(Guid id, UpdateDeliveryZoneRequest model)
	{
		if (!ModelState.IsValid) return View(model);
		var updated = await _zoneService.UpdateZoneAsync(id, model);
		if (updated == null)
		{
			ModelState.AddModelError(string.Empty, "Bölge güncellenemedi");
			return View(model);
		}
		TempData["SuccessMessage"] = "Bölge güncellendi";
		return RedirectToAction(nameof(Index));
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Delete(Guid id)
	{
		var ok = await _zoneService.DeleteZoneAsync(id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Bölge silindi" : "Bölge silinemedi";
		return RedirectToAction(nameof(Index));
	}
}



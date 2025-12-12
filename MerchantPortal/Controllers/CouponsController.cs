using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class CouponsController : Controller
{
	private readonly ICouponService _couponService;
	private readonly ILogger<CouponsController> _logger;

	public CouponsController(ICouponService couponService, ILogger<CouponsController> logger)
	{
		_couponService = couponService;
		_logger = logger;
	}

	public async Task<IActionResult> Index(int page = 1)
	{
		var list = await _couponService.GetCouponsAsync(page, 20);
		return View(list);
	}

	[HttpGet]
	public IActionResult Create()
	{
		return View(new CreateCouponRequest
		{
			StartDate = DateTime.UtcNow.Date,
			EndDate = DateTime.UtcNow.Date.AddDays(30),
			UsageLimit = 100
		});
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Create(CreateCouponRequest model)
	{
		if (!ModelState.IsValid) return View(model);
		var created = await _couponService.CreateAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Kupon oluşturulamadı");
			return View(model);
		}
		TempData["SuccessMessage"] = "Kupon oluşturuldu";
		return RedirectToAction(nameof(Index));
	}

	[HttpGet]
	public IActionResult Validate()
	{
		return View(new ValidateCouponRequest());
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Validate(ValidateCouponRequest model)
	{
		if (!ModelState.IsValid) return View(model);
		var result = await _couponService.ValidateAsync(model);
		ViewBag.Result = result;
		return View(model);
	}
}



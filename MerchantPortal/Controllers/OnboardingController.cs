using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class OnboardingController : Controller
{
	private readonly IMerchantOnboardingService _onboardingService;
	private readonly IMerchantService _merchantService;
	private readonly ILogger<OnboardingController> _logger;

	public OnboardingController(IMerchantOnboardingService onboardingService, IMerchantService merchantService, ILogger<OnboardingController> logger)
	{
		_onboardingService = onboardingService;
		_merchantService = merchantService;
		_logger = logger;
	}

	public async Task<IActionResult> Index()
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var status = await _onboardingService.GetStatusAsync(me.Id);
		var progress = await _onboardingService.GetProgressAsync(me.Id);
		var steps = await _onboardingService.GetStepsAsync(me.Id) ?? new List<OnboardingStepResponse>();
		ViewBag.Status = status;
		ViewBag.Progress = progress;
		return View(steps);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Complete(Guid stepId, string? notes)
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var ok = await _onboardingService.CompleteStepAsync(me.Id, stepId, new CompleteOnboardingStepRequest { Notes = notes ?? string.Empty });
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Adım tamamlandı" : "İşlem başarısız";
		return RedirectToAction(nameof(Index));
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Submit()
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();
		var ok = await _onboardingService.SubmitAsync(me.Id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Onboarding gönderildi" : "İşlem başarısız";
		return RedirectToAction(nameof(Index));
	}
}



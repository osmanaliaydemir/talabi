using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class CampaignsController : Controller
{
	private readonly ICampaignService _campaignService;
	private readonly ILogger<CampaignsController> _logger;

	public CampaignsController(ICampaignService campaignService, ILogger<CampaignsController> logger)
	{
		_campaignService = campaignService;
		_logger = logger;
	}

	public async Task<IActionResult> Index(int page = 1)
	{
		var result = await _campaignService.GetActiveCampaignsAsync(page, 20);
		return View(result);
	}
}



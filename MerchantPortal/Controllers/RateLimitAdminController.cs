using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin")]
public class RateLimitAdminController : Controller
{
    private readonly IRateLimitAdminService _rateLimitService;
    private readonly ILocalizationService _localizationService;

    public RateLimitAdminController(
        IRateLimitAdminService rateLimitService,
        ILocalizationService localizationService)
    {
        _rateLimitService = rateLimitService;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index(string? endpoint = null, string httpMethod = "GET", int page = 1, int pageSize = 20)
    {
        var rules = await _rateLimitService.GetRulesAsync();
        RateLimitCheckResponseModel? status = null;
        RateLimitSearchResponseModel? logs = null;

        if (!string.IsNullOrWhiteSpace(endpoint))
        {
            status = await _rateLimitService.GetStatusAsync(endpoint, httpMethod, HttpContext.RequestAborted);

            var request = new RateLimitSearchRequestModel
            {
                Endpoint = endpoint,
                HttpMethod = httpMethod,
                Page = page,
                PageSize = pageSize
            };

            logs = await _rateLimitService.SearchLogsAsync(request, HttpContext.RequestAborted);
        }

        var viewModel = new RateLimitAdminViewModel
        {
            Rules = rules,
            Status = status,
            LogSearch = logs,
            EndpointQuery = endpoint,
            HttpMethodQuery = httpMethod,
            Page = page,
            PageSize = pageSize
        };

        ViewBag.Title = _localizationService.GetString("RateLimitAdmin");

        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Enable(Guid id)
    {
        var result = await _rateLimitService.EnableRuleAsync(id);
        TempData[result ? "Success" : "Error"] = result
            ? _localizationService.GetString("RateLimitRuleEnabled")
            : _localizationService.GetString("RateLimitRuleEnableFailed");

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Disable(Guid id)
    {
        var result = await _rateLimitService.DisableRuleAsync(id);
        TempData[result ? "Success" : "Error"] = result
            ? _localizationService.GetString("RateLimitRuleDisabled")
            : _localizationService.GetString("RateLimitRuleDisableFailed");

        return RedirectToAction(nameof(Index));
    }
}


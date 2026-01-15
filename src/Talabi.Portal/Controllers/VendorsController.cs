using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin")]
public class VendorsController : Controller
{
    private readonly IVendorService _vendorService;
    private readonly ILogger<VendorsController> _logger;
    private readonly ILocalizationService _localizationService;

    public VendorsController(
        IVendorService vendorService,
        ILogger<VendorsController> logger,
        ILocalizationService localizationService)
    {
        _vendorService = vendorService;
        _logger = logger;
        _localizationService = localizationService;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> GetList(int start = 0, int length = 10, int draw = 1)
    {
        try
        {
            var searchValue = Request.Query["search[value]"].FirstOrDefault();
            var sortColumnIndex = Request.Query["order[0][column]"].FirstOrDefault();
            var sortDirection = Request.Query["order[0][dir]"].FirstOrDefault() ?? "asc";

            string? sortBy = null;
            if (sortColumnIndex != null && int.TryParse(sortColumnIndex, out int colIndex))
            {
                var columnName = Request.Query[$"columns[{colIndex}][data]"].FirstOrDefault();
                sortBy = columnName;
            }

            int page = (start / length) + 1;

            var result = await _vendorService.GetVendorsAsync(page, length, searchValue, sortBy, sortDirection);

            return Json(new
            {
                draw = draw,
                recordsTotal = result.TotalCount,
                recordsFiltered = result.TotalCount,
                data = result.Items
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching vendor list");
            return Json(new { draw = draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Details(string id)
    {
        var vendor = await _vendorService.GetVendorByIdAsync(id);
        if (vendor == null) return NotFound();
        return View(vendor);
    }

    [HttpPost]
    public async Task<IActionResult> Approve(string id)
    {
        var success = await _vendorService.ApproveVendorAsync(id);
        if (success)
            return Json(new { success = true, message = _localizationService.GetString("Success") });

        return Json(new { success = false, message = _localizationService.GetString("Error") });
    }

    [HttpPost]
    public async Task<IActionResult> Reject(string id)
    {
        var success = await _vendorService.RejectVendorAsync(id);
        if (success)
            return Json(new { success = true, message = _localizationService.GetString("Success") });

        return Json(new { success = false, message = _localizationService.GetString("Error") });
    }

    [HttpPost]
    public async Task<IActionResult> UpdateCommissionRate(string id, decimal rate)
    {
        var success = await _vendorService.UpdateCommissionRateAsync(id, rate);
        if (success)
            return Json(new { success = true, message = _localizationService.GetString("Success") });

        return Json(new { success = false, message = _localizationService.GetString("Error") });
    }
}

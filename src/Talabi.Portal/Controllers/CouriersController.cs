using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin")]
public class CouriersController(
    ICourierService courierService,
    ILogger<CouriersController> logger,
    ILocalizationService localizationService) : Controller
{
    private readonly ICourierService _courierService = courierService;
    private readonly ILogger<CouriersController> _logger = logger;
    private readonly ILocalizationService _localizationService = localizationService;
    public IActionResult Index() => View();

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

            var result = await _courierService.GetCouriersAsync(page, length, searchValue, sortBy, sortDirection);

            return Json(new
            {
                draw,
                recordsTotal = result.TotalCount,
                recordsFiltered = result.TotalCount,
                data = result.Items
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching courier list");
            return Json(new { draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Details(string id)
    {
        var courier = await _courierService.GetCourierByIdAsync(id);
        if (courier == null) return NotFound();
        return View(courier);
    }

    [HttpPost]
    public async Task<IActionResult> Approve(string id)
    {
        var success = await _courierService.ApproveCourierAsync(id);
        if (success)
            return Json(new { success = true, message = _localizationService.GetString("Success") });

        return Json(new { success = false, message = _localizationService.GetString("Error") });
    }

    [HttpPost]
    public async Task<IActionResult> Reject(string id)
    {
        var success = await _courierService.RejectCourierAsync(id);
        if (success)
            return Json(new { success = true, message = _localizationService.GetString("Success") });

        return Json(new { success = false, message = _localizationService.GetString("Error") });
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Enums;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class OrdersController : Controller
{
    private readonly IOrderService _orderService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(
        IOrderService orderService,
        ILocalizationService localizationService,
        ILogger<OrdersController> logger)
    {
        _orderService = orderService;
        _localizationService = localizationService;
        _logger = logger;
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
            var sortDirection = Request.Query["order[0][dir]"].FirstOrDefault() ?? "desc";
            var statusFilter = Request.Query["status"].FirstOrDefault();

            string? sortBy = null;
            if (sortColumnIndex != null && int.TryParse(sortColumnIndex, out int colIndex))
            {
                var columnName = Request.Query[$"columns[{colIndex}][data]"].FirstOrDefault();
                if (!string.IsNullOrEmpty(columnName))
                {
                    sortBy = columnName switch
                    {
                        "customerOrderId" => "id",
                        "customerName" => "customerName",
                        "totalAmount" => "totalAmount",
                        "status" => "status",
                        "createdAt" => "date",
                        _ => null
                    };
                }
            }

            int page = (start / length) + 1;
            OrderStatus? status = null;
            if (!string.IsNullOrEmpty(statusFilter) && Enum.TryParse<OrderStatus>(statusFilter, out var parsedStatus))
            {
                status = parsedStatus;
            }

            var startDateStr = Request.Query["startDate"].FirstOrDefault();
            var endDateStr = Request.Query["endDate"].FirstOrDefault();
            var minAmountStr = Request.Query["minAmount"].FirstOrDefault();
            var maxAmountStr = Request.Query["maxAmount"].FirstOrDefault();

            DateTime? startDate = null;
            if (DateTime.TryParse(startDateStr, out var sd)) startDate = sd;

            DateTime? endDate = null;
            if (DateTime.TryParse(endDateStr, out var ed)) 
                endDate = ed.Date.AddDays(1).AddTicks(-1); // End of day

            decimal? minAmount = null;
            if (decimal.TryParse(minAmountStr, out var min)) minAmount = min;

            decimal? maxAmount = null;
            if (decimal.TryParse(maxAmountStr, out var max)) maxAmount = max;

            var result = await _orderService.GetOrdersAsync(page, length, status, searchValue, sortBy, sortDirection, 
                startDate, endDate, minAmount, maxAmount);

            if (result == null)
            {
                 return Json(new 
                 { 
                     draw = draw, 
                     recordsTotal = 0, 
                     recordsFiltered = 0, 
                     data = Array.Empty<object>() 
                 });
            }

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
            _logger.LogError(ex, "Error fetching order list");
            return Json(new { draw = draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Get(Guid id)
    {
        var order = await _orderService.GetOrderAsync(id);
        if (order == null) return NotFound();
        return Json(order);
    }

    public async Task<IActionResult> Details(Guid id)
    {
        var order = await _orderService.GetOrderAsync(id);
        if (order == null) return NotFound();
        return View(order);
    }

    [HttpPost]
    public async Task<IActionResult> UpdateStatus(Guid id, OrderStatus status)
    {
        var success = await _orderService.UpdateOrderStatusAsync(id, status);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = _localizationService.GetString("ErrorUpdatingStatus") });
    }

    [HttpPost]
    public async Task<IActionResult> AcceptOrder(Guid id)
    {
        var success = await _orderService.UpdateOrderStatusAsync(id, OrderStatus.Preparing); // Accepted -> Preparing flow
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = _localizationService.GetString("ErrorAcceptingOrder") });
    }

    [HttpPost]
    public async Task<IActionResult> RejectOrder(Guid id, string reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
            return Json(new { success = false, message = _localizationService.GetString("ReasonRequired") });

        var success = await _orderService.RejectOrderAsync(id, reason);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = _localizationService.GetString("ErrorRejectingOrder") });
    }
    [HttpGet]
    public async Task<IActionResult> GetAvailableCouriers(Guid id)
    {
        var couriers = await _orderService.GetAvailableCouriersAsync(id);
        return Json(couriers);
    }

    [HttpPost]
    public async Task<IActionResult> AssignCourier(Guid id, Guid courierId)
    {
        var success = await _orderService.AssignCourierAsync(id, courierId);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = _localizationService.GetString("ErrorAssigningCourier") });
    }
}

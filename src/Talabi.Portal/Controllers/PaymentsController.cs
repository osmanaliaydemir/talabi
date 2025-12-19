using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using PortalServices = Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
[Route("[controller]")]
public class PaymentsController : Controller
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly PortalServices.ILocalizationService _localizationService;

    public PaymentsController(IUnitOfWork unitOfWork, PortalServices.ILocalizationService localizationService)
    {
        _unitOfWork = unitOfWork;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        // Fetch all delivered orders for the vendor
        // Optimization: In a real app, we might want to paginate or filter date range at DB level.
        // For now, fetching all delivered orders to calculate totals in memory might be okay if volume is low,
        // but ideally we should do db-side aggregation.

        var deliveredOrders = await _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();

        var today = DateTime.UtcNow.Date;
        var startOfWeek = today.AddDays(-(int)today.DayOfWeek + (int)DayOfWeek.Monday); // Assuming Monday start
        var startOfMonth = new DateTime(today.Year, today.Month, 1);

        var viewModel = new PaymentsViewModel
        {
            TotalEarnings = deliveredOrders.Sum(o => o.TotalAmount),
            DailyEarnings = deliveredOrders.Where(o => o.CreatedAt.Date == today).Sum(o => o.TotalAmount),
            WeeklyEarnings = deliveredOrders.Where(o => o.CreatedAt.Date >= startOfWeek).Sum(o => o.TotalAmount),
            MonthlyEarnings = deliveredOrders.Where(o => o.CreatedAt.Date >= startOfMonth).Sum(o => o.TotalAmount),

            // Mapping for the table
            Transactions = deliveredOrders.Select(o => new Core.DTOs.OrderDto
            {
                Id = o.Id,
                CustomerOrderId = o.CustomerOrderId,
                CreatedAt = o.CreatedAt,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString()
            }).ToList()
        };

        return View(viewModel);
    }
}

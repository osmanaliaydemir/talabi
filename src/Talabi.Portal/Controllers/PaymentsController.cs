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
    public async Task<IActionResult> Index(DateTime? startDate, DateTime? endDate)
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        var today = DateTime.UtcNow.Date;
        var startOfWeek = today.AddDays(-(int)today.DayOfWeek + (int)DayOfWeek.Monday);
        var startOfMonth = new DateTime(today.Year, today.Month, 1);

        // Calculate earnings directly in DB (Unaffected by filter)
        decimal totalEarnings = await _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered)
            .SumAsync(o => o.TotalAmount);

        decimal dailyEarnings = await _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered && o.CreatedAt.Date == today)
            .SumAsync(o => o.TotalAmount);

        decimal weeklyEarnings = await _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered && o.CreatedAt.Date >= startOfWeek)
            .SumAsync(o => o.TotalAmount);

        decimal monthlyEarnings = await _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered && o.CreatedAt.Date >= startOfMonth)
            .SumAsync(o => o.TotalAmount);

        // Filter Logic
        var query = _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);

        if (startDate.HasValue)
            query = query.Where(o => o.CreatedAt.Date >= startDate.Value.Date);

        if (endDate.HasValue)
            query = query.Where(o => o.CreatedAt.Date <= endDate.Value.Date);

        // Fetch filtered transactions
        var transactions = await query
            .OrderByDescending(o => o.CreatedAt)
            .Take(500) // Increase limit for filtered views
            .Select(o => new Core.DTOs.OrderDto
            {
                Id = o.Id,
                CustomerOrderId = o.CustomerOrderId,
                CreatedAt = o.CreatedAt,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString()
            })
            .ToListAsync();

        var viewModel = new PaymentsViewModel
        {
            TotalEarnings = totalEarnings,
            DailyEarnings = dailyEarnings,
            WeeklyEarnings = weeklyEarnings,
            MonthlyEarnings = monthlyEarnings,
            Transactions = transactions
        };

        return View(viewModel);
    }

    [HttpGet]
    public async Task<IActionResult> Export(DateTime? startDate, DateTime? endDate)
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        var query = _unitOfWork.Orders.Query()
            .Where(o => o.VendorId == vendorId && o.Status == OrderStatus.Delivered);

        if (startDate.HasValue)
            query = query.Where(o => o.CreatedAt.Date >= startDate.Value.Date);

        if (endDate.HasValue)
            query = query.Where(o => o.CreatedAt.Date <= endDate.Value.Date);

        var transactions = await query
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new
            {
                o.CustomerOrderId,
                o.CreatedAt,
                o.TotalAmount,
                Status = o.Status.ToString()
            })
            .ToListAsync();

        var builder = new System.Text.StringBuilder();
        // Add header
        builder.AppendLine("Siparis No;Tarih;Tutar;Durum");

        foreach (var t in transactions)
        {
            builder.AppendLine($"{t.CustomerOrderId};{t.CreatedAt:yyyy-MM-dd HH:mm};{t.TotalAmount:F2};{t.Status}");
        }

        // Return as CSV file with UTF8 BOM for Excel compatibility
        var bytes = System.Text.Encoding.UTF8.GetPreamble()
            .Concat(System.Text.Encoding.UTF8.GetBytes(builder.ToString())).ToArray();
        return File(bytes, "text/csv", $"gelir_raporu_{DateTime.Now:yyyyMMdd}.csv");
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/admin/couriers")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminCourierController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly IOrderAssignmentService _assignmentService;

    public AdminCourierController(TalabiDbContext context, IOrderAssignmentService assignmentService)
    {
        _context = context;
        _assignmentService = assignmentService;
    }

    // GET: api/admin/couriers
    [HttpGet]
    public async Task<IActionResult> GetCouriers([FromQuery] string? status, [FromQuery] bool? isActive)
    {
        var query = _context.Couriers.AsQueryable();

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<CourierStatus>(status, true, out var statusEnum))
        {
            query = query.Where(c => c.Status == statusEnum);
        }

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        var couriers = await query
            .Select(c => new CourierProfileDto
            {
                Id = c.Id,
                UserId = c.UserId,
                Name = c.Name,
                PhoneNumber = c.PhoneNumber,
                VehicleType = c.VehicleType,
                IsActive = c.IsActive,
                Status = c.Status.ToString(),
                MaxActiveOrders = c.MaxActiveOrders,
                CurrentActiveOrders = c.CurrentActiveOrders,
                CurrentLatitude = c.CurrentLatitude,
                CurrentLongitude = c.CurrentLongitude,
                LastLocationUpdate = c.LastLocationUpdate,
                TotalEarnings = c.TotalEarnings,
                CurrentDayEarnings = c.CurrentDayEarnings,
                TotalDeliveries = c.TotalDeliveries,
                AverageRating = c.AverageRating,
                WorkingHoursStart = c.WorkingHoursStart,
                WorkingHoursEnd = c.WorkingHoursEnd,
                IsWithinWorkingHours = c.IsWithinWorkingHours
            })
            .ToListAsync();

        return Ok(couriers);
    }

    // POST: api/admin/couriers/orders/{id}/assign
    [HttpPost("orders/{id}/assign")]
    public async Task<IActionResult> AssignOrder(Guid id, [FromQuery] Guid courierId)
    {
        var success = await _assignmentService.AssignOrderToCourierAsync(id, courierId);
        if (!success)
        {
            return BadRequest(new { Message = "Failed to assign order. Check if order is ready and courier is available." });
        }

        return Ok(new { Message = "Order assigned successfully" });
    }

    // GET: api/admin/couriers/{id}/performance
    [HttpGet("{id}/performance")]
    public async Task<IActionResult> GetPerformance(Guid id)
    {
        var courier = await _context.Couriers.FindAsync(id);
        if (courier == null) return NotFound(new { Message = "Courier not found" });

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var orders = await _context.Orders
            .Where(o => o.CourierId == id && o.Status == OrderStatus.Delivered)
            .ToListAsync();

        var todayOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date == today);
        var weekOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date >= weekStart);
        var monthOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date >= monthStart);

        // Calculate earnings (this could be optimized by querying CourierEarnings table directly)
        var earnings = await _context.CourierEarnings
            .Where(e => e.CourierId == id)
            .ToListAsync();

        var todayEarnings = earnings.Where(e => e.EarnedAt.Date == today).Sum(e => e.TotalEarning);
        var weekEarnings = earnings.Where(e => e.EarnedAt.Date >= weekStart).Sum(e => e.TotalEarning);
        var monthEarnings = earnings.Where(e => e.EarnedAt.Date >= monthStart).Sum(e => e.TotalEarning);

        var stats = new CourierStatisticsDto
        {
            TotalDeliveries = courier.TotalDeliveries,
            TodayDeliveries = todayOrders,
            WeekDeliveries = weekOrders,
            MonthDeliveries = monthOrders,
            TotalEarnings = courier.TotalEarnings,
            TodayEarnings = todayEarnings,
            WeekEarnings = weekEarnings,
            MonthEarnings = monthEarnings,
            AverageRating = courier.AverageRating,
            TotalRatings = courier.TotalRatings,
            ActiveOrders = courier.CurrentActiveOrders
        };

        return Ok(stats);
    }

    // PUT: api/admin/couriers/{id}/activate
    [HttpPut("{id}/activate")]
    public async Task<IActionResult> ActivateCourier(Guid id)
    {
        var courier = await _context.Couriers.FindAsync(id);
        if (courier == null) return NotFound(new { Message = "Courier not found" });

        courier.IsActive = true;
        courier.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Courier activated successfully" });
    }

    // PUT: api/admin/couriers/{id}/deactivate
    [HttpPut("{id}/deactivate")]
    public async Task<IActionResult> DeactivateCourier(Guid id)
    {
        var courier = await _context.Couriers.FindAsync(id);
        if (courier == null) return NotFound(new { Message = "Courier not found" });

        if (courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new { Message = "Cannot deactivate courier with active orders" });
        }

        courier.IsActive = false;
        courier.Status = CourierStatus.Offline;
        courier.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Courier deactivated successfully" });
    }

    // PUT: api/admin/couriers/{id}/status
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateCourierStatus(Guid id, [FromBody] UpdateCourierStatusDto dto)
    {
        var courier = await _context.Couriers.FindAsync(id);
        if (courier == null) return NotFound(new { Message = "Courier not found" });

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new { Message = "Invalid status" });
        }

        courier.Status = newStatus;
        courier.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { Message = $"Courier status updated to {newStatus}" });
    }

    // GET: api/admin/couriers/statistics
    [HttpGet("statistics")]
    public async Task<IActionResult> GetOverallStatistics()
    {
        var totalCouriers = await _context.Couriers.CountAsync();
        var activeCouriers = await _context.Couriers.CountAsync(c => c.IsActive);
        var availableCouriers = await _context.Couriers.CountAsync(c => c.Status == CourierStatus.Available);
        var busyCouriers = await _context.Couriers.CountAsync(c => c.Status == CourierStatus.Busy);

        var today = DateTime.Today;
        var todayDeliveries = await _context.Orders
            .Where(o => o.Status == OrderStatus.Delivered && o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date == today)
            .CountAsync();

        var todayEarnings = await _context.CourierEarnings
            .Where(e => e.EarnedAt.Date == today)
            .SumAsync(e => e.TotalEarning);

        return Ok(new
        {
            TotalCouriers = totalCouriers,
            ActiveCouriers = activeCouriers,
            AvailableCouriers = availableCouriers,
            BusyCouriers = busyCouriers,
            TodayDeliveries = todayDeliveries,
            TodayEarnings = todayEarnings
        });
    }
}

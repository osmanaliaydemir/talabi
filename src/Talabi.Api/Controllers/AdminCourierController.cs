using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Admin kurye yönetimi işlemleri için controller
/// </summary>
[Route("api/admin/couriers")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminCourierController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IOrderAssignmentService _assignmentService;

    /// <summary>
    /// AdminCourierController constructor
    /// </summary>
    public AdminCourierController(IUnitOfWork unitOfWork, IOrderAssignmentService assignmentService)
    {
        _unitOfWork = unitOfWork;
        _assignmentService = assignmentService;
    }

    /// <summary>
    /// Tüm kuryeleri getirir (filtreleme ile)
    /// </summary>
    /// <param name="status">Kurye durumu filtresi (opsiyonel)</param>
    /// <param name="isActive">Aktiflik filtresi (opsiyonel)</param>
    /// <returns>Kurye listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<CourierProfileDto>>>> GetCouriers([FromQuery] string? status, [FromQuery] bool? isActive)
    {
        IQueryable<Courier> query = _unitOfWork.Couriers.Query();

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

        return Ok(new ApiResponse<List<CourierProfileDto>>(couriers, "Kuryeler başarıyla getirildi"));
    }

    /// <summary>
    /// Siparişi belirli bir kuryeye atar
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="courierId">Kurye ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/assign")]
    public async Task<ActionResult<ApiResponse<object>>> AssignOrder(Guid id, [FromQuery] Guid courierId)
    {
        var success = await _assignmentService.AssignOrderToCourierAsync(id, courierId);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>("Sipariş atanamadı. Siparişin hazır durumda olduğundan ve kuryenin müsait olduğundan emin olun", "ORDER_ASSIGNMENT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, "Sipariş başarıyla atandı"));
    }

    /// <summary>
    /// Belirli bir kuryenin performans istatistiklerini getirir
    /// </summary>
    /// <param name="id">Kurye ID'si</param>
    /// <returns>Kurye performans istatistikleri</returns>
    [HttpGet("{id}/performance")]
    public async Task<ActionResult<ApiResponse<CourierStatisticsDto>>> GetPerformance(Guid id)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(id);
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierStatisticsDto>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);
        var monthStart = new DateTime(today.Year, today.Month, 1);

        // Get orders through OrderCouriers
        var orderCouriers = await _unitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Order)
            .Where(oc => oc.CourierId == id 
                && oc.Order != null 
                && oc.Order.Status == OrderStatus.Delivered)
            .ToListAsync();

        var todayOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date == today);
        var weekOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date >= weekStart);
        var monthOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date >= monthStart);

        // Calculate earnings (this could be optimized by querying CourierEarnings table directly)
        var earnings = await _unitOfWork.CourierEarnings.Query()
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

        return Ok(new ApiResponse<CourierStatisticsDto>(stats, "Kurye performans istatistikleri başarıyla getirildi"));
    }

    /// <summary>
    /// Kuryeyi aktif hale getirir
    /// </summary>
    /// <param name="id">Kurye ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/activate")]
    public async Task<ActionResult<ApiResponse<object>>> ActivateCourier(Guid id)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(id);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        courier.IsActive = true;
        courier.UpdatedAt = DateTime.UtcNow;
        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Kurye başarıyla aktifleştirildi"));
    }

    /// <summary>
    /// Kuryeyi pasif hale getirir
    /// </summary>
    /// <param name="id">Kurye ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/deactivate")]
    public async Task<ActionResult<ApiResponse<object>>> DeactivateCourier(Guid id)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(id);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        if (courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new ApiResponse<object>("Aktif siparişi olan kurye pasifleştirilemez", "CANNOT_DEACTIVATE_WITH_ACTIVE_ORDERS"));
        }

        courier.IsActive = false;
        courier.Status = CourierStatus.Offline;
        courier.UpdatedAt = DateTime.UtcNow;
        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Kurye başarıyla pasifleştirildi"));
    }

    /// <summary>
    /// Kurye durumunu günceller
    /// </summary>
    /// <param name="id">Kurye ID'si</param>
    /// <param name="dto">Yeni durum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateCourierStatus(Guid id, [FromBody] UpdateCourierStatusDto dto)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(id);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new ApiResponse<object>("Geçersiz durum", "INVALID_STATUS"));
        }

        courier.Status = newStatus;
        courier.UpdatedAt = DateTime.UtcNow;
        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { Status = newStatus.ToString() }, $"Kurye durumu {newStatus} olarak güncellendi"));
    }

    /// <summary>
    /// Genel kurye istatistiklerini getirir
    /// </summary>
    /// <returns>Genel kurye istatistikleri</returns>
    [HttpGet("statistics")]
    public async Task<ActionResult<ApiResponse<object>>> GetOverallStatistics()
    {
        var totalCouriers = await _unitOfWork.Couriers.CountAsync();
        var activeCouriers = await _unitOfWork.Couriers.CountAsync(c => c.IsActive);
        var availableCouriers = await _unitOfWork.Couriers.CountAsync(c => c.Status == CourierStatus.Available);
        var busyCouriers = await _unitOfWork.Couriers.CountAsync(c => c.Status == CourierStatus.Busy);

        var today = DateTime.Today;
        var todayDeliveries = await _unitOfWork.OrderCouriers.Query()
            .Where(oc => oc.Order != null 
                && oc.Order.Status == OrderStatus.Delivered 
                && oc.DeliveredAt.HasValue 
                && oc.DeliveredAt.Value.Date == today)
            .CountAsync();

        var todayEarnings = await _unitOfWork.CourierEarnings.Query()
            .Where(e => e.EarnedAt.Date == today)
            .SumAsync(e => e.TotalEarning);

        var stats = new
        {
            TotalCouriers = totalCouriers,
            ActiveCouriers = activeCouriers,
            AvailableCouriers = availableCouriers,
            BusyCouriers = busyCouriers,
            TodayDeliveries = todayDeliveries,
            TodayEarnings = todayEarnings
        };

        return Ok(new ApiResponse<object>(stats, "Genel kurye istatistikleri başarıyla getirildi"));
    }
}

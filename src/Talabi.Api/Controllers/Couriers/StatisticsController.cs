using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers.Couriers;

/// <summary>
/// Courier Dashboard - İstatistikler için controller
/// </summary>
[Route("api/couriers/dashboard/statistics")]
[ApiController]
[Authorize(Roles = "Courier")]
public class StatisticsController : BaseController
{
    private const string ResourceName = "CourierResources";

    /// <summary>
    /// StatisticsController constructor
    /// </summary>
    public StatisticsController(
        IUnitOfWork unitOfWork,
        ILogger<StatisticsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    private async Task<Courier?> GetCurrentCourierAsync()
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }

        var courier = await UnitOfWork.Couriers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);
        return courier;
    }

    /// <summary>
    /// Kurye istatistiklerini getirir
    /// </summary>
    /// <returns>Kurye istatistikleri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<CourierStatisticsDto>>> GetStatistics()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierStatisticsDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);
        var monthStart = new DateTime(today.Year, today.Month, 1);

        // Get orders through OrderCouriers
        var orderCouriers = await UnitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Order)
            .Where(oc => oc.CourierId == courier.Id
                         && oc.Order != null
                         && oc.Order.Status == OrderStatus.Delivered)
            .ToListAsync();

        var todayOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date == today);
        var weekOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date >= weekStart);
        var monthOrders = orderCouriers.Count(oc => oc.DeliveredAt.HasValue && oc.DeliveredAt.Value.Date >= monthStart);

        var stats = new CourierStatisticsDto
        {
            TotalDeliveries = courier.TotalDeliveries,
            TodayDeliveries = todayOrders,
            WeekDeliveries = weekOrders,
            MonthDeliveries = monthOrders,
            TotalEarnings = courier.TotalEarnings,
            TodayEarnings = courier.CurrentDayEarnings,
            WeekEarnings = 0m,
            MonthEarnings = 0m,
            AverageRating = courier.AverageRating,
            TotalRatings = courier.TotalRatings,
            ActiveOrders = courier.CurrentActiveOrders
        };

        return Ok(new ApiResponse<CourierStatisticsDto>(stats,
            LocalizationService.GetLocalizedString(ResourceName, "CourierStatisticsRetrievedSuccessfully",
                CurrentCulture)));
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers.Couriers;

/// <summary>
/// Courier Dashboard - Kazanç yönetimi için controller
/// </summary>
[Route("api/couriers/dashboard/earnings")]
[ApiController]
[Authorize(Roles = "Courier")]
public class EarningsController : BaseController
{
    private readonly IMapper _mapper;
    private const string ResourceName = "CourierResources";

    /// <summary>
    /// EarningsController constructor
    /// </summary>
    public EarningsController(
        IUnitOfWork unitOfWork,
        ILogger<EarningsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _mapper = mapper;
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
    /// Kuryenin bugünkü kazançlarını getirir
    /// </summary>
    /// <returns>Bugünkü kazanç özeti</returns>
    [HttpGet("today")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetTodayEarnings()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var earnings = await UnitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date == today)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = _mapper.Map<List<CourierEarningDto>>(earnings)
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary,
            LocalizationService.GetLocalizedString(ResourceName, "TodayEarningsRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin haftalık kazançlarını getirir
    /// </summary>
    /// <returns>Haftalık kazanç özeti</returns>
    [HttpGet("week")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetWeekEarnings()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);

        var earnings = await UnitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date >= weekStart)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = _mapper.Map<List<CourierEarningDto>>(earnings)
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary,
            LocalizationService.GetLocalizedString(ResourceName, "WeekEarningsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin aylık kazançlarını getirir
    /// </summary>
    /// <returns>Aylık kazanç özeti</returns>
    [HttpGet("month")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetMonthEarnings()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var earnings = await UnitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date >= monthStart)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = _mapper.Map<List<CourierEarningDto>>(earnings)
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary,
            LocalizationService.GetLocalizedString(ResourceName, "MonthEarningsRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin kazanç geçmişini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 50)</param>
    /// <returns>Sayfalanmış kazanç geçmişi</returns>
    [HttpGet("history")]
    public async Task<ActionResult<ApiResponse<object>>> GetEarningsHistory([FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        IQueryable<CourierEarning> query = UnitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id);

        IOrderedQueryable<CourierEarning> orderedQuery = query.OrderByDescending(e => e.EarnedAt);

        var totalCount = await orderedQuery.CountAsync();
        var earnings = await orderedQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var earningDtos = _mapper.Map<List<CourierEarningDto>>(earnings);

        var result = new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            Earnings = earningDtos
        };

        return Ok(new ApiResponse<object>(result,
            LocalizationService.GetLocalizedString(ResourceName, "EarningsHistoryRetrievedSuccessfully",
                CurrentCulture)));
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kurye işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Courier")]
public class CourierController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private const string ResourceName = "CourierResources";

    /// <summary>
    /// CourierController constructor
    /// </summary>
    public CourierController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<CourierController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
        _mapper = mapper;
    }

    private async Task<Courier?> GetCurrentCourier(bool createIfMissing = false)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }
        var courier = await UnitOfWork.Couriers.Query()
            .Include(c => c.User)
            .Include(c => c.WorkingHours)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (courier == null && createIfMissing)
        {
            var user = await _userManager.FindByIdAsync(userId);
            if (user == null)
            {
                return null;
            }

            courier = new Courier
            {
                UserId = user.Id,
                Name = user.FullName ?? user.Email ?? "Courier",
                PhoneNumber = user.PhoneNumber,
                IsActive = true,
                Status = CourierStatus.Offline,
                CreatedAt = DateTime.UtcNow
            };

            await UnitOfWork.Couriers.AddAsync(courier);
            await UnitOfWork.SaveChangesAsync();

            Logger.LogInformation("Courier profile created automatically for user {UserId}", userId);
        }

        return courier;
    }

    /// <summary>
    /// Kurye profil bilgilerini getirir
    /// </summary>
    /// <returns>Kurye profil bilgileri</returns>
    /// <summary>
    /// Kurye profil bilgilerini getirir
    /// </summary>
    /// <returns>Kurye profil bilgileri</returns>
    [HttpGet("profile")]
    public async Task<ActionResult<ApiResponse<CourierProfileDto>>> GetProfile()
    {


        var courier = await GetCurrentCourier(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierProfileDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var profile = _mapper.Map<CourierProfileDto>(courier);

        // Manually map WorkingHours
        profile.WorkingHours = courier.WorkingHours.Select(wh => new WorkingHourDto
        {
            DayOfWeek = (int)wh.DayOfWeek,
            DayName = LocalizationService.GetLocalizedString("CommonResources", wh.DayOfWeek.ToString(), CurrentCulture), // Assumes DayOfWeek Enum string keys exist or use generic logic
            StartTime = wh.StartTime,
            EndTime = wh.EndTime,
            IsClosed = wh.IsClosed
        }).ToList();

        // Populate IsWithinWorkingHours based on current time and rules
        // This logic might need to be consistent with what was there or updated
        // For now, keeping legacy IsWithinWorkingHours property if used by mobile, but logic should be based on collection? 
        // The DTOs still have IsWithinWorkingHours.


        return Ok(new ApiResponse<CourierProfileDto>(profile, LocalizationService.GetLocalizedString(ResourceName, "CourierProfileRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Kurye profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("profile")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile([FromBody] UpdateCourierProfileDto dto)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        courier.Name = dto.Name;
        courier.PhoneNumber = dto.PhoneNumber;

        // Vehicle type as enum (Motor, Araba, Bisiklet)
        if (!string.IsNullOrWhiteSpace(dto.VehicleType))
        {
            if (!Enum.TryParse<CourierVehicleType>(dto.VehicleType, true, out var vehicleType))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidVehicleType", CurrentCulture), "INVALID_VEHICLE_TYPE"));
            }

            courier.VehicleType = vehicleType;
        }

        courier.MaxActiveOrders = dto.MaxActiveOrders;
        // Legacy fields update (optional, maybe keep sync for now)
        courier.WorkingHoursStart = dto.WorkingHoursStart;
        courier.WorkingHoursEnd = dto.WorkingHoursEnd;

        courier.IsWithinWorkingHours = dto.IsWithinWorkingHours;

        // Update Working Hours Collection
        if (dto.WorkingHours != null)
        {
            // Simple strategy: Remove all and re-add
            // In production, we might want to update existing by DayOfWeek

            // Check if context is tracked? Yes, courier comes from context. 
            // We need to manage the collection.

            // Remove existing
            var existingHours = courier.WorkingHours.ToList();
            foreach (var hour in existingHours)
            {
                UnitOfWork.CourierWorkingHours.Remove(hour);
            }
            courier.WorkingHours.Clear();

            // Add new
            foreach (var whDto in dto.WorkingHours)
            {
                courier.WorkingHours.Add(new CourierWorkingHour
                {
                    CourierId = courier.Id,
                    DayOfWeek = (DayOfWeek)whDto.DayOfWeek,
                    StartTime = whDto.StartTime,
                    EndTime = whDto.EndTime,
                    IsClosed = whDto.IsClosed
                });
            }
        }

        courier.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "ProfileUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Mevcut araç tiplerini getirir
    /// </summary>
    /// <returns>Araç tipi listesi</returns>
    /// <summary>
    /// Mevcut araç tiplerini getirir
    /// </summary>
    /// <returns>Araç tipi listesi</returns>
    [HttpGet("vehicle-types")]
    public ActionResult<ApiResponse<List<object>>> GetVehicleTypes()
    {


        // Motor, Araba, Bisiklet seçenekleri
        var types = new List<object>
        {
            new { Key = CourierVehicleType.Motorcycle.ToString(), Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeMotorcycle", CurrentCulture) },
            new { Key = CourierVehicleType.Car.ToString(), Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeCar", CurrentCulture) },
            new { Key = CourierVehicleType.Bicycle.ToString(), Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeBicycle", CurrentCulture) }
        };

        return Ok(new ApiResponse<List<object>>(types, LocalizationService.GetLocalizedString(ResourceName, "VehicleTypesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye durumunu günceller
    /// </summary>
    /// <param name="dto">Yeni durum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Kurye durumunu günceller
    /// </summary>
    /// <param name="dto">Yeni durum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateStatus([FromBody] UpdateCourierStatusDto dto)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidStatus", CurrentCulture), "INVALID_STATUS"));
        }

        // Çalışma saati kontrolü
        if (newStatus == CourierStatus.Available && courier.IsWithinWorkingHours)
        {
            var now = DateTime.Now.TimeOfDay;
            if (courier.WorkingHoursStart.HasValue && courier.WorkingHoursEnd.HasValue)
            {
                if (now < courier.WorkingHoursStart.Value || now > courier.WorkingHoursEnd.Value)
                {
                    return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CannotGoAvailableOutsideWorkingHours", CurrentCulture), "OUTSIDE_WORKING_HOURS"));
                }
            }
        }

        // Aktif siparişi varsa Offline olamaz
        if (newStatus == CourierStatus.Offline && courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CannotGoOfflineWithActiveOrders", CurrentCulture), "CANNOT_GO_OFFLINE_WITH_ACTIVE_ORDERS"));
        }

        courier.Status = newStatus;
        courier.LastActiveAt = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        Logger.LogInformation("Courier {CourierId} status changed to {Status}", courier.Id, newStatus);

        return Ok(new ApiResponse<object>(new { Status = newStatus.ToString() }, LocalizationService.GetLocalizedString(ResourceName, "StatusUpdated", CurrentCulture, newStatus.ToString())));
    }

    /// <summary>
    /// Kurye konumunu günceller
    /// </summary>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Kurye konumunu günceller
    /// </summary>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("location")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateLocation([FromBody] Talabi.Core.DTOs.Courier.UpdateCourierLocationDto dto)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        if (dto.Latitude < -90 || dto.Latitude > 90)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidLatitude", CurrentCulture), "INVALID_LATITUDE"));
        }

        if (dto.Longitude < -180 || dto.Longitude > 180)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidLongitude", CurrentCulture), "INVALID_LONGITUDE"));
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "LocationUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye istatistiklerini getirir
    /// </summary>
    /// <returns>Kurye istatistikleri</returns>
    /// <summary>
    /// Kurye istatistiklerini getirir
    /// </summary>
    /// <returns>Kurye istatistikleri</returns>
    [HttpGet("statistics")]
    public async Task<ActionResult<ApiResponse<CourierStatisticsDto>>> GetStatistics()
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierStatisticsDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<CourierStatisticsDto>(stats, LocalizationService.GetLocalizedString(ResourceName, "CourierStatisticsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye müsaitlik durumunu kontrol eder
    /// </summary>
    /// <returns>Müsaitlik durumu ve nedenleri</returns>
    /// <summary>
    /// Kurye müsaitlik durumunu kontrol eder
    /// </summary>
    /// <returns>Müsaitlik durumu ve nedenleri</returns>
    [HttpGet("check-availability")]
    public async Task<ActionResult<ApiResponse<object>>> CheckAvailability()
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var isAvailable = courier.Status == CourierStatus.Available
            && courier.IsActive
            && courier.CurrentActiveOrders < courier.MaxActiveOrders;

        var reasons = new List<string>();
        if (!courier.IsActive) reasons.Add("Courier is not active");
        if (courier.Status != CourierStatus.Available) reasons.Add($"Status is {courier.Status}");
        if (courier.CurrentActiveOrders >= courier.MaxActiveOrders) reasons.Add("Maximum active orders reached");

        var result = new
        {
            IsAvailable = isAvailable,
            Status = courier.Status.ToString(),
            CurrentActiveOrders = courier.CurrentActiveOrders,
            MaxActiveOrders = courier.MaxActiveOrders,
            Reasons = reasons
        };

        return Ok(new ApiResponse<object>(result, LocalizationService.GetLocalizedString(ResourceName, "AvailabilityCheckedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye konumunu günceller (Legacy endpoint - geriye dönük uyumluluk için)
    /// </summary>
    /// <param name="courierId">Kurye ID'si</param>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Kurye konumunu günceller (Legacy endpoint - geriye dönük uyumluluk için)
    /// </summary>
    /// <param name="courierId">Kurye ID'si</param>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{courierId}/location")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateLocationLegacy(Guid courierId, Talabi.Core.DTOs.Courier.UpdateCourierLocationDto dto)
    {


        var courier = await UnitOfWork.Couriers.GetByIdAsync(courierId);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierNotFound", CurrentCulture), "COURIER_NOT_FOUND"));
        }

        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId) || courier.UserId != userId)
        {
            return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAuthorizedForThisCourier", CurrentCulture), "FORBIDDEN"));
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "LocationUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir kuryenin konumunu getirir
    /// </summary>
    /// <param name="courierId">Kurye ID'si</param>
    /// <returns>Kurye konum bilgisi</returns>
    [HttpGet("{courierId}/location")]
    public async Task<ActionResult<ApiResponse<Talabi.Core.DTOs.CourierLocationDto>>> GetLocation(Guid courierId)
    {


        var courier = await UnitOfWork.Couriers.GetByIdAsync(courierId);
        if (courier == null)
        {
            return NotFound(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierNotFound", CurrentCulture), "COURIER_NOT_FOUND"));
        }

        if (!courier.CurrentLatitude.HasValue || !courier.CurrentLongitude.HasValue)
        {
            return NotFound(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierLocationNotFound", CurrentCulture), "LOCATION_NOT_FOUND"));
        }

        var locationDto = new Talabi.Core.DTOs.CourierLocationDto
        {
            CourierId = courier.Id,
            CourierName = courier.Name,
            Latitude = courier.CurrentLatitude.Value,
            Longitude = courier.CurrentLongitude.Value,
            LastUpdate = courier.LastLocationUpdate ?? DateTime.UtcNow
        };

        return Ok(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>(locationDto, LocalizationService.GetLocalizedString(ResourceName, "CourierLocationRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Aktif kuryelerin konumlarını getirir
    /// </summary>
    /// <returns>Aktif kurye konum listesi</returns>
    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<List<Talabi.Core.DTOs.CourierLocationDto>>>> GetActiveCouriers()
    {


        var couriers = await UnitOfWork.Couriers.Query()
            .Where(c => c.IsActive &&
                       c.CurrentLatitude.HasValue &&
                       c.CurrentLongitude.HasValue)
            .ToListAsync();

        var courierLocationDtos = couriers.Select(c => _mapper.Map<Talabi.Core.DTOs.CourierLocationDto>(c)).ToList();

        return Ok(new ApiResponse<List<Talabi.Core.DTOs.CourierLocationDto>>(courierLocationDtos, LocalizationService.GetLocalizedString(ResourceName, "ActiveCouriersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin aktif siparişlerini getirir
    /// </summary>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>Aktif sipariş listesi</returns>
    [HttpGet("orders/active")]
    public async Task<ActionResult<ApiResponse<List<Talabi.Core.DTOs.Courier.CourierOrderDto>>>> GetActiveOrders([FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<List<Talabi.Core.DTOs.Courier.CourierOrderDto>>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        var orders = await assignmentService.GetActiveOrdersForCourierAsync(courierId);

        var orderDtos = orders.Select(o =>
        {
            var orderCourier = o.OrderCouriers
                .Where(oc => oc.CourierId == courierId && oc.IsActive)
                .FirstOrDefault();

            var dto = _mapper.Map<CourierOrderDto>(o);

            // OrderCourier bilgilerini ekle
            if (orderCourier != null)
            {
                dto.DeliveryFee = orderCourier.DeliveryFee;
                dto.CourierStatus = orderCourier.Status;
                dto.CourierAssignedAt = orderCourier.CourierAssignedAt;
                dto.CourierAcceptedAt = orderCourier.CourierAcceptedAt;
                dto.CourierRejectedAt = orderCourier.CourierRejectedAt;
                dto.RejectReason = orderCourier.RejectReason;
                dto.PickedUpAt = orderCourier.PickedUpAt;
                dto.OutForDeliveryAt = orderCourier.OutForDeliveryAt;
                dto.DeliveredAt = orderCourier.DeliveredAt;
                dto.CourierTip = orderCourier.CourierTip;
            }

            return dto;
        }).ToList();

        return Ok(new ApiResponse<List<Talabi.Core.DTOs.Courier.CourierOrderDto>>(orderDtos, LocalizationService.GetLocalizedString(ResourceName, "ActiveOrdersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi kabul eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/accept")]
    public async Task<ActionResult<ApiResponse<object>>> AcceptOrder(Guid id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.AcceptOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "FailedToAcceptOrder", CurrentCulture), "ORDER_ACCEPT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderAcceptedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi reddeder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Reddetme bilgileri</param>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/reject")]
    public async Task<ActionResult<ApiResponse<object>>> RejectOrder(
        Guid id,
        [FromBody] Talabi.Core.DTOs.Courier.RejectOrderDto dto,
        [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        // Validate reject reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Trim().Length < 10)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "RejectReasonMustBeAtLeast10Characters", CurrentCulture),
                "INVALID_REJECT_REASON"
            ));
        }

        var success = await assignmentService.RejectOrderAsync(id, courier.Id, dto.Reason.Trim());
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "FailedToRejectOrder", CurrentCulture), "ORDER_REJECT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderRejectedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi teslim alır
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/pickup")]
    public async Task<ActionResult<ApiResponse<object>>> PickUpOrder(Guid id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.PickUpOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "FailedToPickUpOrder", CurrentCulture), "ORDER_PICKUP_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderPickedUpSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi teslim eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/deliver")]
    public async Task<ActionResult<ApiResponse<object>>> DeliverOrder(Guid id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {


        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.DeliverOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "FailedToDeliverOrder", CurrentCulture), "ORDER_DELIVER_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderDeliveredSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Teslimat kanıtı gönderir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Teslimat kanıtı bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/proof")]
    public async Task<ActionResult<ApiResponse<object>>> SubmitDeliveryProof(Guid id, [FromBody] SubmitDeliveryProofDto dto)
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.DeliveryProof)
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o => o.Id == id && o.OrderCouriers.Any(oc => oc.CourierId == courierId && oc.IsActive));

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFoundOrNotAssigned", CurrentCulture), "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Delivered)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderMustBeDeliveredBeforeSubmittingProof", CurrentCulture), "ORDER_NOT_DELIVERED"));
        }

        // Create or update delivery proof
        if (order.DeliveryProof == null)
        {
            order.DeliveryProof = new DeliveryProof
            {
                OrderId = order.Id,
                PhotoUrl = dto.PhotoUrl,
                SignatureUrl = dto.SignatureUrl,
                Notes = dto.Notes,
                ProofSubmittedAt = DateTime.UtcNow
            };
            await UnitOfWork.DeliveryProofs.AddAsync(order.DeliveryProof);
        }
        else
        {
            order.DeliveryProof.PhotoUrl = dto.PhotoUrl;
            order.DeliveryProof.SignatureUrl = dto.SignatureUrl;
            order.DeliveryProof.Notes = dto.Notes;
            order.DeliveryProof.ProofSubmittedAt = DateTime.UtcNow;
            UnitOfWork.DeliveryProofs.Update(order.DeliveryProof);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "DeliveryProofSubmittedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin sipariş geçmişini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20)</param>
    /// <returns>Sayfalanmış sipariş geçmişi</returns>
    [HttpGet("orders/history")]
    public async Task<ActionResult<ApiResponse<object>>> GetOrderHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        // Get orders through OrderCouriers
        var orderCouriers = await UnitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Order)
                .ThenInclude(o => o.Vendor)
            .Include(oc => oc.Order)
                .ThenInclude(o => o.Customer)
            .Include(oc => oc.Order)
                .ThenInclude(o => o.DeliveryAddress)
            .Include(oc => oc.Order)
                .ThenInclude(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
            .Where(oc => oc.CourierId == courier.Id
                && oc.Order != null
                && oc.Order.Status == OrderStatus.Delivered
                && oc.DeliveredAt.HasValue)
            .OrderByDescending(oc => oc.DeliveredAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var totalCount = await UnitOfWork.OrderCouriers.Query()
            .CountAsync(oc => oc.CourierId == courier.Id
                && oc.Order != null
                && oc.Order.Status == OrderStatus.Delivered
                && oc.DeliveredAt.HasValue);

        var orderDtos = _mapper.Map<List<CourierOrderDto>>(orderCouriers);

        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        var result = new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = totalPages,
            HasNextPage = page < totalPages,
            HasPreviousPage = page > 1,
            items = orderDtos
        };

        return Ok(new ApiResponse<object>(result, LocalizationService.GetLocalizedString(ResourceName, "OrderHistoryRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir siparişin detaylarını getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayları</returns>
    [HttpGet("orders/{id}")]
    public async Task<ActionResult<ApiResponse<CourierOrderDto>>> GetOrderDetail(Guid id)
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierOrderDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        // First try to get order if it's currently assigned to this courier
        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.DeliveryProof)
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o => o.Id == id && o.OrderCouriers.Any(oc => oc.CourierId == courierId && oc.IsActive));

        // If not found, check if this courier has a notification for this order
        // This allows viewing orders from notifications even if they were rejected or reassigned
        if (order == null)
        {
            var hasNotification = await UnitOfWork.CourierNotifications.Query()
                .AnyAsync(n => n.CourierId == courierId && n.OrderId == id);

            if (hasNotification)
            {
                // Get the order even if not currently assigned to this courier
                order = await UnitOfWork.Orders.Query()
                    .Include(o => o.Vendor)
                    .Include(o => o.Customer)
                    .Include(o => o.DeliveryAddress)
                    .Include(o => o.OrderItems)
                        .ThenInclude(oi => oi.Product)
                    .Include(o => o.DeliveryProof)
                    .FirstOrDefaultAsync(o => o.Id == id);
            }
        }

        if (order == null)
        {
            return NotFound(new ApiResponse<CourierOrderDto>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFoundOrNotAssigned", CurrentCulture), "ORDER_NOT_FOUND"));
        }

        var orderCourier = order.OrderCouriers
            .Where(oc => oc.CourierId == courier.Id)
            .OrderByDescending(oc => oc.CreatedAt)
            .FirstOrDefault();

        var orderDto = _mapper.Map<CourierOrderDto>(order);

        // OrderCourier bilgilerini ekle
        if (orderCourier != null)
        {
            orderDto.DeliveryFee = orderCourier.DeliveryFee;
            orderDto.CourierStatus = orderCourier.Status;
            orderDto.CourierAssignedAt = orderCourier.CourierAssignedAt;
            orderDto.CourierAcceptedAt = orderCourier.CourierAcceptedAt;
            orderDto.CourierRejectedAt = orderCourier.CourierRejectedAt;
            orderDto.RejectReason = orderCourier.RejectReason;
            orderDto.PickedUpAt = orderCourier.PickedUpAt;
            orderDto.OutForDeliveryAt = orderCourier.OutForDeliveryAt;
            orderDto.DeliveredAt = orderCourier.DeliveredAt;
            orderDto.CourierTip = orderCourier.CourierTip;
        }

        return Ok(new ApiResponse<CourierOrderDto>(orderDto, LocalizationService.GetLocalizedString(ResourceName, "OrderDetailsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin bugünkü kazançlarını getirir
    /// </summary>
    /// <returns>Bugünkü kazanç özeti</returns>
    [HttpGet("earnings/today")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetTodayEarnings()
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, LocalizationService.GetLocalizedString(ResourceName, "TodayEarningsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin haftalık kazançlarını getirir
    /// </summary>
    /// <returns>Haftalık kazanç özeti</returns>
    [HttpGet("earnings/week")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetWeekEarnings()
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, LocalizationService.GetLocalizedString(ResourceName, "WeekEarningsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin aylık kazançlarını getirir
    /// </summary>
    /// <returns>Aylık kazanç özeti</returns>
    [HttpGet("earnings/month")]
    public async Task<ActionResult<ApiResponse<EarningsSummaryDto>>> GetMonthEarnings()
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<EarningsSummaryDto>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, LocalizationService.GetLocalizedString(ResourceName, "MonthEarningsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin kazanç geçmişini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 50)</param>
    /// <returns>Sayfalanmış kazanç geçmişi</returns>
    [HttpGet("earnings/history")]
    public async Task<ActionResult<ApiResponse<object>>> GetEarningsHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {

        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture), "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<object>(result, LocalizationService.GetLocalizedString(ResourceName, "EarningsHistoryRetrievedSuccessfully", CurrentCulture)));
    }
}

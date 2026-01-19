using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Talabi.Api.Hubs;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers.Couriers;

/// <summary>
/// Courier Dashboard - Hesap ve profil yönetimi için controller
/// </summary>
[Route("api/couriers/dashboard/account")]
[ApiController]
[Authorize(Roles = "Courier")]
public class AccountController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private readonly IHubContext<NotificationHub> _hubContext;
    private const string ResourceName = "CourierResources";

    /// <summary>
    /// AccountController constructor
    /// </summary>
    public AccountController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<AccountController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IMapper mapper,
        IHubContext<NotificationHub> hubContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
        _mapper = mapper;
        _hubContext = hubContext;
    }

    private async Task<Courier?> GetCurrentCourierAsync(bool createIfMissing = false)
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
    [HttpGet("profile")]
    public async Task<ActionResult<ApiResponse<CourierProfileDto>>> GetProfile()
    {
        var courier = await GetCurrentCourierAsync(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierProfileDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var profile = _mapper.Map<CourierProfileDto>(courier);

        // Manually map WorkingHours
        profile.WorkingHours = courier.WorkingHours.Select(wh => new WorkingHourDto
        {
            DayOfWeek = (int)wh.DayOfWeek,
            DayName = LocalizationService.GetLocalizedString("CommonResources", wh.DayOfWeek.ToString(),
                CurrentCulture),
            StartTime = wh.StartTime,
            EndTime = wh.EndTime,
            IsClosed = wh.IsClosed
        }).ToList();

        return Ok(new ApiResponse<CourierProfileDto>(profile,
            LocalizationService.GetLocalizedString(ResourceName, "CourierProfileRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Kurye profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("profile")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile([FromBody] UpdateCourierProfileDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        courier.Name = dto.Name;
        courier.PhoneNumber = dto.PhoneNumber;
        courier.ShamCashAccountNumber = dto.ShamCashAccountNumber;

        // Vehicle type as enum
        if (!string.IsNullOrWhiteSpace(dto.VehicleType))
        {
            if (!Enum.TryParse<CourierVehicleType>(dto.VehicleType, true, out var vehicleType))
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidVehicleType", CurrentCulture),
                    "INVALID_VEHICLE_TYPE"));
            }

            courier.VehicleType = vehicleType;
        }

        courier.MaxActiveOrders = dto.MaxActiveOrders;
#pragma warning disable CS0618 // Type or member is obsolete
        courier.WorkingHoursStart = dto.WorkingHoursStart;
        courier.WorkingHoursEnd = dto.WorkingHoursEnd;
#pragma warning restore CS0618 // Type or member is obsolete

        courier.IsWithinWorkingHours = dto.IsWithinWorkingHours;

        // Update Working Hours Collection
        if (dto.WorkingHours != null)
        {
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

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "ProfileUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Mevcut araç tiplerini getirir
    /// </summary>
    /// <returns>Araç tipi listesi</returns>
    [HttpGet("vehicle-types")]
    public ActionResult<ApiResponse<List<object>>> GetVehicleTypes()
    {
        var types = new List<object>
        {
            new
            {
                Key = CourierVehicleType.Motorcycle.ToString(),
                Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeMotorcycle", CurrentCulture)
            },
            new
            {
                Key = CourierVehicleType.Car.ToString(),
                Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeCar", CurrentCulture)
            },
            new
            {
                Key = CourierVehicleType.Bicycle.ToString(),
                Name = LocalizationService.GetLocalizedString(ResourceName, "VehicleTypeBicycle", CurrentCulture)
            }
        };

        return Ok(new ApiResponse<List<object>>(types,
            LocalizationService.GetLocalizedString(ResourceName, "VehicleTypesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye durumunu günceller
    /// </summary>
    /// <param name="dto">Yeni durum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateStatus([FromBody] UpdateCourierStatusDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidStatus", CurrentCulture),
                "INVALID_STATUS"));
        }

        // Çalışma saati kontrolü
        if (newStatus == CourierStatus.Available && courier.IsWithinWorkingHours)
        {
            var now = DateTime.Now.TimeOfDay;
#pragma warning disable CS0618 // Type or member is obsolete
            if (courier.WorkingHoursStart.HasValue && courier.WorkingHoursEnd.HasValue)
            {
                if (now < courier.WorkingHoursStart.Value || now > courier.WorkingHoursEnd.Value)
                {
                    return BadRequest(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "CannotGoAvailableOutsideWorkingHours",
                            CurrentCulture), "OUTSIDE_WORKING_HOURS"));
                }
            }
#pragma warning restore CS0618 // Type or member is obsolete
        }

        // Aktif siparişi varsa Offline olamaz
        if (newStatus == CourierStatus.Offline && courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CannotGoOfflineWithActiveOrders", CurrentCulture),
                "CANNOT_GO_OFFLINE_WITH_ACTIVE_ORDERS"));
        }

        courier.Status = newStatus;
        courier.LastActiveAt = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        Logger.LogInformation("Courier {CourierId} status changed to {Status}", courier.Id, newStatus);

        return Ok(new ApiResponse<object>(new { Status = newStatus.ToString() },
            LocalizationService.GetLocalizedString(ResourceName, "StatusUpdated", CurrentCulture,
                newStatus.ToString())));
    }

    /// <summary>
    /// Kurye konumunu günceller
    /// </summary>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("location")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateLocation(
        [FromBody] Talabi.Core.DTOs.Courier.UpdateCourierLocationDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        if (dto.Latitude < -90 || dto.Latitude > 90)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidLatitude", CurrentCulture),
                "INVALID_LATITUDE"));
        }

        if (dto.Longitude < -180 || dto.Longitude > 180)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidLongitude", CurrentCulture),
                "INVALID_LONGITUDE"));
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Couriers.Update(courier);
        await UnitOfWork.SaveChangesAsync();

        // Broadcast to NotificationHub
        try
        {
            var activeOrders = await UnitOfWork.OrderCouriers.Query()
                .Where(oc =>
                    oc.CourierId == courier.Id && oc.IsActive && oc.Order != null &&
                    oc.Order.Status == OrderStatus.OutForDelivery)
                .Select(oc => new { oc.OrderId, VendorId = oc.Order!.VendorId })
                .ToListAsync();

            foreach (var order in activeOrders)
            {
                // Notify Customer (Order Tracking Group)
                await _hubContext.Clients.Group($"order_tracking_{order.OrderId}")
                    .SendAsync("OrderLocationUpdated", order.OrderId, dto.Latitude, dto.Longitude);

                // Notify Vendor
                await _hubContext.Clients.Group($"vendor_{order.VendorId}")
                    .SendAsync("CourierLocationUpdated", new
                    {
                        CourierId = courier.Id,
                        Lat = dto.Latitude,
                        Lng = dto.Longitude
                    });
            }
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Failed to broadcast location update for courier {CourierId}", courier.Id);
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "LocationUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kurye müsaitlik durumunu kontrol eder
    /// </summary>
    /// <returns>Müsaitlik durumu ve nedenleri</returns>
    [HttpGet("check-availability")]
    public async Task<ActionResult<ApiResponse<object>>> CheckAvailability()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<object>(result,
            LocalizationService.GetLocalizedString(ResourceName, "AvailabilityCheckedSuccessfully", CurrentCulture)));
    }
}

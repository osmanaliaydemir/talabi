using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kurye işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Courier")]
public class CourierController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<AppUser> _userManager;
    private readonly ILogger<CourierController> _logger;
    private readonly IStringLocalizer<CourierController> _localizer;

    /// <summary>
    /// CourierController constructor
    /// </summary>
    public CourierController(
        IUnitOfWork unitOfWork,
        UserManager<AppUser> userManager,
        ILogger<CourierController> logger,
        IStringLocalizer<CourierController> localizer)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
        _logger = logger;
        _localizer = localizer;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    private async Task<Courier?> GetCurrentCourier(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var courier = await _unitOfWork.Couriers.Query()
            .Include(c => c.User)
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

            await _unitOfWork.Couriers.AddAsync(courier);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Courier profile created automatically for user {UserId}", userId);
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
        var courier = await GetCurrentCourier(createIfMissing: true);
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierProfileDto>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        var profile = new CourierProfileDto
        {
            Id = courier.Id,
            UserId = courier.UserId,
            Name = courier.Name,
            PhoneNumber = courier.PhoneNumber,
            VehicleType = courier.VehicleType,
            IsActive = courier.IsActive,
            Status = courier.Status.ToString(),
            MaxActiveOrders = courier.MaxActiveOrders,
            CurrentActiveOrders = courier.CurrentActiveOrders,
            CurrentLatitude = courier.CurrentLatitude,
            CurrentLongitude = courier.CurrentLongitude,
            LastLocationUpdate = courier.LastLocationUpdate,
            TotalEarnings = courier.TotalEarnings,
            CurrentDayEarnings = courier.CurrentDayEarnings,
            TotalDeliveries = courier.TotalDeliveries,
            AverageRating = courier.AverageRating,
            WorkingHoursStart = courier.WorkingHoursStart,
            WorkingHoursEnd = courier.WorkingHoursEnd,
            IsWithinWorkingHours = courier.IsWithinWorkingHours
        };

        return Ok(new ApiResponse<CourierProfileDto>(profile, "Kurye profili başarıyla getirildi"));
    }

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
            return NotFound(new ApiResponse<object>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        courier.Name = dto.Name;
        courier.PhoneNumber = dto.PhoneNumber;

        // Vehicle type as enum (Motor, Araba, Bisiklet)
        if (!string.IsNullOrWhiteSpace(dto.VehicleType))
        {
            if (!Enum.TryParse<CourierVehicleType>(dto.VehicleType, true, out var vehicleType))
            {
                return BadRequest(new ApiResponse<object>("Geçersiz araç tipi", "INVALID_VEHICLE_TYPE"));
            }

            courier.VehicleType = vehicleType.ToString();
        }
        else
        {
            courier.VehicleType = null;
        }

        courier.MaxActiveOrders = dto.MaxActiveOrders;
        courier.WorkingHoursStart = dto.WorkingHoursStart;
        courier.WorkingHoursEnd = dto.WorkingHoursEnd;
        courier.IsWithinWorkingHours = dto.IsWithinWorkingHours;
        courier.UpdatedAt = DateTime.UtcNow;

        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, _localizer["ProfileUpdatedSuccessfully"]));
    }

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
            new { Key = CourierVehicleType.Motorcycle.ToString(), Name = "Motor" },
            new { Key = CourierVehicleType.Car.ToString(), Name = "Araba" },
            new { Key = CourierVehicleType.Bicycle.ToString(), Name = "Bisiklet" }
        };

        return Ok(new ApiResponse<List<object>>(types, "Araç tipleri başarıyla getirildi"));
    }

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
            return NotFound(new ApiResponse<object>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new ApiResponse<object>(_localizer["InvalidStatus"], "INVALID_STATUS"));
        }

        // Çalışma saati kontrolü
        if (newStatus == CourierStatus.Available && courier.IsWithinWorkingHours)
        {
            var now = DateTime.Now.TimeOfDay;
            if (courier.WorkingHoursStart.HasValue && courier.WorkingHoursEnd.HasValue)
            {
                if (now < courier.WorkingHoursStart.Value || now > courier.WorkingHoursEnd.Value)
                {
                    return BadRequest(new ApiResponse<object>(_localizer["CannotGoAvailableOutsideWorkingHours"], "OUTSIDE_WORKING_HOURS"));
                }
            }
        }

        // Aktif siparişi varsa Offline olamaz
        if (newStatus == CourierStatus.Offline && courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new ApiResponse<object>(_localizer["CannotGoOfflineWithActiveOrders"], "CANNOT_GO_OFFLINE_WITH_ACTIVE_ORDERS"));
        }

        courier.Status = newStatus;
        courier.LastActiveAt = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        _logger.LogInformation("Courier {CourierId} status changed to {Status}", courier.Id, newStatus);

        return Ok(new ApiResponse<object>(new { Status = newStatus.ToString() }, _localizer["StatusUpdated", newStatus.ToString()]));
    }

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
            return NotFound(new ApiResponse<object>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        if (dto.Latitude < -90 || dto.Latitude > 90)
        {
            return BadRequest(new ApiResponse<object>(_localizer["InvalidLatitude"], "INVALID_LATITUDE"));
        }

        if (dto.Longitude < -180 || dto.Longitude > 180)
        {
            return BadRequest(new ApiResponse<object>(_localizer["InvalidLongitude"], "INVALID_LONGITUDE"));
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, _localizer["LocationUpdatedSuccessfully"]));
    }

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
            return NotFound(new ApiResponse<CourierStatisticsDto>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var orders = await _unitOfWork.Orders.Query()
            .Where(o => o.CourierId == courier.Id && o.Status == OrderStatus.Delivered)
            .ToListAsync();

        var todayOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date == today);
        var weekOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date >= weekStart);
        var monthOrders = orders.Count(o => o.DeliveredAt.HasValue && o.DeliveredAt.Value.Date >= monthStart);

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

        return Ok(new ApiResponse<CourierStatisticsDto>(stats, "Kurye istatistikleri başarıyla getirildi"));
    }

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
            return NotFound(new ApiResponse<object>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
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

        return Ok(new ApiResponse<object>(result, "Müsaitlik durumu başarıyla kontrol edildi"));
    }

    /// <summary>
    /// Kurye konumunu günceller (Legacy endpoint - geriye dönük uyumluluk için)
    /// </summary>
    /// <param name="courierId">Kurye ID'si</param>
    /// <param name="dto">Yeni konum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{courierId}/location")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateLocationLegacy(Guid courierId, Talabi.Core.DTOs.Courier.UpdateCourierLocationDto dto)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(courierId);
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        if (courier.UserId != GetUserId())
        {
            return StatusCode(403, new ApiResponse<object>("Bu kurye için yetkiniz yok", "FORBIDDEN"));
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;

        _unitOfWork.Couriers.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Konum güncellendi"));
    }

    /// <summary>
    /// Belirli bir kuryenin konumunu getirir
    /// </summary>
    /// <param name="courierId">Kurye ID'si</param>
    /// <returns>Kurye konum bilgisi</returns>
    [HttpGet("{courierId}/location")]
    public async Task<ActionResult<ApiResponse<Talabi.Core.DTOs.CourierLocationDto>>> GetLocation(Guid courierId)
    {
        var courier = await _unitOfWork.Couriers.GetByIdAsync(courierId);
        if (courier == null)
        {
            return NotFound(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>("Kurye bulunamadı", "COURIER_NOT_FOUND"));
        }

        if (!courier.CurrentLatitude.HasValue || !courier.CurrentLongitude.HasValue)
        {
            return NotFound(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>("Kurye konumu bulunamadı", "LOCATION_NOT_FOUND"));
        }

        var locationDto = new Talabi.Core.DTOs.CourierLocationDto
        {
            CourierId = courier.Id,
            CourierName = courier.Name,
            Latitude = courier.CurrentLatitude.Value,
            Longitude = courier.CurrentLongitude.Value,
            LastUpdate = courier.LastLocationUpdate ?? DateTime.UtcNow
        };

        return Ok(new ApiResponse<Talabi.Core.DTOs.CourierLocationDto>(locationDto, "Kurye konumu başarıyla getirildi"));
    }

    /// <summary>
    /// Aktif kuryelerin konumlarını getirir
    /// </summary>
    /// <returns>Aktif kurye konum listesi</returns>
    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<List<Talabi.Core.DTOs.CourierLocationDto>>>> GetActiveCouriers()
    {
        var couriers = await _unitOfWork.Couriers.Query()
            .Where(c => c.IsActive &&
                       c.CurrentLatitude.HasValue &&
                       c.CurrentLongitude.HasValue)
            .Select(c => new Talabi.Core.DTOs.CourierLocationDto
            {
                CourierId = c.Id,
                CourierName = c.Name,
                Latitude = c.CurrentLatitude!.Value,
                Longitude = c.CurrentLongitude!.Value,
                LastUpdate = c.LastLocationUpdate ?? DateTime.UtcNow
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<Talabi.Core.DTOs.CourierLocationDto>>(couriers, "Aktif kuryeler başarıyla getirildi"));
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
            return NotFound(new ApiResponse<List<Talabi.Core.DTOs.Courier.CourierOrderDto>>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var orders = await assignmentService.GetActiveOrdersForCourierAsync(courier.Id);

        var orderDtos = orders.Select(o => new Talabi.Core.DTOs.Courier.CourierOrderDto
        {
            Id = o.Id,
            VendorName = o.Vendor?.Name ?? "Unknown Vendor",
            VendorAddress = o.Vendor?.Address ?? "",
            VendorLatitude = o.Vendor?.Latitude ?? 0,
            VendorLongitude = o.Vendor?.Longitude ?? 0,
            CustomerName = o.Customer?.FullName ?? "Unknown Customer",
            DeliveryAddress = o.DeliveryAddress?.FullAddress ?? "",
            DeliveryLatitude = o.DeliveryAddress?.Latitude ?? 0,
            DeliveryLongitude = o.DeliveryAddress?.Longitude ?? 0,
            DeliveryFee = o.DeliveryFee,
            Status = o.Status.ToString(),
            CreatedAt = o.CreatedAt,
            Items = o.OrderItems.Select(i => new Talabi.Core.DTOs.Courier.CourierOrderItemDto
            {
                ProductName = i.Product?.Name ?? "Unknown Product",
                Quantity = i.Quantity
            }).ToList()
        }).ToList();

        return Ok(new ApiResponse<List<Talabi.Core.DTOs.Courier.CourierOrderDto>>(orderDtos, "Aktif siparişler başarıyla getirildi"));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.AcceptOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(_localizer["FailedToAcceptOrder"], "ORDER_ACCEPT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, _localizer["OrderAcceptedSuccessfully"]));
    }

    /// <summary>
    /// Siparişi reddeder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="assignmentService">Sipariş atama servisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("orders/{id}/reject")]
    public async Task<ActionResult<ApiResponse<object>>> RejectOrder(Guid id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.RejectOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(_localizer["FailedToRejectOrder"], "ORDER_REJECT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, _localizer["OrderRejectedSuccessfully"]));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.PickUpOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(_localizer["FailedToPickUpOrder"], "ORDER_PICKUP_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, _localizer["OrderPickedUpSuccessfully"]));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await assignmentService.DeliverOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(_localizer["FailedToDeliverOrder"], "ORDER_DELIVER_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, _localizer["OrderDeliveredSuccessfully"]));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.DeliveryProof)
            .FirstOrDefaultAsync(o => o.Id == id && o.CourierId == courier.Id);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(_localizer["OrderNotFoundOrNotAssigned"], "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Delivered)
        {
            return BadRequest(new ApiResponse<object>(_localizer["OrderMustBeDeliveredBeforeSubmittingProof"], "ORDER_NOT_DELIVERED"));
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
            await _unitOfWork.DeliveryProofs.AddAsync(order.DeliveryProof);
        }
        else
        {
            order.DeliveryProof.PhotoUrl = dto.PhotoUrl;
            order.DeliveryProof.SignatureUrl = dto.SignatureUrl;
            order.DeliveryProof.Notes = dto.Notes;
            order.DeliveryProof.ProofSubmittedAt = DateTime.UtcNow;
            _unitOfWork.DeliveryProofs.Update(order.DeliveryProof);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, _localizer["DeliveryProofSubmittedSuccessfully"]));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        IQueryable<Order> query = _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Where(o => o.CourierId == courier.Id && o.Status == OrderStatus.Delivered);

        IOrderedQueryable<Order> orderedQuery = query.OrderByDescending(o => o.DeliveredAt);

        // Gelişmiş query helper kullanımı - Pagination ve DTO mapping tek satırda
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            o => new CourierOrderDto
            {
                Id = o.Id,
                VendorName = o.Vendor != null ? o.Vendor.Name : "Unknown Vendor",
                VendorAddress = o.Vendor != null ? o.Vendor.Address : "",
                VendorLatitude = o.Vendor != null && o.Vendor.Latitude.HasValue ? (double)o.Vendor.Latitude.Value : 0,
                VendorLongitude = o.Vendor != null && o.Vendor.Longitude.HasValue ? (double)o.Vendor.Longitude.Value : 0,
                CustomerName = o.Customer != null ? o.Customer.FullName : "Unknown Customer",
                DeliveryAddress = o.DeliveryAddress != null ? o.DeliveryAddress.FullAddress : "",
                DeliveryLatitude = o.DeliveryAddress != null && o.DeliveryAddress.Latitude.HasValue ? (double)o.DeliveryAddress.Latitude.Value : 0,
                DeliveryLongitude = o.DeliveryAddress != null && o.DeliveryAddress.Longitude.HasValue ? (double)o.DeliveryAddress.Longitude.Value : 0,
                DeliveryFee = o.DeliveryFee,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt,
                Items = o.OrderItems.Select(i => new CourierOrderItemDto
                {
                    ProductName = i.Product != null ? i.Product.Name : "Unknown Product",
                    Quantity = i.Quantity
                }).ToList()
            },
            page,
            pageSize);

        var result = new
        {
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages,
            HasNextPage = pagedResult.HasNextPage,
            HasPreviousPage = pagedResult.HasPreviousPage,
            Orders = pagedResult.Items
        };

        return Ok(new ApiResponse<object>(result, "Sipariş geçmişi başarıyla getirildi"));
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
            return NotFound(new ApiResponse<CourierOrderDto>(_localizer["CourierProfileNotFound"], "COURIER_PROFILE_NOT_FOUND"));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.DeliveryProof)
            .FirstOrDefaultAsync(o => o.Id == id && o.CourierId == courier.Id);

        if (order == null)
        {
            return NotFound(new ApiResponse<CourierOrderDto>("Sipariş bulunamadı veya size atanmamış", "ORDER_NOT_FOUND"));
        }

        var orderDto = new CourierOrderDto
        {
            Id = order.Id,
            VendorName = order.Vendor?.Name ?? "Unknown Vendor",
            VendorAddress = order.Vendor?.Address ?? "",
            VendorLatitude = order.Vendor?.Latitude ?? 0,
            VendorLongitude = order.Vendor?.Longitude ?? 0,
            CustomerName = order.Customer?.FullName ?? "Unknown Customer",
            DeliveryAddress = order.DeliveryAddress?.FullAddress ?? "",
            DeliveryLatitude = order.DeliveryAddress?.Latitude ?? 0,
            DeliveryLongitude = order.DeliveryAddress?.Longitude ?? 0,
            DeliveryFee = order.DeliveryFee,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt,
            Items = order.OrderItems.Select(i => new CourierOrderItemDto
            {
                ProductName = i.Product?.Name ?? "Unknown Product",
                Quantity = i.Quantity
            }).ToList()
        };

        return Ok(new ApiResponse<CourierOrderDto>(orderDto, "Sipariş detayları başarıyla getirildi"));
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
            return NotFound(new ApiResponse<EarningsSummaryDto>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var earnings = await _unitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date == today)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = earnings.Select(e => new CourierEarningDto
            {
                Id = e.Id,
                OrderId = e.OrderId,
                BaseDeliveryFee = e.BaseDeliveryFee,
                DistanceBonus = e.DistanceBonus,
                TipAmount = e.TipAmount,
                TotalEarning = e.TotalEarning,
                EarnedAt = e.EarnedAt,
                IsPaid = e.IsPaid
            }).ToList()
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, "Bugünkü kazançlar başarıyla getirildi"));
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
            return NotFound(new ApiResponse<EarningsSummaryDto>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);

        var earnings = await _unitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date >= weekStart)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = earnings.Select(e => new CourierEarningDto
            {
                Id = e.Id,
                OrderId = e.OrderId,
                BaseDeliveryFee = e.BaseDeliveryFee,
                DistanceBonus = e.DistanceBonus,
                TipAmount = e.TipAmount,
                TotalEarning = e.TotalEarning,
                EarnedAt = e.EarnedAt,
                IsPaid = e.IsPaid
            }).ToList()
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, "Haftalık kazançlar başarıyla getirildi"));
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
            return NotFound(new ApiResponse<EarningsSummaryDto>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        var today = DateTime.Today;
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var earnings = await _unitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id && e.EarnedAt.Date >= monthStart)
            .OrderByDescending(e => e.EarnedAt)
            .ToListAsync();

        var summary = new EarningsSummaryDto
        {
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            TotalDeliveries = earnings.Count,
            AverageEarningPerDelivery = earnings.Any() ? earnings.Average(e => e.TotalEarning) : 0,
            Earnings = earnings.Select(e => new CourierEarningDto
            {
                Id = e.Id,
                OrderId = e.OrderId,
                BaseDeliveryFee = e.BaseDeliveryFee,
                DistanceBonus = e.DistanceBonus,
                TipAmount = e.TipAmount,
                TotalEarning = e.TotalEarning,
                EarnedAt = e.EarnedAt,
                IsPaid = e.IsPaid
            }).ToList()
        };

        return Ok(new ApiResponse<EarningsSummaryDto>(summary, "Aylık kazançlar başarıyla getirildi"));
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
            return NotFound(new ApiResponse<object>("Kurye profili bulunamadı", "COURIER_PROFILE_NOT_FOUND"));
        }

        IQueryable<CourierEarning> query = _unitOfWork.CourierEarnings.Query()
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id);

        IOrderedQueryable<CourierEarning> orderedQuery = query.OrderByDescending(e => e.EarnedAt);

        var totalCount = await orderedQuery.CountAsync();
        var earnings = await orderedQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var earningDtos = earnings.Select(e => new CourierEarningDto
        {
            Id = e.Id,
            OrderId = e.OrderId,
            BaseDeliveryFee = e.BaseDeliveryFee,
            DistanceBonus = e.DistanceBonus,
            TipAmount = e.TipAmount,
            TotalEarning = e.TotalEarning,
            EarnedAt = e.EarnedAt,
            IsPaid = e.IsPaid
        }).ToList();

        var result = new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            Earnings = earningDtos
        };

        return Ok(new ApiResponse<object>(result, "Kazanç geçmişi başarıyla getirildi"));
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Localization;
using System.Security.Claims;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Courier")]
public class CourierController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<CourierController> _logger;
    private readonly IStringLocalizer<CourierController> _localizer;

    public CourierController(
        TalabiDbContext context,
        ILogger<CourierController> logger,
        IStringLocalizer<CourierController> localizer)
    {
        _context = context;
        _logger = logger;
        _localizer = localizer;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    private async Task<Courier?> GetCurrentCourier(bool createIfMissing = false)
    {
        var userId = GetUserId();
        var courier = await _context.Couriers
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (courier == null && createIfMissing)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
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

            _context.Couriers.Add(courier);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Courier profile created automatically for user {UserId}", userId);
        }

        return courier;
    }

    // GET: api/courier/profile
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var courier = await GetCurrentCourier(createIfMissing: true);
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

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

        return Ok(profile);
    }

    // PUT: api/courier/profile
    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateCourierProfileDto dto)
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        courier.Name = dto.Name;
        courier.PhoneNumber = dto.PhoneNumber;

        // Vehicle type as enum (Motor, Araba, Bisiklet)
        if (!string.IsNullOrWhiteSpace(dto.VehicleType))
        {
            if (!Enum.TryParse<CourierVehicleType>(dto.VehicleType, true, out var vehicleType))
            {
                return BadRequest(new { Message = "Invalid vehicle type" });
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

        await _context.SaveChangesAsync();

        return Ok(new { Message = _localizer["ProfileUpdatedSuccessfully"] });
    }

    [HttpGet("vehicle-types")]
    public ActionResult<IEnumerable<object>> GetVehicleTypes()
    {
        // Motor, Araba, Bisiklet seçenekleri
        var types = new List<object>
        {
            new { Key = CourierVehicleType.Motorcycle.ToString(), Name = "Motor" },
            new { Key = CourierVehicleType.Car.ToString(), Name = "Araba" },
            new { Key = CourierVehicleType.Bicycle.ToString(), Name = "Bisiklet" }
        };

        return Ok(types);
    }

    // PUT: api/courier/status
    [HttpPut("status")]
    public async Task<IActionResult> UpdateStatus([FromBody] UpdateCourierStatusDto dto)
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        if (!Enum.TryParse<CourierStatus>(dto.Status, true, out var newStatus))
        {
            return BadRequest(new { Message = _localizer["InvalidStatus"] });
        }

        // Çalışma saati kontrolü
        if (newStatus == CourierStatus.Available && courier.IsWithinWorkingHours)
        {
            var now = DateTime.Now.TimeOfDay;
            if (courier.WorkingHoursStart.HasValue && courier.WorkingHoursEnd.HasValue)
            {
                if (now < courier.WorkingHoursStart.Value || now > courier.WorkingHoursEnd.Value)
                {
                    return BadRequest(new { Message = _localizer["CannotGoAvailableOutsideWorkingHours"] });
                }
            }
        }

        // Aktif siparişi varsa Offline olamaz
        if (newStatus == CourierStatus.Offline && courier.CurrentActiveOrders > 0)
        {
            return BadRequest(new { Message = _localizer["CannotGoOfflineWithActiveOrders"] });
        }

        courier.Status = newStatus;
        courier.LastActiveAt = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Courier {CourierId} status changed to {Status}", courier.Id, newStatus);

        return Ok(new { Message = _localizer["StatusUpdated", newStatus.ToString()], Status = newStatus.ToString() });
    }

    // PUT: api/courier/location
    [HttpPut("location")]
    public async Task<IActionResult> UpdateLocation([FromBody] UpdateCourierLocationDto dto)
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        if (dto.Latitude < -90 || dto.Latitude > 90)
            return BadRequest(new { Message = _localizer["InvalidLatitude"] });

        if (dto.Longitude < -180 || dto.Longitude > 180)
            return BadRequest(new { Message = _localizer["InvalidLongitude"] });

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;
        courier.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { Message = _localizer["LocationUpdatedSuccessfully"] });
    }

    // GET: api/courier/statistics
    [HttpGet("statistics")]
    public async Task<IActionResult> GetStatistics()
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var orders = await _context.Orders
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

        return Ok(stats);
    }

    // GET: api/courier/check-availability
    [HttpGet("check-availability")]
    public async Task<IActionResult> CheckAvailability()
    {
        var courier = await GetCurrentCourier();
        if (courier == null)
            return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        var isAvailable = courier.Status == CourierStatus.Available
            && courier.IsActive
            && courier.CurrentActiveOrders < courier.MaxActiveOrders;

        var reasons = new List<string>();
        if (!courier.IsActive) reasons.Add("Courier is not active");
        if (courier.Status != CourierStatus.Available) reasons.Add($"Status is {courier.Status}");
        if (courier.CurrentActiveOrders >= courier.MaxActiveOrders) reasons.Add("Maximum active orders reached");

        return Ok(new
        {
            IsAvailable = isAvailable,
            Status = courier.Status.ToString(),
            CurrentActiveOrders = courier.CurrentActiveOrders,
            MaxActiveOrders = courier.MaxActiveOrders,
            Reasons = reasons
        });
    }

    // Legacy endpoints for backward compatibility
    [HttpPut("{courierId}/location")]
    public async Task<ActionResult> UpdateLocationLegacy(int courierId, UpdateCourierLocationDto dto)
    {
        var courier = await _context.Couriers.FindAsync(courierId);
        if (courier == null)
            return NotFound("Courier not found");

        if (courier.UserId != GetUserId())
            return Forbid();

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Location updated" });
    }

    [HttpGet("{courierId}/location")]
    public async Task<ActionResult<Talabi.Core.DTOs.CourierLocationDto>> GetLocation(int courierId)
    {
        var courier = await _context.Couriers.FindAsync(courierId);
        if (courier == null)
            return NotFound("Courier not found");

        if (!courier.CurrentLatitude.HasValue || !courier.CurrentLongitude.HasValue)
            return NotFound(_localizer["LocationUpdatedSuccessfully"]); // Using existing key, can add new one if needed

        return Ok(new Talabi.Core.DTOs.CourierLocationDto
        {
            CourierId = courier.Id,
            CourierName = courier.Name,
            Latitude = courier.CurrentLatitude.Value,
            Longitude = courier.CurrentLongitude.Value,
            LastUpdate = courier.LastLocationUpdate ?? DateTime.UtcNow
        });
    }

    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<ActionResult<List<Talabi.Core.DTOs.CourierLocationDto>>> GetActiveCouriers()
    {
        var couriers = await _context.Couriers
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

        return Ok(couriers);
    }

    // GET: api/courier/orders/active
    [HttpGet("orders/active")]
    public async Task<IActionResult> GetActiveOrders([FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

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

        return Ok(orderDtos);
    }

    // POST: api/courier/orders/{id}/accept
    [HttpPost("orders/{id}/accept")]
    public async Task<IActionResult> AcceptOrder(int id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var success = await assignmentService.AcceptOrderAsync(id, courier.Id);
        if (!success) return BadRequest(new { Message = _localizer["FailedToAcceptOrder"] });

        return Ok(new { Message = _localizer["OrderAcceptedSuccessfully"] });
    }

    // POST: api/courier/orders/{id}/reject
    [HttpPost("orders/{id}/reject")]
    public async Task<IActionResult> RejectOrder(int id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var success = await assignmentService.RejectOrderAsync(id, courier.Id);
        if (!success) return BadRequest(new { Message = _localizer["FailedToRejectOrder"] });

        return Ok(new { Message = _localizer["OrderRejectedSuccessfully"] });
    }

    // POST: api/courier/orders/{id}/pickup
    [HttpPost("orders/{id}/pickup")]
    public async Task<IActionResult> PickUpOrder(int id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var success = await assignmentService.PickUpOrderAsync(id, courier.Id);
        if (!success) return BadRequest(new { Message = _localizer["FailedToPickUpOrder"] });

        return Ok(new { Message = _localizer["OrderPickedUpSuccessfully"] });
    }

    // POST: api/courier/orders/{id}/deliver
    [HttpPost("orders/{id}/deliver")]
    public async Task<IActionResult> DeliverOrder(int id, [FromServices] Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var success = await assignmentService.DeliverOrderAsync(id, courier.Id);
        if (!success) return BadRequest(new { Message = _localizer["FailedToDeliverOrder"] });

        return Ok(new { Message = _localizer["OrderDeliveredSuccessfully"] });
    }

    // POST: api/courier/orders/{id}/proof
    [HttpPost("orders/{id}/proof")]
    public async Task<IActionResult> SubmitDeliveryProof(int id, [FromBody] SubmitDeliveryProofDto dto)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var order = await _context.Orders
            .Include(o => o.DeliveryProof)
            .FirstOrDefaultAsync(o => o.Id == id && o.CourierId == courier.Id);

        if (order == null)
            return NotFound(new { Message = _localizer["OrderNotFoundOrNotAssigned"] });

        if (order.Status != OrderStatus.Delivered)
            return BadRequest(new { Message = _localizer["OrderMustBeDeliveredBeforeSubmittingProof"] });

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
            _context.DeliveryProofs.Add(order.DeliveryProof);
        }
        else
        {
            order.DeliveryProof.PhotoUrl = dto.PhotoUrl;
            order.DeliveryProof.SignatureUrl = dto.SignatureUrl;
            order.DeliveryProof.Notes = dto.Notes;
            order.DeliveryProof.ProofSubmittedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return Ok(new { Message = _localizer["DeliveryProofSubmittedSuccessfully"] });
    }

    // GET: api/courier/orders/history
    [HttpGet("orders/history")]
    public async Task<IActionResult> GetOrderHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var query = _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Where(o => o.CourierId == courier.Id && o.Status == OrderStatus.Delivered)
            .OrderByDescending(o => o.DeliveredAt);

        var totalCount = await query.CountAsync();
        var orders = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var orderDtos = orders.Select(o => new CourierOrderDto
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
            Items = o.OrderItems.Select(i => new CourierOrderItemDto
            {
                ProductName = i.Product?.Name ?? "Unknown Product",
                Quantity = i.Quantity
            }).ToList()
        }).ToList();

        return Ok(new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            Orders = orderDtos
        });
    }

    // GET: api/courier/orders/{id}
    [HttpGet("orders/{id}")]
    public async Task<IActionResult> GetOrderDetail(int id)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = _localizer["CourierProfileNotFound"] });

        var order = await _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.DeliveryProof)
            .FirstOrDefaultAsync(o => o.Id == id && o.CourierId == courier.Id);

        if (order == null)
            return NotFound(new { Message = "Order not found or not assigned to you" });

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

        return Ok(orderDto);
    }

    // GET: api/courier/earnings/today
    [HttpGet("earnings/today")]
    public async Task<IActionResult> GetTodayEarnings()
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var today = DateTime.Today;
        var earnings = await _context.CourierEarnings
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

        return Ok(summary);
    }

    // GET: api/courier/earnings/week
    [HttpGet("earnings/week")]
    public async Task<IActionResult> GetWeekEarnings()
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var today = DateTime.Today;
        var weekStart = today.AddDays(-(int)today.DayOfWeek);

        var earnings = await _context.CourierEarnings
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

        return Ok(summary);
    }

    // GET: api/courier/earnings/month
    [HttpGet("earnings/month")]
    public async Task<IActionResult> GetMonthEarnings()
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var today = DateTime.Today;
        var monthStart = new DateTime(today.Year, today.Month, 1);

        var earnings = await _context.CourierEarnings
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

        return Ok(summary);
    }

    // GET: api/courier/earnings/history
    [HttpGet("earnings/history")]
    public async Task<IActionResult> GetEarningsHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var courier = await GetCurrentCourier();
        if (courier == null) return NotFound(new { Message = "Courier profile not found" });

        var query = _context.CourierEarnings
            .Include(e => e.Order)
            .Where(e => e.CourierId == courier.Id)
            .OrderByDescending(e => e.EarnedAt);

        var totalCount = await query.CountAsync();
        var earnings = await query
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

        return Ok(new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalEarnings = earnings.Sum(e => e.TotalEarning),
            Earnings = earningDtos
        });
    }
}

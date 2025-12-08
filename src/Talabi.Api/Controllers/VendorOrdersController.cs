using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı sipariş işlemleri için controller
/// </summary>
[Route("api/vendor/orders")]
[ApiController]
[Authorize]
public class VendorOrdersController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IOrderAssignmentService _assignmentService;

    /// <summary>
    /// VendorOrdersController constructor
    /// </summary>
    public VendorOrdersController(IUnitOfWork unitOfWork, IOrderAssignmentService assignmentService)
    {
        _unitOfWork = unitOfWork;
        _assignmentService = assignmentService;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? throw new UnauthorizedAccessException();

    private async Task<Guid?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _unitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    /// <summary>
    /// Satıcının siparişlerini getirir
    /// </summary>
    /// <param name="status">Sipariş durumu filtresi (opsiyonel)</param>
    /// <param name="startDate">Başlangıç tarihi filtresi (opsiyonel)</param>
    /// <param name="endDate">Bitiş tarihi filtresi (opsiyonel)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış sipariş listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorOrderDto>>>> GetVendorOrders([FromQuery] string? status = null,
        [FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null, [FromQuery] int page = 1, [FromQuery] int pageSize = 6)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<PagedResultDto<VendorOrderDto>>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
        }

        IQueryable<Order> query = _unitOfWork.Orders.Query()
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Where(o => o.VendorId == vendorId);

        // Filter by status
        if (!string.IsNullOrEmpty(status))
        {
            // "OutForDelivery" status'ü Assigned, Accepted ve OutForDelivery status'lerini içerir
            if (status.Equals("OutForDelivery", StringComparison.OrdinalIgnoreCase))
            {
                query = query.Where(o => o.Status == OrderStatus.Assigned 
                    || o.Status == OrderStatus.Accepted 
                    || o.Status == OrderStatus.OutForDelivery);
            }
            else if (Enum.TryParse<OrderStatus>(status, out var statusEnum))
            {
                query = query.Where(o => o.Status == statusEnum);
            }
        }
        else
        {
            // Status belirtilmediğinde Cancelled siparişleri hariç tut
            query = query.Where(o => o.Status != OrderStatus.Cancelled);
        }

        // Filter by date range - Gelişmiş query helper kullanımı
        query = query.WhereDateRange(o => o.CreatedAt, startDate, endDate);

        IOrderedQueryable<Order> orderedQuery = query.OrderByDescending(o => o.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            o => new VendorOrderDto
            {
                Id = o.Id,
                CustomerOrderId = o.CustomerOrderId,
                CustomerName = o.Customer!.FullName,
                CustomerEmail = o.Customer.Email!,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt,
                EstimatedDeliveryTime = o.EstimatedDeliveryTime,
                Items = o.OrderItems.Select(oi => new VendorOrderItemDto
                {
                    ProductId = oi.ProductId,
                    ProductName = oi.Product!.Name,
                    ProductImageUrl = oi.Product.ImageUrl,
                    Quantity = oi.Quantity,
                    UnitPrice = oi.UnitPrice,
                    TotalPrice = oi.Quantity * oi.UnitPrice
                }).ToList()
            },
            page,
            pageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<VendorOrderDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<VendorOrderDto>>(result, "Satıcı siparişleri başarıyla getirildi"));
    }

    /// <summary>
    /// Belirli bir siparişi getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş bilgileri</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VendorOrderDto>>> GetVendorOrder(Guid id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<VendorOrderDto>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.OrderCouriers)
            .ThenInclude(oc => oc.Courier)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<VendorOrderDto>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        // Get active courier assignment
        var activeOrderCourier = order.OrderCouriers.FirstOrDefault(oc => oc.IsActive);
        VendorCourierInfoDto? courierDto = null;
        
        if (activeOrderCourier != null && activeOrderCourier.Courier != null)
        {
            courierDto = new VendorCourierInfoDto
            {
                Id = activeOrderCourier.Courier.Id,
                Name = activeOrderCourier.Courier.Name,
                PhoneNumber = activeOrderCourier.Courier.PhoneNumber,
                VehicleType = activeOrderCourier.Courier.VehicleType,
                Status = activeOrderCourier.Status.ToString(),
                AssignedAt = activeOrderCourier.CourierAssignedAt,
                AcceptedAt = activeOrderCourier.CourierAcceptedAt,
                PickedUpAt = activeOrderCourier.PickedUpAt,
                OutForDeliveryAt = activeOrderCourier.OutForDeliveryAt
            };
        }

        var orderDto = new VendorOrderDto
        {
            Id = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            CustomerName = order.Customer!.FullName,
            CustomerEmail = order.Customer.Email!,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt,
            EstimatedDeliveryTime = order.EstimatedDeliveryTime,
            Items = order.OrderItems.Select(oi => new VendorOrderItemDto
            {
                ProductId = oi.ProductId,
                ProductName = oi.Product!.Name,
                ProductImageUrl = oi.Product.ImageUrl,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TotalPrice = oi.Quantity * oi.UnitPrice
            }).ToList(),
            Courier = courierDto
        };

        return Ok(new ApiResponse<VendorOrderDto>(orderDto, "Sipariş başarıyla getirildi"));
    }

    /// <summary>
    /// Siparişi kabul eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/accept")]
    public async Task<ActionResult<ApiResponse<object>>> AcceptOrder(Guid id)
    {
        try
        {
            var vendorId = await GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
            }

            // Order'ı Include olmadan yüklüyoruz
            var order = await _unitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
            }

            if (order.Status != OrderStatus.Pending)
            {
                return BadRequest(new ApiResponse<object>("Sipariş yalnızca Beklemede durumundayken kabul edilebilir", "INVALID_ORDER_STATUS"));
            }

            var userId = GetUserId();
            order.Status = OrderStatus.Preparing;

            _unitOfWork.Orders.Update(order); // Order'ı güncelliyoruz

            // StatusHistory'yi ayrı bir entity olarak ekliyoruz
            await _unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Preparing,
                Note = "Order accepted by vendor",
                CreatedBy = userId ?? "System"
            });

            // Add customer notification
            if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
            {
                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    "Sipariş Onaylandı",
                    $"#{order.Id} numaralı siparişiniz onaylandı ve hazırlanmaya başlandı.",
                    "OrderAccepted",
                    order.Id);
            }

            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Sipariş başarıyla kabul edildi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Sipariş kabul edilirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
    }

    /// <summary>
    /// Siparişi reddeder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Reddetme nedeni</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/reject")]
    public async Task<ActionResult<ApiResponse<object>>> RejectOrder(Guid id, [FromBody] RejectOrderDto dto)
    {
        try
        {
            var vendorId = await GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
            }

            // Order'ı Include etmeden yükle (concurrency sorununu önlemek için)
            var order = await _unitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
            }

            if (order.Status != OrderStatus.Pending)
            {
                return BadRequest(new ApiResponse<object>("Sipariş yalnızca Beklemede durumundayken reddedilebilir", "INVALID_ORDER_STATUS"));
            }

            if (dto == null || string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
            {
                return BadRequest(new ApiResponse<object>("Reddetme nedeni en az 10 karakter olmalıdır", "INVALID_REJECTION_REASON"));
            }

            var userId = GetUserId();
            
            // Order'ı güncelle
            order.Status = OrderStatus.Cancelled;
            order.CancelledAt = DateTime.UtcNow;
            order.CancelReason = $"Rejected by vendor: {dto.Reason}";
            _unitOfWork.Orders.Update(order);

            // StatusHistory'yi ayrı bir entity olarak ekle (concurrency sorununu önlemek için)
            var statusHistory = new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Cancelled,
                Note = $"Rejected by vendor: {dto.Reason}",
                CreatedBy = userId ?? "System"
            };
            await _unitOfWork.OrderStatusHistories.AddAsync(statusHistory);

            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Sipariş başarıyla reddedildi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>($"Sipariş reddedilirken bir hata oluştu: {ex.Message}", "INTERNAL_SERVER_ERROR"));
        }
    }

    /// <summary>
    /// Sipariş durumunu günceller
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Yeni durum bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateOrderStatus(Guid id, [FromBody] UpdateOrderStatusDto dto)
    {
        try
        {
            var vendorId = await GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
            }

            // Order'ı Include olmadan yüklüyoruz
            var order = await _unitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
            }

            if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
            {
                return BadRequest(new ApiResponse<object>("Geçersiz durum", "INVALID_STATUS"));
            }

            // Validate status transition for vendor
            if (!IsValidVendorStatusTransition(order.Status, newStatus))
            {
                return BadRequest(new ApiResponse<object>($"Durum {order.Status} durumundan {newStatus} durumuna geçirilemez", "INVALID_STATUS_TRANSITION"));
            }

            var userId = GetUserId();
            order.Status = newStatus;

            // Set estimated delivery time if status is Ready
            if (newStatus == OrderStatus.Ready && !order.EstimatedDeliveryTime.HasValue)
            {
                order.EstimatedDeliveryTime = DateTime.UtcNow.AddMinutes(30); // Default 30 minutes
            }

            _unitOfWork.Orders.Update(order); // Order'ı güncelliyoruz

            // StatusHistory'yi ayrı bir entity olarak ekliyoruz
            await _unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = newStatus,
                Note = dto.Note ?? $"Status updated to {newStatus}",
                CreatedBy = userId ?? "System"
            });

            // Add customer notification for status change
            if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
            {
                var statusMessage = newStatus switch
                {
                    OrderStatus.Preparing => "Siparişiniz hazırlanıyor",
                    OrderStatus.Ready => "Siparişiniz hazır, kurye atanıyor",
                    OrderStatus.Delivered => "Siparişiniz teslim edildi",
                    OrderStatus.Cancelled => "Siparişiniz iptal edildi",
                    _ => "Sipariş durumu güncellendi"
                };

                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    "Sipariş Durumu Güncellendi",
                    $"#{order.Id} numaralı sipariş: {statusMessage}",
                    "OrderStatusChanged",
                    order.Id);
            }

            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Sipariş durumu başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Sipariş durumu güncellenirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
    }

    private bool IsValidVendorStatusTransition(OrderStatus current, OrderStatus next)
    {
        return current switch
        {
            OrderStatus.Pending => next is OrderStatus.Preparing or OrderStatus.Cancelled,
            OrderStatus.Preparing => next is OrderStatus.Ready or OrderStatus.Cancelled,
            OrderStatus.Ready => next is OrderStatus.Cancelled or OrderStatus.Assigned or OrderStatus.Delivered,
            OrderStatus.Delivered => false,
            OrderStatus.Cancelled => false,
            _ => false
        };
    }

    /// <summary>
    /// Manuel atama için müsait kuryeleri getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Müsait kurye listesi</returns>
    [HttpGet("{id}/available-couriers")]
    public async Task<ActionResult<ApiResponse<List<AvailableCourierDto>>>> GetAvailableCouriers(Guid id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<List<AvailableCourierDto>>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<List<AvailableCourierDto>>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<List<AvailableCourierDto>>("Kurye atamak için sipariş Hazır durumunda olmalıdır", "INVALID_ORDER_STATUS"));
        }

        // Get vendor location
        var vendor = order.Vendor;
        if (vendor == null || !vendor.Latitude.HasValue || !vendor.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<List<AvailableCourierDto>>("Satıcı konumu ayarlanmamış", "VENDOR_LOCATION_NOT_SET"));
        }

        // Get available couriers (first get all, then calculate distance in memory)
        var availableCouriersQuery = await _unitOfWork.Couriers.Query()
            .Where(c => c.IsActive
                && c.Status == CourierStatus.Available
                && c.CurrentActiveOrders < c.MaxActiveOrders
                && c.CurrentLatitude.HasValue
                && c.CurrentLongitude.HasValue)
            .ToListAsync();

        // Calculate distances in memory and filter
        var availableCouriers = availableCouriersQuery
            .Select(c => new
            {
                Courier = c,
                Distance = CalculateDistance(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    c.CurrentLatitude!.Value,
                    c.CurrentLongitude!.Value
                )
            })
            .Where(x => x.Distance <= 10) // Max 10km
            .OrderBy(x => x.Distance)
            .Select(x => new AvailableCourierDto
            {
                Id = x.Courier.Id,
                FullName = x.Courier.Name,
                PhoneNumber = x.Courier.PhoneNumber ?? string.Empty,
                VehicleType = x.Courier.VehicleType ?? "Unknown",
                AverageRating = x.Courier.AverageRating,
                TotalDeliveries = x.Courier.TotalDeliveries,
                CurrentActiveOrders = x.Courier.CurrentActiveOrders,
                MaxActiveOrders = x.Courier.MaxActiveOrders,
                Distance = Math.Round(x.Distance, 2),
                EstimatedArrivalMinutes = (int)Math.Ceiling(x.Distance * 3) // Rough estimate: 3 min per km
            })
            .ToList();

        return Ok(new ApiResponse<List<AvailableCourierDto>>(availableCouriers, "Müsait kuryeler başarıyla getirildi"));
    }

    /// <summary>
    /// Siparişe manuel olarak kurye atar
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Kurye bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/assign-courier")]
    public async Task<ActionResult<ApiResponse<object>>> AssignCourier(Guid id, [FromBody] AssignCourierDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
        }

        var order = await _unitOfWork.Orders.Query()
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<object>("Kurye atamak için sipariş Hazır durumunda olmalıdır", "INVALID_ORDER_STATUS"));
        }

        // Check if order already has an active courier assignment
        var hasActiveCourier = await _unitOfWork.OrderCouriers.Query()
            .AnyAsync(oc => oc.OrderId == id && oc.IsActive);
        
        if (hasActiveCourier)
        {
            return BadRequest(new ApiResponse<object>("Siparişe zaten bir kurye atanmış", "COURIER_ALREADY_ASSIGNED"));
        }

        // Assign courier using the service
        var success = await _assignmentService.AssignOrderToCourierAsync(id, dto.CourierId);

        if (!success)
        {
            return BadRequest(new ApiResponse<object>("Kurye atanamadı. Kurye müsait olmayabilir veya sipariş durumu geçersiz olabilir", "COURIER_ASSIGNMENT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, "Kurye başarıyla atandı"));
    }

    /// <summary>
    /// En uygun kuryeyi otomatik olarak atar
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu ve atanan kurye bilgisi</returns>
    [HttpPost("{id}/auto-assign-courier")]
    public async Task<ActionResult<ApiResponse<object>>> AutoAssignCourier(Guid id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<object>("Kullanıcı bir satıcı değil", "NOT_A_VENDOR"));
        }

        var order = await _unitOfWork.Orders.Query()
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<object>("Kurye atamak için sipariş Hazır durumunda olmalıdır", "INVALID_ORDER_STATUS"));
        }

        // Check if order already has an active courier assignment
        var hasActiveCourier = await _unitOfWork.OrderCouriers.Query()
            .AnyAsync(oc => oc.OrderId == id && oc.IsActive);
        
        if (hasActiveCourier)
        {
            return BadRequest(new ApiResponse<object>("Siparişe zaten bir kurye atanmış", "COURIER_ALREADY_ASSIGNED"));
        }

        // Find best courier
        var bestCourier = await _assignmentService.FindBestCourierAsync(order);

        if (bestCourier == null)
        {
            return BadRequest(new ApiResponse<object>("Yakınlarda müsait kurye bulunamadı", "NO_AVAILABLE_COURIERS"));
        }

        // Assign courier
        var success = await _assignmentService.AssignOrderToCourierAsync(id, bestCourier.Id);

        if (!success)
        {
            return BadRequest(new ApiResponse<object>("Kurye atanamadı", "COURIER_ASSIGNMENT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new
        {
            CourierId = bestCourier.Id,
            CourierName = bestCourier.Name
        }, "Kurye otomatik olarak başarıyla atandı"));
    }

    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371; // Radius of the earth in km
        var dLat = Deg2Rad(lat2 - lat1);
        var dLon = Deg2Rad(lon2 - lon1);
        var a =
            Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
            Math.Cos(Deg2Rad(lat1)) * Math.Cos(Deg2Rad(lat2)) *
            Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        var d = R * c; // Distance in km
        return d;
    }

    private double Deg2Rad(double deg)
    {
        return deg * (Math.PI / 180);
    }

    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type, Guid? orderId = null)
    {
        var customer = await _unitOfWork.Customers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);
        if (customer == null)
        {
            // Create customer if doesn't exist
            customer = new Customer
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            await _unitOfWork.Customers.AddAsync(customer);
            await _unitOfWork.SaveChangesAsync();
        }

        await _unitOfWork.CustomerNotifications.AddAsync(new CustomerNotification
        {
            CustomerId = customer.Id,
            Title = title,
            Message = message,
            Type = type,
            OrderId = orderId
        });
    }
}

public class RejectOrderDto
{
    [JsonPropertyName("reason")]
    public string Reason { get; set; } = string.Empty;
}

public class AssignCourierDto
{
    public Guid CourierId { get; set; }
}

public class AvailableCourierDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string VehicleType { get; set; } = string.Empty;
    public double AverageRating { get; set; }
    public int TotalDeliveries { get; set; }
    public int CurrentActiveOrders { get; set; }
    public int MaxActiveOrders { get; set; }
    public double Distance { get; set; }
    public int EstimatedArrivalMinutes { get; set; }
}


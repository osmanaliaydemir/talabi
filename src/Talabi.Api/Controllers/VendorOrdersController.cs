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
using System.Globalization;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı sipariş işlemleri için controller
/// </summary>
[Route("api/vendor/orders")]
[ApiController]
[Authorize]
public class VendorOrdersController : BaseController
{
    private readonly IOrderAssignmentService _assignmentService;
    private readonly IMapper _mapper;
    private readonly INotificationService _notificationService;
    private const string ResourceName = "VendorOrderResources";

    /// <summary>
    /// VendorOrdersController constructor
    /// </summary>
    public VendorOrdersController(
        IUnitOfWork unitOfWork,
        ILogger<VendorOrdersController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IOrderAssignmentService assignmentService,
        IMapper mapper,
        INotificationService notificationService)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _assignmentService = assignmentService;
        _mapper = mapper;
        _notificationService = notificationService;
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

        var vendorId = await UserContext.GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<PagedResultDto<VendorOrderDto>>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
        }

        IQueryable<Order> query = UnitOfWork.Orders.Query()
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
                CustomerName = o.Customer.FullName,
                CustomerEmail = o.Customer.Email,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt,
                EstimatedDeliveryTime = o.EstimatedDeliveryTime,
                Items = _mapper.Map<List<VendorOrderItemDto>>(o.OrderItems)
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

        return Ok(new ApiResponse<PagedResultDto<VendorOrderDto>>(result, LocalizationService.GetLocalizedString(ResourceName, "VendorOrdersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir siparişi getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş bilgileri</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VendorOrderDto>>> GetVendorOrder(Guid id)
    {
        var vendorId = await UserContext.GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<VendorOrderDto>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
        }

        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.OrderCouriers)
            .ThenInclude(oc => oc.Courier)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<VendorOrderDto>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
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
                VehicleType = activeOrderCourier.Courier.VehicleType.ToString(),
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
            CustomerName = order.Customer?.FullName ?? "Misafir",
            CustomerEmail = order.Customer?.Email ?? "-",
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt,
            EstimatedDeliveryTime = order.EstimatedDeliveryTime,
            Items = order.OrderItems.Select(oi => new VendorOrderItemDto
            {
                ProductId = oi.ProductId,
                ProductName = oi.Product?.Name ?? "Unknown Product",
                ProductImageUrl = oi.Product?.ImageUrl,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TotalPrice = oi.Quantity * oi.UnitPrice
            }).ToList(),
            Courier = courierDto
        };

        return Ok(new ApiResponse<VendorOrderDto>(orderDto, LocalizationService.GetLocalizedString(ResourceName, "OrderRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi kabul eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/accept")]
    public async Task<ActionResult<ApiResponse<object>>> AcceptOrder(Guid id)
    {
            var vendorId = await UserContext.GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
            }

            // Order'ı Include olmadan yüklüyoruz
            var order = await UnitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
            }

            if (order.Status != OrderStatus.Pending)
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderCanOnlyBeAcceptedWhenPending", CurrentCulture), "INVALID_ORDER_STATUS"));
            }

            var userId = UserContext.GetUserId();
            order.Status = OrderStatus.Preparing;

            UnitOfWork.Orders.Update(order); // Order'ı güncelliyoruz

            // StatusHistory'yi ayrı bir entity olarak ekliyoruz
            await UnitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Preparing,
                Note = "Order accepted by vendor",
                CreatedBy = userId ?? "System"
            });

            // Add customer notification
            if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
            {
                var notificationTitle = LocalizationService.GetLocalizedString(ResourceName, "OrderAcceptedTitle", CurrentCulture);
                var notificationMessage = LocalizationService.GetLocalizedString(ResourceName, "OrderAcceptedMessage", CurrentCulture, order.CustomerOrderId);
                
                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    notificationTitle,
                    notificationMessage,
                    "OrderAccepted",
                    order.Id);

                // Send Firebase push notification to customer
                var languageCode = CurrentCulture.TwoLetterISOLanguageName;
                await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, order.Id, "Preparing", languageCode);
            }

            await UnitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderAcceptedSuccessfully", CurrentCulture)));
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
            var vendorId = await UserContext.GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
            }

            // Order'ı Include etmeden yükle (concurrency sorununu önlemek için)
            var order = await UnitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
            }

            if (order.Status != OrderStatus.Pending)
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderCanOnlyBeRejectedWhenPending", CurrentCulture), "INVALID_ORDER_STATUS"));
            }

            if (dto == null || string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRejectionReason", CurrentCulture), "INVALID_REJECTION_REASON"));
            }

            var userId = UserContext.GetUserId();
            
            // Order'ı güncelle
            order.Status = OrderStatus.Cancelled;
            order.CancelledAt = DateTime.UtcNow;
            order.CancelReason = $"Rejected by vendor: {dto.Reason}";
            UnitOfWork.Orders.Update(order);

            // StatusHistory'yi ayrı bir entity olarak ekle (concurrency sorununu önlemek için)
            var statusHistory = new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Cancelled,
                Note = $"Rejected by vendor: {dto.Reason}",
                CreatedBy = userId ?? "System"
            };
            await UnitOfWork.OrderStatusHistories.AddAsync(statusHistory);

            // Add customer notification
            if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
            {
                var notificationTitle = LocalizationService.GetLocalizedString(ResourceName, "OrderRejectedTitle", CurrentCulture);
                var notificationMessage = LocalizationService.GetLocalizedString(ResourceName, "OrderRejectedMessage", CurrentCulture, order.CustomerOrderId, dto.Reason);
                
                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    notificationTitle,
                    notificationMessage,
                    "OrderRejected",
                    order.Id);

                // Send Firebase push notification to customer
                var languageCode = CurrentCulture.TwoLetterISOLanguageName;
                await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, order.Id, "Cancelled", languageCode);
            }

            await UnitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderRejectedSuccessfully", CurrentCulture)));
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
            var vendorId = await UserContext.GetVendorIdAsync();
            if (vendorId == null)
            {
                return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
            }

            // Order'ı Include olmadan yüklüyoruz
            var order = await UnitOfWork.Orders.Query()
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

            if (order == null)
            {
                return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
            }

            if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidOrderStatus", CurrentCulture), "INVALID_STATUS"));
            }

            // Validate status transition for vendor
            if (!IsValidVendorStatusTransition(order.Status, newStatus))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidStatusTransition", CurrentCulture, order.Status, newStatus), "INVALID_STATUS_TRANSITION"));
            }

            var userId = UserContext.GetUserId();
            order.Status = newStatus;

            // Set estimated delivery time if status is Ready
            if (newStatus == OrderStatus.Ready && !order.EstimatedDeliveryTime.HasValue)
            {
                order.EstimatedDeliveryTime = DateTime.UtcNow.AddMinutes(30); // Default 30 minutes
            }

            UnitOfWork.Orders.Update(order); // Order'ı güncelliyoruz

            // StatusHistory'yi ayrı bir entity olarak ekliyoruz
            await UnitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
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
                    OrderStatus.Preparing => LocalizationService.GetLocalizedString(ResourceName, "OrderStatusPreparing", CurrentCulture),
                    OrderStatus.Ready => LocalizationService.GetLocalizedString(ResourceName, "OrderStatusReady", CurrentCulture),
                    OrderStatus.Delivered => LocalizationService.GetLocalizedString(ResourceName, "OrderStatusDelivered", CurrentCulture),
                    OrderStatus.Cancelled => LocalizationService.GetLocalizedString(ResourceName, "OrderStatusCancelled", CurrentCulture),
                    _ => LocalizationService.GetLocalizedString(ResourceName, "OrderStatusUpdated", CurrentCulture)
                };

                var notificationTitle = LocalizationService.GetLocalizedString(ResourceName, "OrderStatusChangedTitle", CurrentCulture);
                var notificationMessage = LocalizationService.GetLocalizedString(ResourceName, "OrderStatusMessage", CurrentCulture, order.CustomerOrderId, statusMessage);

                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    notificationTitle,
                    notificationMessage,
                    "OrderStatusChanged",
                    order.Id);

                // Send Firebase push notification to customer
                var languageCode = CurrentCulture.TwoLetterISOLanguageName;
                await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, order.Id, newStatus.ToString(), languageCode);
            }

            await UnitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "OrderStatusUpdatedSuccessfully", CurrentCulture)));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error updating order status for order {OrderId}", id);
            return StatusCode(500, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "ErrorUpdatingOrderStatus", CurrentCulture), "INTERNAL_ERROR"));
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
        var vendorId = await UserContext.GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<List<AvailableCourierDto>>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
        }

        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<List<AvailableCourierDto>>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<List<AvailableCourierDto>>(LocalizationService.GetLocalizedString(ResourceName, "OrderMustBeReadyForCourierAssignment", CurrentCulture), "INVALID_ORDER_STATUS"));
        }

        // Get vendor location
        var vendor = order.Vendor;
        if (vendor == null || !vendor.Latitude.HasValue || !vendor.Longitude.HasValue)
        {
            return BadRequest(new ApiResponse<List<AvailableCourierDto>>(LocalizationService.GetLocalizedString(ResourceName, "VendorLocationNotSet", CurrentCulture), "VENDOR_LOCATION_NOT_SET"));
        }

        // Get available couriers (first get all, then calculate distance in memory)
        var availableCouriersQuery = await UnitOfWork.Couriers.Query()
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
                Distance = Talabi.Core.Helpers.GeoHelper.CalculateDistance(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    c.CurrentLatitude!.Value,
                    c.CurrentLongitude!.Value
                )
            })
            .Where(x => x.Distance <= 10) // Max 10km
            .OrderBy(x => x.Distance)
            .Select(x =>
            {
                var dto = new AvailableCourierDto
                {
                    Id = x.Courier.Id,
                    FullName = x.Courier.Name,
                    PhoneNumber = x.Courier.PhoneNumber ?? string.Empty,
                    VehicleType = x.Courier.VehicleType.ToString(),
                    AverageRating = x.Courier.AverageRating,
                    TotalDeliveries = x.Courier.TotalDeliveries,
                    CurrentActiveOrders = x.Courier.CurrentActiveOrders,
                    MaxActiveOrders = x.Courier.MaxActiveOrders,
                    Distance = Math.Round(x.Distance, 2),
                    EstimatedArrivalMinutes = (int)Math.Ceiling(x.Distance * 3) // Rough estimate: 3 min per km
                };
                return dto;
            })
            .ToList();

        return Ok(new ApiResponse<List<AvailableCourierDto>>(availableCouriers, LocalizationService.GetLocalizedString(ResourceName, "AvailableCouriersRetrievedSuccessfully", CurrentCulture)));
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
        var vendorId = await UserContext.GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
        }

        var order = await UnitOfWork.Orders.Query()
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderMustBeReadyForCourierAssignment", CurrentCulture), "INVALID_ORDER_STATUS"));
        }

        // Check if order already has an active courier assignment
        var hasActiveCourier = await UnitOfWork.OrderCouriers.Query()
            .AnyAsync(oc => oc.OrderId == id && oc.IsActive);
        
        if (hasActiveCourier)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierAlreadyAssigned", CurrentCulture), "COURIER_ALREADY_ASSIGNED"));
        }

        // Assign courier using the service
        var success = await _assignmentService.AssignOrderToCourierAsync(id, dto.CourierId);

        if (!success)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierAssignmentFailed", CurrentCulture), "COURIER_ASSIGNMENT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CourierAssignedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// En uygun kuryeyi otomatik olarak atar
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu ve atanan kurye bilgisi</returns>
    [HttpPost("{id}/auto-assign-courier")]
    public async Task<ActionResult<ApiResponse<object>>> AutoAssignCourier(Guid id)
    {
        var vendorId = await UserContext.GetVendorIdAsync();
        if (vendorId == null)
        {
            return StatusCode(403, new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NotAVendor", CurrentCulture), "NOT_A_VENDOR"));
        }

        var order = await UnitOfWork.Orders.Query()
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture), "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "OrderMustBeReadyForCourierAssignment", CurrentCulture), "INVALID_ORDER_STATUS"));
        }

        // Check if order already has an active courier assignment
        var hasActiveCourier = await UnitOfWork.OrderCouriers.Query()
            .AnyAsync(oc => oc.OrderId == id && oc.IsActive);
        
        if (hasActiveCourier)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CourierAlreadyAssigned", CurrentCulture), "COURIER_ALREADY_ASSIGNED"));
        }

        // Broadcast to nearby couriers
        var offeredCount = await _assignmentService.BroadcastOrderToCouriersAsync(id, 5.0); // 5km radius

        if (offeredCount == 0)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "NoAvailableCouriers", CurrentCulture), "NO_AVAILABLE_COURIERS"));
        }

        return Ok(new ApiResponse<object>(new
        {
            OfferedCount = offeredCount
        }, LocalizationService.GetLocalizedString(ResourceName, "OrderBroadcastedSuccessfully", CurrentCulture)));
    }


    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type, Guid? orderId = null)
    {
        var customer = await UnitOfWork.Customers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);
        if (customer == null)
        {
            // Create customer if doesn't exist
            customer = new Customer
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            await UnitOfWork.Customers.AddAsync(customer);
            await UnitOfWork.SaveChangesAsync();
        }

        await UnitOfWork.CustomerNotifications.AddAsync(new CustomerNotification
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


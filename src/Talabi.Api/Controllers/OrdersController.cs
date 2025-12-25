using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Sipariş işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class OrdersController : BaseController
{
    private readonly IOrderAssignmentService _assignmentService;
    private readonly IOrderService _orderService;
    private readonly IMapper _mapper;
    private const string ResourceName = "OrderResources";

    /// <summary>
    /// OrdersController constructor
    /// </summary>
    public OrdersController(
        IUnitOfWork unitOfWork,
        ILogger<OrdersController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IOrderAssignmentService assignmentService,
        IOrderService orderService,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _assignmentService = assignmentService;
        _orderService = orderService;
        _mapper = mapper;
    }

    /// <summary>
    /// Yeni sipariş oluşturur
    /// </summary>
    /// <param name="dto">Sipariş bilgileri</param>
    /// <returns>Oluşturulan sipariş</returns>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<OrderDto>>> CreateOrder(CreateOrderDto dto)
    {
        try
        {
            // Transaction başlat
            await UnitOfWork.BeginTransactionAsync();

            var customerId = UserContext.GetUserId() ?? "anonymous";
            var order = await _orderService.CreateOrderAsync(dto, customerId, CurrentCulture);

            // Transaction commit
            await UnitOfWork.CommitTransactionAsync();

            // Automatic Courier Assignment (outside transaction)
            try
            {
                var bestCourier = await _assignmentService.FindBestCourierAsync(order);
                if (bestCourier != null)
                {
                    await _assignmentService.AssignOrderToCourierAsync(order.Id, bestCourier.Id);
                }
            }
            catch
            {
                // Log error but continue
            }

            // Load vendor for mapping
            await UnitOfWork.Vendors.GetByIdAsync(order.VendorId);
            var orderDto = _mapper.Map<OrderDto>(order);

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, new ApiResponse<OrderDto>(
                orderDto,
                LocalizationService.GetLocalizedString(ResourceName, "OrderCreatedSuccessfully", CurrentCulture)));
        }
        catch (Exception)
        {
            await UnitOfWork.RollbackTransactionAsync();
            throw;
        }
    }

    /// <summary>
    /// Sipariş tutarlarını hesaplar
    /// </summary>
    /// <param name="dto">Hesaplama kriterleri</param>
    /// <returns>Hesaplama sonucu</returns>
    [HttpPost("calculate")]
    public async Task<ActionResult<ApiResponse<OrderCalculationResultDto>>> CalculateOrder(CalculateOrderDto dto)
    {
        var userId = UserContext.GetUserId() ?? "anonymous"; // Or null if strictly required

        var result = await _orderService.CalculateOrderAsync(dto, userId, CurrentCulture);

        return Ok(new ApiResponse<OrderCalculationResultDto>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "OrderCalculatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// ID'ye göre sipariş getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> GetOrder(Guid id)
    {
        var userId = UserContext.GetUserId();

        // Authorization: User must be authenticated to view orders
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<OrderDto>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        IQueryable<Order> query = UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.OrderCouriers)
            .ThenInclude(oc => oc.Courier)
            .ThenInclude(c => c.User);

        // Only allow access to orders that belong to the authenticated user
        var order = await query.FirstOrDefaultAsync(o => o.Id == id && o.CustomerId == userId);

        if (order == null)
        {
            return NotFound(new ApiResponse<OrderDto>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        var orderDto = _mapper.Map<OrderDto>(order);

        var activeCourier = order.ActiveOrderCourier;
        if (activeCourier?.Courier != null)
        {
            var courier = activeCourier.Courier;
            orderDto.ActiveOrderCourier = new OrderCourierDto
            {
                CourierId = courier.Id,
                CourierName = !string.IsNullOrEmpty(courier.Name) ? courier.Name : (courier.User?.FullName ?? "Courier"),
                CourierPhone = courier.PhoneNumber,
                CourierImageUrl = courier.User?.ProfileImageUrl
            };
        }

        return Ok(new ApiResponse<OrderDto>(
            orderDto,
            LocalizationService.GetLocalizedString(ResourceName, "OrderRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcının tüm siparişlerini getirir
    /// </summary>
    /// <param name="vendorType">Satıcı türü filtresi (opsiyonel)</param>
    /// <returns>Sipariş listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<OrderDto>>>> GetOrders([FromQuery] Talabi.Core.Enums.VendorType? vendorType = null)
    {

        var userId = UserContext.GetUserId();

        if (userId == null)
        {
            return Unauthorized(new ApiResponse<List<OrderDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        IQueryable<Order> query = UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Where(o => o.CustomerId == userId);

        // VendorType filtresi
        if (vendorType.HasValue)
        {
            query = query.Where(o => o.Vendor.Type == vendorType.Value);
        }

        IOrderedQueryable<Order> orderedQuery = query.OrderByDescending(o => o.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        // Not: GetOrders() şu anda pagination parametresi almıyor, bu yüzden tüm sonuçları döndürüyor
        // Eğer pagination eklenirse ToPagedResultAsync kullanılabilir
        var orders = await orderedQuery
            .ToListAsync();

        var orderDtos = _mapper.Map<List<OrderDto>>(orders);

        return Ok(new ApiResponse<List<OrderDto>>(
            orderDtos,
            LocalizationService.GetLocalizedString(ResourceName, "OrdersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sipariş detayını getirir (tüm bilgilerle)
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayı</returns>
    [HttpGet("{id}/detail")]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> GetOrderDetail(Guid id)
    {
        var userId = UserContext.GetUserId();

        // Authorization: User must be authenticated to view order details
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<OrderDetailDto>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        IQueryable<Order> query = UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.StatusHistory.OrderByDescending(sh => sh.CreatedAt));

        // Only allow access to orders that belong to the authenticated user
        var order = await query.FirstOrDefaultAsync(o => o.Id == id && o.CustomerId == userId);

        if (order == null)
        {
            return NotFound(new ApiResponse<OrderDetailDto>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        var orderDetailDto = _mapper.Map<OrderDetailDto>(order);

        return Ok(new ApiResponse<OrderDetailDto>(
            orderDetailDto,
            LocalizationService.GetLocalizedString(ResourceName, "OrderDetailRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sipariş durumunu günceller
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Güncellenecek durum bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateOrderStatus(Guid id, UpdateOrderStatusDto dto)
    {
        var userId = UserContext.GetUserId();

        // Authorization: User must be authenticated
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        // Check if order exists and user has permission
        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        // Authorization: Only vendor owner, courier assigned to order, or admin can update status
        // For customer orders, only the customer can update (but typically customers don't update status)
        // This endpoint is typically used by vendors/couriers, so we check vendor ownership
        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.Id == order.VendorId && v.OwnerId == userId);

        if (vendor == null)
        {
            // Check if user is a courier assigned to this order
            var courier = await UnitOfWork.Couriers.Query()
                .Include(c => c.OrderCouriers)
                .FirstOrDefaultAsync(c => c.UserId == userId &&
                    c.OrderCouriers.Any(oc => oc.OrderId == id && oc.IsActive));

            if (courier == null)
            {
                // Check if user is the customer (customers typically can't update status, but we check for completeness)
                if (order.CustomerId != userId)
                {
                    return Forbid(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "Forbidden", CurrentCulture),
                        "FORBIDDEN").ToString() ?? "");
                }
            }
        }

        await _orderService.UpdateOrderStatusAsync(id, dto, userId, CurrentCulture);

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "OrderStatusUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi iptal eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">İptal bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<ApiResponse<object>>> CancelOrder(Guid id, CancelOrderDto dto)
    {
        var userId = UserContext.GetUserId();

        try
        {
            await UnitOfWork.BeginTransactionAsync();
            await _orderService.CancelOrderAsync(id, userId, dto, CurrentCulture);
            await UnitOfWork.CommitTransactionAsync();

            return Ok(new ApiResponse<object>(
                new { },
                LocalizationService.GetLocalizedString(ResourceName, "OrderCancelledSuccessfully", CurrentCulture)));
        }
        catch (DbUpdateConcurrencyException)
        {
            await UnitOfWork.RollbackTransactionAsync();
            return Conflict(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ConcurrencyConflict", CurrentCulture),
                "CONCURRENCY_CONFLICT"
            ));
        }
        catch
        {
            await UnitOfWork.RollbackTransactionAsync();
            throw; // Let ExceptionHandlingMiddleware handle it
        }
    }

    /// <summary>
    /// Sipariş ürününü iptal eder
    /// </summary>
    /// <param name="customerOrderItemId">Müşteri sipariş ürün ID'si</param>
    /// <param name="dto">İptal bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("items/{customerOrderItemId}/cancel")]
    public async Task<ActionResult<ApiResponse<object>>> CancelOrderItem(string customerOrderItemId, CancelOrderDto dto)
    {

        var userId = UserContext.GetUserId();

        if (userId == null)
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Unauthorized", CurrentCulture),
                "UNAUTHORIZED"));
        }

        try
        {
            await UnitOfWork.BeginTransactionAsync();

            // Find the order item by CustomerOrderItemId
            var orderItem = await UnitOfWork.OrderItems.Query()
                .Include(oi => oi.Order!)
                    .ThenInclude(o => o.StatusHistory)
                .FirstOrDefaultAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);

            if (orderItem == null)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return NotFound(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "OrderItemNotFound", CurrentCulture),
                    "ORDER_ITEM_NOT_FOUND"));
            }

            // Check if order exists and belongs to user
            if (orderItem.Order == null)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return NotFound(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                    "ORDER_NOT_FOUND"));
            }

            if (orderItem.Order.CustomerId != userId)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return Forbid(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "Forbidden", CurrentCulture),
                    "FORBIDDEN").ToString() ?? "");
            }

            // Check if already cancelled
            if (orderItem.IsCancelled)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "AlreadyCancelled", CurrentCulture),
                    "ALREADY_CANCELLED"));
            }

            // Check if order can have items cancelled (only Pending or Preparing)
            if (orderItem.Order.Status != OrderStatus.Pending && orderItem.Order.Status != OrderStatus.Preparing)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "OrderItemInvalidCancellationStatus", CurrentCulture),
                    "INVALID_CANCELLATION_STATUS"
                ));
            }

            // Validate reason
            if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
            {
                await UnitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidCancellationReason", CurrentCulture),
                    "INVALID_CANCELLATION_REASON"
                ));
            }

            // Update order item
            orderItem.IsCancelled = true;
            orderItem.CancelledAt = DateTime.UtcNow;
            orderItem.CancelReason = dto.Reason;

            // Recalculate order total (subtract cancelled item's total)
            var cancelledItemTotal = orderItem.Quantity * orderItem.UnitPrice;
            orderItem.Order.TotalAmount -= cancelledItemTotal;

            // Check if all items are cancelled, then cancel the whole order
            // Note: We need to check after updating IsCancelled, so we check if count of non-cancelled items is 0
            var remainingItemsCount = await UnitOfWork.OrderItems.Query()
                .Where(oi => oi.OrderId == orderItem.OrderId && oi.Id != orderItem.Id && !oi.IsCancelled)
                .CountAsync();

            var allItemsCancelled = remainingItemsCount == 0;

            // Ensure StatusHistory is initialized
            if (orderItem.Order.StatusHistory == null)
            {
                orderItem.Order.StatusHistory = new List<OrderStatusHistory>();
            }

            if (allItemsCancelled)
            {
                orderItem.Order.Status = OrderStatus.Cancelled;
                orderItem.Order.CancelledAt = DateTime.UtcNow;
                orderItem.Order.CancelReason = "All items cancelled";

                // Add to status history
                orderItem.Order.StatusHistory.Add(new OrderStatusHistory
                {
                    OrderId = orderItem.Order.Id,
                    Status = OrderStatus.Cancelled,
                    Note = "Order cancelled: All items were cancelled",
                    CreatedBy = userId
                });
            }
            else
            {
                // Add status history note for item cancellation
                orderItem.Order.StatusHistory.Add(new OrderStatusHistory
                {
                    OrderId = orderItem.Order.Id,
                    Status = orderItem.Order.Status,
                    Note = $"Item #{customerOrderItemId} cancelled: {dto.Reason}",
                    CreatedBy = userId
                });
            }

            UnitOfWork.OrderItems.Update(orderItem);
            UnitOfWork.Orders.Update(orderItem.Order);
            await UnitOfWork.SaveChangesAsync();

            // Note: Customer notification for order item cancellation can be added via service if needed

            await UnitOfWork.SaveChangesAsync();
            await UnitOfWork.CommitTransactionAsync();

            return Ok(new ApiResponse<object>(
                new { },
                LocalizationService.GetLocalizedString(ResourceName, "OrderItemCancelledSuccessfully", CurrentCulture)));
        }
        catch
        {
            await UnitOfWork.RollbackTransactionAsync();
            throw; // Let ExceptionHandlingMiddleware handle it
        }
    }

}

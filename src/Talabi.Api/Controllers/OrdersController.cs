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
/// Sipariş işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class OrdersController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IOrderAssignmentService _assignmentService;

    /// <summary>
    /// OrdersController constructor
    /// </summary>
    public OrdersController(IUnitOfWork unitOfWork, IOrderAssignmentService assignmentService)
    {
        _unitOfWork = unitOfWork;
        _assignmentService = assignmentService;
    }

    /// <summary>
    /// Benzersiz müşteri sipariş ID'si oluşturur
    /// </summary>
    private async Task<string> GenerateUniqueCustomerOrderIdAsync()
    {
        var random = new Random();
        string customerOrderId;
        bool isUnique;

        do
        {
            customerOrderId = random.Next(100000, 999999).ToString();
            isUnique = !await _unitOfWork.Orders.Query().AnyAsync(o => o.CustomerOrderId == customerOrderId);
        } while (!isUnique);

        return customerOrderId;
    }

    /// <summary>
    /// Benzersiz müşteri sipariş ürün ID'si oluşturur
    /// </summary>
    private async Task<string> GenerateUniqueCustomerOrderItemIdAsync()
    {
        var random = new Random();
        string customerOrderItemId;
        bool isUnique;

        do
        {
            customerOrderItemId = random.Next(100000, 999999).ToString();
            isUnique = !await _unitOfWork.OrderItems.Query().AnyAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);
        } while (!isUnique);

        return customerOrderItemId;
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
            await _unitOfWork.BeginTransactionAsync();

            // Validate vendor exists
            var vendor = await _unitOfWork.Vendors.GetByIdAsync(dto.VendorId);
            if (vendor == null)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<OrderDto>("Satıcı bulunamadı", "VENDOR_NOT_FOUND"));
            }

            // Calculate total and create order items
            decimal totalAmount = 0;
            var orderItems = new List<OrderItem>();

            foreach (var item in dto.Items)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId);
                if (product == null)
                {
                    await _unitOfWork.RollbackTransactionAsync();
                    return BadRequest(new ApiResponse<OrderDto>($"Ürün {item.ProductId} bulunamadı", "PRODUCT_NOT_FOUND"));
                }

                totalAmount += product.Price * item.Quantity;
                var customerOrderItemId = await GenerateUniqueCustomerOrderItemIdAsync();
                orderItems.Add(new OrderItem
                {
                    ProductId = item.ProductId,
                    Quantity = item.Quantity,
                    UnitPrice = product.Price,
                    CustomerOrderItemId = customerOrderItemId
                });
            }

            // Create order
            var customerId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous";
            var customerOrderId = await GenerateUniqueCustomerOrderIdAsync();

            var order = new Order
            {
                VendorId = dto.VendorId,
                CustomerId = customerId,
                CustomerOrderId = customerOrderId,
                TotalAmount = totalAmount,
                Status = OrderStatus.Pending,
                OrderItems = orderItems,
                CreatedAt = DateTime.UtcNow,
                DeliveryAddressId = dto.DeliveryAddressId,
            };

            await _unitOfWork.Orders.AddAsync(order);
            await _unitOfWork.SaveChangesAsync();

            // Add vendor notification
            await AddVendorNotificationAsync(
                order.VendorId,
                "Yeni Sipariş",
                $"#Order.{order.CustomerOrderId} numaralı yeni sipariş alındı. Toplam: ₺{totalAmount:N2}",
                "NewOrder",
                order.Id);

            // Add customer notification
            if (customerId != "anonymous")
            {
                await AddCustomerNotificationAsync(
                    customerId,
                    "Sipariş Oluşturuldu",
                    $"#{order.CustomerOrderId} numaralı siparişiniz başarıyla oluşturuldu. Toplam: ₺{totalAmount:N2}",
                    "OrderCreated",
                    order.Id);
            }

            await _unitOfWork.SaveChangesAsync();

            // Transaction commit
            await _unitOfWork.CommitTransactionAsync();

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

            var orderDto = new OrderDto
            {
                Id = order.Id,
                CustomerOrderId = order.CustomerOrderId,
                VendorId = order.VendorId,
                VendorName = vendor.Name,
                TotalAmount = order.TotalAmount,
                Status = order.Status.ToString(),
                CreatedAt = order.CreatedAt
            };

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, new ApiResponse<OrderDto>(orderDto, "Sipariş başarıyla oluşturuldu"));
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            
            // Get inner exception message if available
            var errorMessage = ex.Message;
            var innerException = ex.InnerException;
            while (innerException != null)
            {
                errorMessage += " | Inner: " + innerException.Message;
                innerException = innerException.InnerException;
            }
            
            // Log full exception details
            Console.WriteLine($"Error creating order: {ex}");
            Console.WriteLine($"StackTrace: {ex.StackTrace}");
            
            return StatusCode(500, new ApiResponse<OrderDto>(
                "Sipariş oluşturulurken bir hata oluştu",
                "ORDER_CREATION_FAILED",
                new List<string> { errorMessage }
            ));
        }
    }

    /// <summary>
    /// ID'ye göre sipariş getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayı</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> GetOrder(Guid id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        IQueryable<Order> query = _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product);

        var order = await query.FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

        if (order == null)
        {
            return NotFound(new ApiResponse<OrderDto>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        var orderDto = new OrderDto
        {
            Id = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            VendorId = order.VendorId,
            VendorName = order.Vendor?.Name ?? "",
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt
        };

        return Ok(new ApiResponse<OrderDto>(orderDto, "Sipariş başarıyla getirildi"));
    }

    /// <summary>
    /// Kullanıcının tüm siparişlerini getirir
    /// </summary>
    /// <returns>Sipariş listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<OrderDto>>>> GetOrders()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new ApiResponse<List<OrderDto>>("Yetkilendirme gerekli", "UNAUTHORIZED"));
        }

        IQueryable<Order> query = _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Where(o => o.CustomerId == userId);

        IOrderedQueryable<Order> orderedQuery = query.OrderByDescending(o => o.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        // Not: GetOrders() şu anda pagination parametresi almıyor, bu yüzden tüm sonuçları döndürüyor
        // Eğer pagination eklenirse ToPagedResultAsync kullanılabilir
        var orders = await orderedQuery
            .Select(o => new OrderDto
            {
                Id = o.Id,
                CustomerOrderId = o.CustomerOrderId,
                VendorId = o.VendorId,
                VendorName = o.Vendor != null ? o.Vendor.Name : "",
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<OrderDto>>(orders, "Siparişler başarıyla getirildi"));
    }

    /// <summary>
    /// Sipariş detayını getirir (tüm bilgilerle)
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayı</returns>
    [HttpGet("{id}/detail")]
    public async Task<ActionResult<ApiResponse<OrderDetailDto>>> GetOrderDetail(Guid id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        IQueryable<Order> query = _unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.StatusHistory.OrderByDescending(sh => sh.CreatedAt));

        var order = await query.FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

        if (order == null)
        {
            return NotFound(new ApiResponse<OrderDetailDto>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        var orderDetailDto = new OrderDetailDto
        {
            Id = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            VendorId = order.VendorId,
            VendorName = order.Vendor?.Name ?? "",
            CustomerId = order.CustomerId,
            CustomerName = order.Customer?.FullName ?? "",
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt,
            CancelledAt = order.CancelledAt,
            CancelReason = order.CancelReason,
            Items = order.OrderItems.Select(oi => new OrderItemDetailDto
            {
                ProductId = oi.ProductId,
                CustomerOrderItemId = oi.CustomerOrderItemId,
                ProductName = oi.Product?.Name ?? "",
                ProductImageUrl = oi.Product?.ImageUrl,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TotalPrice = oi.Quantity * oi.UnitPrice,
                IsCancelled = oi.IsCancelled,
                CancelledAt = oi.CancelledAt,
                CancelReason = oi.CancelReason
            }).ToList(),
            StatusHistory = order.StatusHistory.Select(sh => new OrderStatusHistoryDto
            {
                Status = sh.Status.ToString(),
                Note = sh.Note,
                CreatedAt = sh.CreatedAt,
                CreatedBy = sh.CreatedBy
            }).ToList()
        };

        return Ok(new ApiResponse<OrderDetailDto>(orderDetailDto, "Sipariş detayı başarıyla getirildi"));
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
        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order == null)
        {
            return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
        }

        // Parse status
        if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
        {
            return BadRequest(new ApiResponse<object>("Geçersiz durum", "INVALID_STATUS"));
        }

        // Validate status transition
        if (!IsValidStatusTransition(order.Status, newStatus))
        {
            return BadRequest(new ApiResponse<object>(
                $"{order.Status} durumundan {newStatus} durumuna geçiş yapılamaz",
                "INVALID_STATUS_TRANSITION"
            ));
        }

        // Update order status
        order.Status = newStatus;

        // Add to status history
        order.StatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = newStatus,
            Note = dto.Note,
            CreatedBy = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "System"
        });

        _unitOfWork.Orders.Update(order);
        await _unitOfWork.SaveChangesAsync();

        // Add customer notification for status change
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var statusMessage = newStatus switch
            {
                OrderStatus.Preparing => "Siparişiniz hazırlanıyor",
                OrderStatus.Ready => "Siparişiniz hazır, kurye atanıyor",
                OrderStatus.Assigned => "Siparişinize kurye atandı",
                OrderStatus.Accepted => "Kurye siparişi kabul etti",
                OrderStatus.OutForDelivery => "Siparişiniz yola çıktı",
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

        return Ok(new ApiResponse<object>(new { }, "Sipariş durumu başarıyla güncellendi"));
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
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        try
        {
            await _unitOfWork.BeginTransactionAsync();

            var order = await _unitOfWork.Orders.Query()
                .Include(o => o.StatusHistory)
                .FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

            if (order == null)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
            }

            // Check if order can be cancelled
            if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Cancelled)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>("Sipariş iptal edilemez", "ORDER_CANNOT_BE_CANCELLED"));
            }

            // Customers can only cancel Pending or Preparing orders
            var isCustomer = order.CustomerId == userId;
            if (isCustomer && order.Status != OrderStatus.Pending && order.Status != OrderStatus.Preparing)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    "Sipariş sadece Beklemede veya Hazırlanıyor durumundayken iptal edilebilir",
                    "INVALID_CANCELLATION_STATUS"
                ));
            }

            // Validate reason
            if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    "İptal sebebi en az 10 karakter olmalıdır",
                    "INVALID_CANCELLATION_REASON"
                ));
            }

            // Update order
            order.Status = OrderStatus.Cancelled;
            order.CancelledAt = DateTime.UtcNow;
            order.CancelReason = dto.Reason;

            // Add to status history
            order.StatusHistory.Add(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Cancelled,
                Note = $"Cancelled: {dto.Reason}",
                CreatedBy = userId ?? "System"
            });

            _unitOfWork.Orders.Update(order);
            await _unitOfWork.SaveChangesAsync();

            // Add customer notification for cancellation
            if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
            {
                await AddCustomerNotificationAsync(
                    order.CustomerId,
                    "Sipariş İptal Edildi",
                    $"#{order.Id} numaralı siparişiniz iptal edildi. Sebep: {dto.Reason}",
                    "OrderCancelled",
                    order.Id);
            }

            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();

            return Ok(new ApiResponse<object>(new { }, "Sipariş başarıyla iptal edildi"));
        }
        catch (DbUpdateConcurrencyException)
        {
            await _unitOfWork.RollbackTransactionAsync();
            return Conflict(new ApiResponse<object>(
                "Sipariş başka bir kullanıcı tarafından değiştirildi. Lütfen yenileyin ve tekrar deneyin.",
                "CONCURRENCY_CONFLICT"
            ));
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            return StatusCode(500, new ApiResponse<object>(
                "Sipariş iptal edilirken bir hata oluştu",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
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
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new ApiResponse<object>("Yetkilendirme gerekli", "UNAUTHORIZED"));
        }

        try
        {
            await _unitOfWork.BeginTransactionAsync();

            // Find the order item by CustomerOrderItemId
            var orderItem = await _unitOfWork.OrderItems.Query()
                .Include(oi => oi.Order!)
                    .ThenInclude(o => o.StatusHistory)
                .FirstOrDefaultAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);

            if (orderItem == null)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return NotFound(new ApiResponse<object>("Sipariş ürünü bulunamadı", "ORDER_ITEM_NOT_FOUND"));
            }

            // Check if order exists and belongs to user
            if (orderItem.Order == null)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return NotFound(new ApiResponse<object>("Sipariş bulunamadı", "ORDER_NOT_FOUND"));
            }

            if (orderItem.Order.CustomerId != userId)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return Forbid(new ApiResponse<object>("Bu sipariş ürününü iptal etme yetkiniz yok", "FORBIDDEN").ToString() ?? "");
            }

            // Check if already cancelled
            if (orderItem.IsCancelled)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>("Sipariş ürünü zaten iptal edilmiş", "ALREADY_CANCELLED"));
            }

            // Check if order can have items cancelled (only Pending or Preparing)
            if (orderItem.Order.Status != OrderStatus.Pending && orderItem.Order.Status != OrderStatus.Preparing)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    "Sipariş ürünleri sadece Beklemede veya Hazırlanıyor durumundayken iptal edilebilir",
                    "INVALID_CANCELLATION_STATUS"
                ));
            }

            // Validate reason
            if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
            {
                await _unitOfWork.RollbackTransactionAsync();
                return BadRequest(new ApiResponse<object>(
                    "İptal sebebi en az 10 karakter olmalıdır",
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
            var remainingItemsCount = await _unitOfWork.OrderItems.Query()
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

            _unitOfWork.OrderItems.Update(orderItem);
            _unitOfWork.Orders.Update(orderItem.Order);
            await _unitOfWork.SaveChangesAsync();

            // Add customer notification
            if (!string.IsNullOrEmpty(orderItem.Order.CustomerId) && orderItem.Order.CustomerId != "anonymous")
            {
                await AddCustomerNotificationAsync(
                    orderItem.Order.CustomerId,
                    "Sipariş Ürünü İptal Edildi",
                    $"#{customerOrderItemId} numaralı ürün siparişinizden iptal edildi. Sebep: {dto.Reason}",
                    "OrderItemCancelled",
                    orderItem.Order.Id);
            }

            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();

            return Ok(new ApiResponse<object>(new { }, "Sipariş ürünü başarıyla iptal edildi"));
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            return StatusCode(500, new ApiResponse<object>(
                "Sipariş ürünü iptal edilirken bir hata oluştu",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Satıcı bildirimi ekler
    /// </summary>
    private async Task AddVendorNotificationAsync(Guid vendorId, string title, string message, string type, Guid? relatedEntityId = null)
    {
        await _unitOfWork.VendorNotifications.AddAsync(new VendorNotification
        {
            VendorId = vendorId,
            Title = title,
            Message = message,
            Type = type,
            RelatedEntityId = relatedEntityId
        });
    }

    /// <summary>
    /// Müşteri bildirimi ekler
    /// </summary>
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

    private bool IsValidStatusTransition(OrderStatus current, OrderStatus next)
    {
        return current switch
        {
            OrderStatus.Pending => next is OrderStatus.Preparing or OrderStatus.Cancelled,
            OrderStatus.Preparing => next is OrderStatus.Ready or OrderStatus.Cancelled,
            OrderStatus.Ready => next is OrderStatus.Assigned or OrderStatus.Cancelled,
            OrderStatus.Assigned => next is OrderStatus.Accepted or OrderStatus.Cancelled,
            OrderStatus.Accepted => next is OrderStatus.OutForDelivery or OrderStatus.Cancelled,
            OrderStatus.OutForDelivery => next is OrderStatus.Delivered,
            OrderStatus.Delivered => false,
            OrderStatus.Cancelled => false,
            _ => false
        };
    }
}

using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class OrdersController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly Talabi.Core.Interfaces.IOrderAssignmentService _assignmentService;

    public OrdersController(TalabiDbContext context, Talabi.Core.Interfaces.IOrderAssignmentService assignmentService)
    {
        _context = context;
        _assignmentService = assignmentService;
    }

    private async Task<string> GenerateUniqueCustomerOrderIdAsync()
    {
        var random = new Random();
        string customerOrderId;
        bool isUnique;

        do
        {
            customerOrderId = random.Next(100000, 999999).ToString();
            isUnique = !await _context.Orders.AnyAsync(o => o.CustomerOrderId == customerOrderId);
        } while (!isUnique);

        return customerOrderId;
    }

    private async Task<string> GenerateUniqueCustomerOrderItemIdAsync()
    {
        var random = new Random();
        string customerOrderItemId;
        bool isUnique;

        do
        {
            customerOrderItemId = random.Next(100000, 999999).ToString();
            isUnique = !await _context.OrderItems.AnyAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);
        } while (!isUnique);

        return customerOrderItemId;
    }

    [HttpPost]
    public async Task<ActionResult<OrderDto>> CreateOrder(CreateOrderDto dto)
    {
        // Validate vendor exists
        var vendor = await _context.Vendors.FindAsync(dto.VendorId);
        if (vendor == null)
        {
            return BadRequest("Vendor not found");
        }

        // Calculate total and create order items
        decimal totalAmount = 0;
        var orderItems = new List<OrderItem>();

        foreach (var item in dto.Items)
        {
            var product = await _context.Products.FindAsync(item.ProductId);
            if (product == null)
            {
                return BadRequest($"Product {item.ProductId} not found");
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

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // Add vendor notification
        await AddVendorNotificationAsync(
            order.VendorId,
            "Yeni Sipariş",
            $"#{order.Id} numaralı yeni sipariş alındı. Toplam: {totalAmount:C}",
            "NewOrder",
            order.Id);

        // Add customer notification
        if (customerId != "anonymous")
        {
            await AddCustomerNotificationAsync(
                customerId,
                "Sipariş Oluşturuldu",
                $"#{order.Id} numaralı siparişiniz başarıyla oluşturuldu. Toplam: {totalAmount:C}",
                "OrderCreated",
                order.Id);
        }

        await _context.SaveChangesAsync();

        // Automatic Courier Assignment
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

        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, new OrderDto
        {
            Id = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            VendorId = order.VendorId,
            VendorName = vendor.Name,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(Guid id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        var order = await _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

        if (order == null)
        {
            return NotFound();
        }

        return new OrderDto
        {
            Id = order.Id,
            CustomerOrderId = order.CustomerOrderId,
            VendorId = order.VendorId,
            VendorName = order.Vendor?.Name ?? "",
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt
        };
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrders()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var orders = await _context.Orders
            .Include(o => o.Vendor)
            .Where(o => o.CustomerId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OrderDto
            {
                Id = o.Id,
                CustomerOrderId = o.CustomerOrderId,
                VendorId = o.VendorId,
                VendorName = o.Vendor!.Name,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAt = o.CreatedAt
            })
            .ToListAsync();

        return Ok(orders);
    }

    [HttpGet("{id}/detail")]
    public async Task<ActionResult<OrderDetailDto>> GetOrderDetail(Guid id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        var order = await _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.StatusHistory.OrderByDescending(sh => sh.CreatedAt))
            .FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

        if (order == null)
        {
            return NotFound();
        }

        return Ok(new OrderDetailDto
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
        });
    }

    [HttpPut("{id}/status")]
    public async Task<ActionResult> UpdateOrderStatus(Guid id, UpdateOrderStatusDto dto)
    {
        var order = await _context.Orders
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order == null)
        {
            return NotFound();
        }

        // Parse status
        if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
        {
            return BadRequest("Invalid status");
        }

        // Validate status transition
        if (!IsValidStatusTransition(order.Status, newStatus))
        {
            return BadRequest($"Cannot transition from {order.Status} to {newStatus}");
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

        await _context.SaveChangesAsync();

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

        return Ok(new { Message = "Order status updated" });
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult> CancelOrder(Guid id, CancelOrderDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        var order = await _context.Orders
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id && (userId == null || o.CustomerId == userId));

        if (order == null)
        {
            return NotFound();
        }

        // Check if order can be cancelled
        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Cancelled)
        {
            return BadRequest("Order cannot be cancelled");
        }

        // Customers can only cancel Pending or Preparing orders
        var isCustomer = order.CustomerId == userId;
        if (isCustomer && order.Status != OrderStatus.Pending && order.Status != OrderStatus.Preparing)
        {
            return BadRequest("Order can only be cancelled in Pending or Preparing status");
        }

        // Validate reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
        {
            return BadRequest("Cancellation reason must be at least 10 characters");
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

        await _context.SaveChangesAsync();

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

        return Ok(new { Message = "Order cancelled successfully" });
    }

    [HttpPost("items/{customerOrderItemId}/cancel")]
    public async Task<ActionResult> CancelOrderItem(string customerOrderItemId, CancelOrderDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        // Find the order item by CustomerOrderItemId
        var orderItem = await _context.OrderItems
            .Include(oi => oi.Order!)
                .ThenInclude(o => o.StatusHistory)
            .FirstOrDefaultAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);

        if (orderItem == null)
        {
            return NotFound("Order item not found");
        }

        // Check if order exists and belongs to user
        if (orderItem.Order == null)
        {
            return NotFound("Order not found");
        }

        if (orderItem.Order.CustomerId != userId)
        {
            return Forbid("You don't have permission to cancel this order item");
        }

        // Check if already cancelled
        if (orderItem.IsCancelled)
        {
            return BadRequest("Order item is already cancelled");
        }

        // Check if order can have items cancelled (only Pending or Preparing)
        if (orderItem.Order.Status != OrderStatus.Pending && orderItem.Order.Status != OrderStatus.Preparing)
        {
            return BadRequest("Order items can only be cancelled when order status is Pending or Preparing");
        }

        // Validate reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
        {
            return BadRequest("Cancellation reason must be at least 10 characters");
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
        var remainingItemsCount = await _context.OrderItems
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

        await _context.SaveChangesAsync();

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

        return Ok(new { Message = "Order item cancelled successfully" });
    }

    private async Task AddVendorNotificationAsync(Guid vendorId, string title, string message, string type, Guid? relatedEntityId = null)
    {
        _context.VendorNotifications.Add(new VendorNotification
        {
            VendorId = vendorId,
            Title = title,
            Message = message,
            Type = type,
            RelatedEntityId = relatedEntityId
        });
    }

    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type, Guid? orderId = null)
    {
        var customer = await _context.Customers.FirstOrDefaultAsync(c => c.UserId == userId);
        if (customer == null)
        {
            // Create customer if doesn't exist
            customer = new Customer
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            _context.Customers.Add(customer);
            await _context.SaveChangesAsync();
        }

        _context.CustomerNotifications.Add(new CustomerNotification
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

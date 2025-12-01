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
            orderItems.Add(new OrderItem
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                UnitPrice = product.Price
            });
        }

        // Create order
        var customerId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous";

        var order = new Order
        {
            VendorId = dto.VendorId,
            CustomerId = customerId,
            TotalAmount = totalAmount,
            Status = OrderStatus.Pending,
            OrderItems = orderItems,
            CreatedAt = DateTime.UtcNow
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
            VendorId = order.VendorId,
            VendorName = vendor.Name,
            TotalAmount = order.TotalAmount,
            Status = order.Status.ToString(),
            CreatedAt = order.CreatedAt
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(int id)
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
    public async Task<ActionResult<OrderDetailDto>> GetOrderDetail(int id)
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
                ProductName = oi.Product?.Name ?? "",
                ProductImageUrl = oi.Product?.ImageUrl,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TotalPrice = oi.Quantity * oi.UnitPrice
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
    public async Task<ActionResult> UpdateOrderStatus(int id, UpdateOrderStatusDto dto)
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
    public async Task<ActionResult> CancelOrder(int id, CancelOrderDto dto)
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

    private async Task AddVendorNotificationAsync(int vendorId, string title, string message, string type, int? relatedEntityId = null)
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

    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type, int? orderId = null)
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

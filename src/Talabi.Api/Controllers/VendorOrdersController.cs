using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/orders")]
[ApiController]
[Authorize]
public class VendorOrdersController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public VendorOrdersController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value 
        ?? throw new UnauthorizedAccessException();

    private async Task<int?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<VendorOrderDto>>> GetVendorOrders(
        [FromQuery] string? status = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var query = _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Where(o => o.VendorId == vendorId);

        // Filter by status
        if (!string.IsNullOrEmpty(status) && Enum.TryParse<OrderStatus>(status, out var statusEnum))
        {
            query = query.Where(o => o.Status == statusEnum);
        }

        // Filter by date range
        if (startDate.HasValue)
        {
            query = query.Where(o => o.CreatedAt >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            query = query.Where(o => o.CreatedAt <= endDate.Value);
        }

        var orders = await query
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new VendorOrderDto
            {
                Id = o.Id,
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
            })
            .ToListAsync();

        return Ok(orders);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<VendorOrderDto>> GetVendorOrder(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound();
        }

        return Ok(new VendorOrderDto
        {
            Id = order.Id,
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
            }).ToList()
        });
    }

    [HttpPost("{id}/accept")]
    public async Task<ActionResult> AcceptOrder(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound();
        }

        if (order.Status != OrderStatus.Pending)
        {
            return BadRequest("Order can only be accepted when status is Pending");
        }

        order.Status = OrderStatus.Preparing;
        order.StatusHistory.Add(new Talabi.Core.Entities.OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Preparing,
            Note = "Order accepted by vendor",
            CreatedBy = GetUserId()
        });

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Order accepted successfully" });
    }

    [HttpPost("{id}/reject")]
    public async Task<ActionResult> RejectOrder(int id, [FromBody] RejectOrderDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound();
        }

        if (order.Status != OrderStatus.Pending)
        {
            return BadRequest("Order can only be rejected when status is Pending");
        }

        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
        {
            return BadRequest("Rejection reason must be at least 10 characters");
        }

        order.Status = OrderStatus.Cancelled;
        order.CancelledAt = DateTime.UtcNow;
        order.CancelReason = $"Rejected by vendor: {dto.Reason}";
        order.StatusHistory.Add(new Talabi.Core.Entities.OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Cancelled,
            Note = $"Rejected by vendor: {dto.Reason}",
            CreatedBy = GetUserId()
        });

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Order rejected successfully" });
    }

    [HttpPut("{id}/status")]
    public async Task<ActionResult> UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound();
        }

        if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
        {
            return BadRequest("Invalid status");
        }

        // Validate status transition for vendor
        if (!IsValidVendorStatusTransition(order.Status, newStatus))
        {
            return BadRequest($"Cannot transition from {order.Status} to {newStatus}");
        }

        order.Status = newStatus;
        order.StatusHistory.Add(new Talabi.Core.Entities.OrderStatusHistory
        {
            OrderId = order.Id,
            Status = newStatus,
            Note = dto.Note ?? $"Status updated to {newStatus}",
            CreatedBy = GetUserId()
        });

        // Set estimated delivery time if status is Ready
        if (newStatus == OrderStatus.Ready && !order.EstimatedDeliveryTime.HasValue)
        {
            order.EstimatedDeliveryTime = DateTime.UtcNow.AddMinutes(30); // Default 30 minutes
        }

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Order status updated successfully" });
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
}

public class RejectOrderDto
{
    public string Reason { get; set; } = string.Empty;
}


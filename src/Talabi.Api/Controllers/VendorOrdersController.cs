using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/orders")]
[ApiController]
[Authorize]
public class VendorOrdersController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly IOrderAssignmentService _assignmentService;

    public VendorOrdersController(TalabiDbContext context, IOrderAssignmentService assignmentService)
    {
        _context = context;
        _assignmentService = assignmentService;
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

    // Get available couriers for manual assignment
    [HttpGet("{id}/available-couriers")]
    public async Task<ActionResult<IEnumerable<AvailableCourierDto>>> GetAvailableCouriers(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound("Order not found");
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest("Order must be in Ready status to assign courier");
        }

        // Get vendor location
        var vendor = order.Vendor;
        if (vendor == null || !vendor.Latitude.HasValue || !vendor.Longitude.HasValue)
        {
            return BadRequest("Vendor location not set");
        }

        // Get available couriers (first get all, then calculate distance in memory)
        var availableCouriersQuery = await _context.Couriers
            .Where(c => c.IsActive
                && c.Status == Talabi.Core.Enums.CourierStatus.Available
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
                PhoneNumber = x.Courier.PhoneNumber,
                VehicleType = x.Courier.VehicleType ?? "Unknown",
                AverageRating = x.Courier.AverageRating,
                TotalDeliveries = x.Courier.TotalDeliveries,
                CurrentActiveOrders = x.Courier.CurrentActiveOrders,
                MaxActiveOrders = x.Courier.MaxActiveOrders,
                Distance = Math.Round(x.Distance, 2),
                EstimatedArrivalMinutes = (int)Math.Ceiling(x.Distance * 3) // Rough estimate: 3 min per km
            })
            .ToList();

        return Ok(availableCouriers);
    }

    // Manually assign courier to order
    [HttpPost("{id}/assign-courier")]
    public async Task<ActionResult> AssignCourier(int id, [FromBody] AssignCourierDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound("Order not found");
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest("Order must be in Ready status to assign courier");
        }

        if (order.CourierId.HasValue)
        {
            return BadRequest("Order already has a courier assigned");
        }

        // Assign courier using the service
        var success = await _assignmentService.AssignOrderToCourierAsync(id, dto.CourierId);

        if (!success)
        {
            return BadRequest("Failed to assign courier. Courier may not be available or order status is invalid.");
        }

        return Ok(new { Message = "Courier assigned successfully" });
    }

    // Auto-assign best courier
    [HttpPost("{id}/auto-assign-courier")]
    public async Task<ActionResult> AutoAssignCourier(int id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return Forbid("User is not a vendor");
        }

        var order = await _context.Orders
            .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId);

        if (order == null)
        {
            return NotFound("Order not found");
        }

        if (order.Status != OrderStatus.Ready)
        {
            return BadRequest("Order must be in Ready status to assign courier");
        }

        if (order.CourierId.HasValue)
        {
            return BadRequest("Order already has a courier assigned");
        }

        // Find best courier
        var bestCourier = await _assignmentService.FindBestCourierAsync(order);

        if (bestCourier == null)
        {
            return BadRequest("No available couriers found nearby");
        }

        // Assign courier
        var success = await _assignmentService.AssignOrderToCourierAsync(id, bestCourier.Id);

        if (!success)
        {
            return BadRequest("Failed to assign courier");
        }

        return Ok(new
        {
            Message = "Courier auto-assigned successfully",
            CourierId = bestCourier.Id,
            CourierName = bestCourier.Name
        });
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
}

public class RejectOrderDto
{
    public string Reason { get; set; } = string.Empty;
}

public class AssignCourierDto
{
    public int CourierId { get; set; }
}

public class AvailableCourierDto
{
    public int Id { get; set; }
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


using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class OrderService(
    IUnitOfWork unitOfWork,
    IUserContextService userContextService,
    ILogger<OrderService> logger) : IOrderService
{
    private readonly IUnitOfWork _unitOfWork = unitOfWork;
    private readonly IUserContextService _userContextService = userContextService;
    private readonly ILogger<OrderService> _logger = logger;

    private async Task<Guid?> GetVendorIdAsync(CancellationToken ct)
    {
        var userId = _userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return null;

        var vendor = await _unitOfWork.Vendors.Query()
            .Select(v => new { v.Id, v.OwnerId })
            .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

        return vendor?.Id;
    }

    public async Task<PagedResultDto<VendorOrderDto>?> GetOrdersAsync(int page = 1, int pageSize = 10, OrderStatus? status = null,
        string? search = null, string? sortBy = null, string sortOrder = "desc",
        DateTime? startDate = null, DateTime? endDate = null, decimal? minAmount = null, decimal? maxAmount = null,
        CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;

            var query = _unitOfWork.Orders.Query()
                .Include(o => o.Customer)
                .Where(o => o.VendorId == vendorId.Value);

            if (status.HasValue)
                query = query.Where(o => o.Status == status.Value);

            if (startDate.HasValue)
                query = query.Where(o => o.CreatedAt >= startDate.Value.ToUniversalTime());

            if (endDate.HasValue)
                query = query.Where(o => o.CreatedAt <= endDate.Value.ToUniversalTime()); // Should handle end of day logic in Controller or here if passing just date

            if (minAmount.HasValue)
                query = query.Where(o => o.TotalAmount >= minAmount.Value);

            if (maxAmount.HasValue)
                query = query.Where(o => o.TotalAmount <= maxAmount.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                // Search by Order ID or Customer Name
                query = query.Where(o => o.CustomerOrderId.ToLower().Contains(searchLower) ||
                                         (o.Customer != null && (o.Customer.FullName).ToLower().Contains(searchLower)));
            }

            IOrderedQueryable<Order> orderedQuery;

            if (string.IsNullOrEmpty(sortBy))
            {
                orderedQuery = query.OrderByDescending(o => o.CreatedAt);
            }
            else
            {
                var isAsc = sortOrder.Equals("asc", StringComparison.OrdinalIgnoreCase);
                orderedQuery = sortBy.ToLower() switch
                {
                    "id" => isAsc ? query.OrderBy(o => o.CustomerOrderId) : query.OrderByDescending(o => o.CustomerOrderId),
                    "totalamount" => isAsc ? query.OrderBy(o => o.TotalAmount) : query.OrderByDescending(o => o.TotalAmount),
                    "status" => isAsc ? query.OrderBy(o => o.Status) : query.OrderByDescending(o => o.Status),
                    "date" => isAsc ? query.OrderBy(o => o.CreatedAt) : query.OrderByDescending(o => o.CreatedAt),
                    "customername" => isAsc ? query.OrderBy(o => o.Customer != null ? o.Customer.FullName : "") : query.OrderByDescending(o => o.Customer != null ? o.Customer.FullName : ""),
                    _ => query.OrderByDescending(o => o.CreatedAt)
                };
            }

            var totalCount = await query.LongCountAsync(ct);
            var items = await orderedQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(o => new VendorOrderDto
                {
                    Id = o.Id,
                    CustomerOrderId = o.CustomerOrderId,
                    CustomerName = o.Customer != null ? (o.Customer.FullName) : "Unknown",
                    TotalAmount = o.TotalAmount,
                    Status = o.Status,
                    CreatedAt = o.CreatedAt,
                    ItemCount = o.OrderItems.Count
                })
                .ToListAsync(ct);

            return new PagedResultDto<VendorOrderDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting orders");
            return null;
        }
    }

    public async Task<VendorOrderDetailDto?> GetOrderAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            var order = await _unitOfWork.Orders.Query()
                .Include(o => o.Customer)
                .Include(o => o.DeliveryAddress)
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .Include(o => o.StatusHistory)
                .Include(o => o.OrderCouriers)
                .ThenInclude(oc => oc.Courier)
                .ThenInclude(c => c!.User)
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return null;

            // Get active courier if any
            var activeCourier = order.OrderCouriers.FirstOrDefault(oc => oc.IsActive);

            return new VendorOrderDetailDto
            {
                Id = order.Id,
                CustomerOrderId = order.CustomerOrderId,
                CustomerName = order.Customer != null ? (order.Customer.FullName) : "Unknown",
                CustomerPhone = order.Customer?.PhoneNumber,
                TotalAmount = order.TotalAmount,
                DeliveryFee = order.DeliveryFee,
                Status = order.Status,
                CancelReason = order.CancelReason,
                CreatedAt = order.CreatedAt,
                ItemCount = order.OrderItems.Count,
                DeliveryAddress = order.DeliveryAddress != null ? $"{order.DeliveryAddress.FullAddress} {(order.DeliveryAddress.City != null ? order.DeliveryAddress.City.NameTr : "")}" : null,
                Items = [.. order.OrderItems.Select(oi => new VendorOrderItemDto
                {
                    ProductName = oi.Product?.Name ?? "Unknown Product",
                    Quantity = oi.Quantity,
                    UnitPrice = oi.UnitPrice
                })],
                StatusHistory = [.. order.StatusHistory.OrderByDescending(h => h.CreatedAt).Select(h => new OrderStatusHistoryDto
                {
                    Status = h.Status,
                    CreatedAt = h.CreatedAt,
                    Note = h.Note
                })],
                CourierName = activeCourier?.Courier?.User?.FullName,
                CourierPhone = activeCourier?.Courier?.User?.PhoneNumber,
                CourierStatus = activeCourier != null ? "Assigned" : null // Simplified logic
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting order details {OrderId}", id);
            return null;
        }
    }

    public async Task<bool> UpdateOrderStatusAsync(Guid id, OrderStatus status, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var order = await _unitOfWork.Orders.Query()
                .Include(o => o.StatusHistory)
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return false;

            // Don't update if already in that status
            if (order.Status == status) return true;

            order.Status = status;
            order.UpdatedAt = DateTime.UtcNow;

            order.StatusHistory.Add(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = status,
                CreatedAt = DateTime.UtcNow
            });

            _unitOfWork.Orders.Update(order);
            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order status {OrderId}", id);
            return false;
        }
    }

    public async Task<bool> RejectOrderAsync(Guid id, string reason, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var order = await _unitOfWork.Orders.Query()
                .Include(o => o.StatusHistory)
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return false;

            order.Status = OrderStatus.Cancelled;
            order.CancelReason = reason;
            order.UpdatedAt = DateTime.UtcNow;

            order.StatusHistory.Add(new OrderStatusHistory
            {
                OrderId = order.Id,
                Status = OrderStatus.Cancelled,
                Note = reason,
                CreatedAt = DateTime.UtcNow
            });

            _unitOfWork.Orders.Update(order);
            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error rejecting order {OrderId}", id);
            return false;
        }
    }

    public async Task<bool> AssignCourierAsync(Guid id, Guid courierId, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var order = await _unitOfWork.Orders.Query()
                .Include(o => o.StatusHistory)
                .Include(o => o.OrderCouriers)
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return false;

            // Deactivate existing couriers
            foreach (var oc in order.OrderCouriers)
            {
                oc.IsActive = false;
                oc.UpdatedAt = DateTime.UtcNow;
            }

            // Assign new courier
            order.OrderCouriers.Add(new OrderCourier
            {
                OrderId = order.Id,
                CourierId = courierId,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                CourierAssignedAt = DateTime.UtcNow
            });

            // Update order status if needed (e.g. from Ready to Assigned)
            if (order.Status == OrderStatus.Ready)
            {
                order.Status = OrderStatus.Assigned;
                order.StatusHistory.Add(new OrderStatusHistory
                {
                    OrderId = order.Id,
                    Status = OrderStatus.Assigned,
                    CreatedAt = DateTime.UtcNow
                });
            }

            order.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Orders.Update(order);
            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error assigning courier to order {OrderId}", id);
            return false;
        }
    }

    public async Task<List<AvailableCourierDto>> GetAvailableCouriersAsync(Guid orderId, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return [];

            var order = await _unitOfWork.Orders.Query()
               .Include(o => o.Vendor)
               .FirstOrDefaultAsync(o => o.Id == orderId && o.VendorId == vendorId.Value, ct);

            if (order == null || order.Status != OrderStatus.Ready) return [];

            var vendor = order.Vendor;
            if (vendor == null || !vendor.Latitude.HasValue || !vendor.Longitude.HasValue) return [];

            var availableCouriersQuery = await _unitOfWork.Couriers.Query()
                .Where(c => c.IsActive
                    && c.Status == CourierStatus.Available
                    && c.CurrentActiveOrders < c.MaxActiveOrders
                    && c.CurrentLatitude.HasValue
                    && c.CurrentLongitude.HasValue)
                .ToListAsync(ct);

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
                .Where(x => x.Distance <= 10) // Max 10km radius
                .OrderBy(x => x.Distance)
                .Select(x => new AvailableCourierDto
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
                    EstimatedArrivalMinutes = (int)Math.Ceiling(x.Distance * 3)
                })
                .ToList();

            return availableCouriers;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting available couriers for order {OrderId}", orderId);
            return [];
        }
    }
}

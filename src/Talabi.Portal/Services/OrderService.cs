using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<OrderService> _logger;

    public OrderService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<OrderService> logger)
    {
        _unitOfWork = unitOfWork;
        _userContextService = userContextService;
        _logger = logger;
    }

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
        string? search = null, string? sortBy = null, string sortOrder = "desc", CancellationToken ct = default)
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
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return null;

            return new VendorOrderDetailDto
            {
                Id = order.Id,
                CustomerOrderId = order.CustomerOrderId,
                CustomerName = order.Customer != null ? (order.Customer.FullName) : "Unknown",
                CustomerPhone = order.Customer?.PhoneNumber,
                TotalAmount = order.TotalAmount,
                Status = order.Status,
                CreatedAt = order.CreatedAt,
                ItemCount = order.OrderItems.Count,
                DeliveryAddress = order.DeliveryAddress != null ? $"{order.DeliveryAddress.FullAddress} {order.DeliveryAddress.City}" : null,
                Items = order.OrderItems.Select(oi => new VendorOrderItemDto
                {
                    ProductName = oi.Product?.Name ?? "Unknown Product",
                    Quantity = oi.Quantity,
                    UnitPrice = oi.UnitPrice
                }).ToList()
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
                .FirstOrDefaultAsync(o => o.Id == id && o.VendorId == vendorId.Value, ct);

            if (order == null) return false;

            order.Status = status;
            order.UpdatedAt = DateTime.UtcNow;

            // Optional: Log status history
            // _unitOfWork.OrderStatusHistories.Add(...)

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
}

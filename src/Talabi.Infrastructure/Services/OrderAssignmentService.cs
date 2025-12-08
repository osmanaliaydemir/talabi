using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class OrderAssignmentService : IOrderAssignmentService
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<OrderAssignmentService> _logger;
    private readonly INotificationService _notificationService;

    public OrderAssignmentService(TalabiDbContext context, ILogger<OrderAssignmentService> logger, INotificationService notificationService)
    {
        _context = context;
        _logger = logger;
        _notificationService = notificationService;
    }

    // ...

    public async Task<bool> AssignOrderToCourierAsync(Guid orderId, Guid courierId)
    {
        var order = await _context.Orders
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await _context.Couriers.FindAsync(courierId);

        if (order == null || courier == null) return false;
        if (order.Status != OrderStatus.Ready) return false;
        
        // Check if order already has an active assignment
        var activeAssignment = await GetActiveOrderCourierAsync(orderId);
        if (activeAssignment != null) return false;
        
        if (!courier.IsActive || courier.Status != CourierStatus.Available) return false;
        if (courier.CurrentActiveOrders >= courier.MaxActiveOrders) return false;

        // Deactivate any previous assignments (if any)
        await DeactivatePreviousAssignmentsAsync(orderId);

        // Calculate delivery fee
        decimal deliveryFee = await CalculateDeliveryFee(order, courier);

        // Create new OrderCourier assignment
        var orderCourier = new OrderCourier
        {
            OrderId = orderId,
            CourierId = courierId,
            CourierAssignedAt = DateTime.UtcNow,
            Status = OrderCourierStatus.Assigned,
            IsActive = true,
            DeliveryFee = deliveryFee
        };

        _context.OrderCouriers.Add(orderCourier);

        // Update order status
        order.Status = OrderStatus.Assigned;

        // Update courier
        courier.Status = CourierStatus.Assigned;

        AddCourierNotification(
            courier.Id,
            "Yeni sipariş atandı",
            $"#{order.CustomerOrderId} numaralı sipariş sana atandı. İnceleyip hızlıca aksiyon al.",
            "order_assigned",
            order.Id);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order {OrderId} assigned to courier {CourierId}", orderId, courierId);

        // Send notification
        if (!string.IsNullOrEmpty(courier.UserId))
        {
            await _notificationService.SendOrderAssignmentNotificationAsync(courier.UserId, orderId);
        }

        return true;
    }

    public async Task<Courier?> FindBestCourierAsync(Order order)
    {
        // 1. Get available couriers
        var availableCouriers = await _context.Couriers
            .Where(c => c.IsActive
                && c.Status == CourierStatus.Available
                && c.CurrentActiveOrders < c.MaxActiveOrders
                && c.CurrentLatitude.HasValue
                && c.CurrentLongitude.HasValue)
            .ToListAsync();

        if (!availableCouriers.Any())
        {
            _logger.LogWarning("No available couriers found for order {OrderId}", order.Id);
            return null;
        }

        // 2. Get vendor location
        var vendor = await _context.Vendors.FindAsync(order.VendorId);
        if (vendor == null)
        {
            _logger.LogError("Vendor not found for order {OrderId}", order.Id);
            return null;
        }

        // 3. Calculate distances and find the best one
        // Simple logic: Closest courier within 10km
        var bestCourier = availableCouriers
            .Select(c => new
            {
                Courier = c,
                Distance = CalculateDistance(
                    vendor.Latitude ?? 0,
                    vendor.Longitude ?? 0,
                    c.CurrentLatitude!.Value,
                    c.CurrentLongitude!.Value
                )
            })
            .Where(x => x.Distance <= 10) // Max 10km radius
            .OrderBy(x => x.Distance)
            .ThenByDescending(x => x.Courier.AverageRating) // Secondary sort by rating
            .FirstOrDefault();

        return bestCourier?.Courier;
    }


    public async Task<bool> AcceptOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await _context.Orders.FindAsync(orderId);
        var courier = await _context.Couriers.FindAsync(courierId);

        if (order == null || courier == null) return false;
        
        var orderCourier = await GetActiveOrderCourierAsync(orderId);
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;
        if (order.Status != OrderStatus.Assigned) return false;
        if (orderCourier.Status != OrderCourierStatus.Assigned) return false;
        if (courier.CurrentActiveOrders >= courier.MaxActiveOrders) return false;

        // Update OrderCourier
        orderCourier.CourierAcceptedAt = DateTime.UtcNow;
        orderCourier.Status = OrderCourierStatus.Accepted;
        orderCourier.UpdatedAt = DateTime.UtcNow;

        // Update order status
        order.Status = OrderStatus.Accepted;

        // Update courier
        courier.CurrentActiveOrders++;
        courier.Status = CourierStatus.Busy;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order {OrderId} accepted by courier {CourierId}", orderId, courierId);
        return true;
    }

    public async Task<bool> RejectOrderAsync(Guid orderId, Guid courierId, string reason)
    {
        var order = await _context.Orders
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await _context.Couriers.FindAsync(courierId);

        if (order == null || courier == null) return false;

        var orderCourier = await GetActiveOrderCourierAsync(orderId);
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;
        if (order.Status != OrderStatus.Assigned) return false;
        if (orderCourier.Status != OrderCourierStatus.Assigned) return false;

        if (string.IsNullOrWhiteSpace(reason))
        {
            return false;
        }

        // Update OrderCourier - mark as rejected
        orderCourier.CourierRejectedAt = DateTime.UtcNow;
        orderCourier.RejectReason = reason.Trim();
        orderCourier.Status = OrderCourierStatus.Rejected;
        orderCourier.IsActive = false;
        orderCourier.UpdatedAt = DateTime.UtcNow;

        // Reset order status to Ready
        order.Status = OrderStatus.Ready;
        order.CancelReason = null; // Clear cancel reason since order is still active

        // Update courier
        courier.Status = courier.CurrentActiveOrders > 0 ? CourierStatus.Busy : CourierStatus.Available;

        // Add vendor notification
        if (order.VendorId != Guid.Empty)
        {
            await AddVendorNotificationAsync(
                order.VendorId,
                order.CustomerOrderId,
                courier.Name,
                reason.Trim()
            );
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order {OrderId} rejected by courier {CourierId}. Reason: {Reason}", orderId, courierId, reason);

        return true;
    }

    public async Task<bool> PickUpOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await _context.Orders.FindAsync(orderId);
        var courier = await _context.Couriers.FindAsync(courierId);

        if (order == null || courier == null) return false;

        var orderCourier = await GetActiveOrderCourierAsync(orderId);
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;
        if (order.Status != OrderStatus.Accepted) return false;
        if (orderCourier.Status != OrderCourierStatus.Accepted) return false;

        // Update OrderCourier - mark as picked up and out for delivery
        orderCourier.PickedUpAt = DateTime.UtcNow;
        orderCourier.OutForDeliveryAt = DateTime.UtcNow;
        orderCourier.Status = OrderCourierStatus.OutForDelivery;
        orderCourier.UpdatedAt = DateTime.UtcNow;

        // Update order status
        order.Status = OrderStatus.OutForDelivery;

        // Update courier
        courier.Status = CourierStatus.Busy;

        AddCourierNotification(
            courier.Id,
            "Sipariş teslimata çıktı",
            $"#{order.CustomerOrderId} numaralı sipariş müşteriye teslim edilmek üzere yola çıktı.",
            "order_progress",
            order.Id);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order {OrderId} picked up by courier {CourierId}", orderId, courierId);

        // Notify customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "OutForDelivery");
            await AddCustomerNotificationAsync(
                order.CustomerId,
                "Sipariş Yola Çıktı",
                $"#{order.Id} numaralı siparişiniz teslim edilmek üzere yola çıktı.",
                "OrderOutForDelivery",
                order.Id);
        }

        return true;
    }

    public async Task<bool> DeliverOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await _context.Orders
            .Include(o => o.DeliveryAddress)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await _context.Couriers.FindAsync(courierId);

        if (order == null || courier == null) return false;

        var orderCourier = await GetActiveOrderCourierAsync(orderId);
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;
        if (order.Status != OrderStatus.OutForDelivery) return false;
        if (orderCourier.Status != OrderCourierStatus.OutForDelivery) return false;

        // Update OrderCourier
        orderCourier.DeliveredAt = DateTime.UtcNow;
        orderCourier.Status = OrderCourierStatus.Delivered;
        orderCourier.UpdatedAt = DateTime.UtcNow;

        // Update order status
        order.Status = OrderStatus.Delivered;

        // Update courier
        courier.CurrentActiveOrders = Math.Max(0, courier.CurrentActiveOrders - 1);
        courier.Status = courier.CurrentActiveOrders == 0 ? CourierStatus.Available : CourierStatus.Busy;
        courier.TotalDeliveries++;

        // Create detailed earning record (use OrderCourier data)
        await CreateCourierEarningAsync(order, courier, orderCourier);

        AddCourierNotification(
            courier.Id,
            "Teslimat tamamlandı",
            $"Tebrikler! #{order.CustomerOrderId} numaralı siparişi başarıyla teslim ettin.",
            "order_delivered",
            order.Id);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Order {OrderId} delivered by courier {CourierId}", orderId, courierId);

        // Notify customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Delivered");
            await AddCustomerNotificationAsync(
                order.CustomerId,
                "Sipariş Teslim Edildi",
                $"#{order.Id} numaralı siparişiniz başarıyla teslim edildi. Afiyet olsun!",
                "OrderDelivered",
                order.Id);
        }

        return true;
    }

    public async Task<List<Order>> GetActiveOrdersForCourierAsync(Guid courierId)
    {
        return await _context.Orders
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
            .Include(o => o.OrderCouriers)
            .Where(o => o.OrderCouriers.Any(oc => oc.CourierId == courierId && oc.IsActive)
                && o.Status != OrderStatus.Delivered
                && o.Status != OrderStatus.Cancelled)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync();
    }

    /// <summary>
    /// Belirli bir siparişe atanan tüm kuryelerin geçmişini getirir
    /// </summary>
    /// <param name="orderId">Sipariş ID'si</param>
    /// <returns>Siparişe atanan tüm OrderCourier kayıtları (tarihe göre sıralanmış)</returns>
    public async Task<List<OrderCourier>> GetOrderCourierHistoryAsync(Guid orderId)
    {
        return await _context.OrderCouriers
            .Include(oc => oc.Courier)
            .Where(oc => oc.OrderId == orderId)
            .OrderByDescending(oc => oc.CreatedAt)
            .ToListAsync();
    }

    private void AddCourierNotification(
        Guid courierId,
        string title,
        string message,
        string type,
        Guid? orderId = null)
    {
        _context.CourierNotifications.Add(new CourierNotification
        {
            CourierId = courierId,
            Title = title,
            Message = message,
            Type = type,
            OrderId = orderId
        });
    }

    private async Task AddVendorNotificationAsync(Guid vendorId, string customerOrderId, string courierName, string rejectReason)
    {
        _context.VendorNotifications.Add(new VendorNotification
        {
            VendorId = vendorId,
            Title = "Kurye Siparişi Reddetti",
            Message = $"#Order.{customerOrderId} numaralı sipariş {courierName} tarafından reddedildi. Sebep: {rejectReason}. Sipariş yeniden Hazır durumuna alındı.",
            Type = "CourierRejected",
            RelatedEntityId = null
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

    // Haversine formula to calculate distance in km
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

    private async Task<decimal> CalculateDeliveryFee(Order order, Courier courier)
    {
        decimal baseFee = 15.00m; // Base delivery fee

        // Get vendor and delivery address for distance calculation
        var vendor = await _context.Vendors.FindAsync(order.VendorId);
        var deliveryAddress = order.DeliveryAddress;

        if (vendor == null || deliveryAddress == null)
        {
            _logger.LogWarning("Cannot calculate delivery fee: missing vendor or delivery address for order {OrderId}", order.Id);
            return baseFee;
        }

        // Distance bonus (2 TL per km)
        double distance = CalculateDistance(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );
        decimal distanceBonus = (decimal)distance * 2.00m;

        // Time bonus (20% extra during evening hours 18:00-22:00)
        decimal timeBonus = 0;
        var currentHour = DateTime.Now.Hour;
        if (currentHour >= 18 && currentHour <= 22)
        {
            timeBonus = baseFee * 0.20m;
        }

        // Vehicle type bonus
        decimal vehicleBonus = courier.VehicleType switch
        {
            "Motosiklet" => 5.00m,
            "Araba" => 10.00m,
            _ => 0
        };

        decimal totalFee = baseFee + distanceBonus + timeBonus + vehicleBonus;

        return totalFee;
    }

    // Helper method to get active OrderCourier for an order
    private async Task<OrderCourier?> GetActiveOrderCourierAsync(Guid orderId)
    {
        return await _context.OrderCouriers
            .Include(oc => oc.Courier)
            .FirstOrDefaultAsync(oc => oc.OrderId == orderId && oc.IsActive);
    }

    // Helper method to deactivate previous assignments
    private async Task DeactivatePreviousAssignmentsAsync(Guid orderId)
    {
        var previousAssignments = await _context.OrderCouriers
            .Where(oc => oc.OrderId == orderId && oc.IsActive)
            .ToListAsync();

        foreach (var assignment in previousAssignments)
        {
            assignment.IsActive = false;
            assignment.UpdatedAt = DateTime.UtcNow;
        }
    }

    private async Task CreateCourierEarningAsync(Order order, Courier courier, OrderCourier orderCourier)
    {
        var vendor = await _context.Vendors.FindAsync(order.VendorId);
        var deliveryAddress = order.DeliveryAddress;

        if (vendor == null || deliveryAddress == null)
        {
            _logger.LogWarning("Cannot create earning record: missing vendor or delivery address for order {OrderId}", order.Id);
            return;
        }

        decimal baseFee = 15.00m;

        // Calculate distance bonus
        double distance = CalculateDistance(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );
        decimal distanceBonus = (decimal)distance * 2.00m;

        // Calculate time bonus
        decimal timeBonus = 0;
        var currentHour = DateTime.Now.Hour;
        if (currentHour >= 18 && currentHour <= 22)
        {
            timeBonus = baseFee * 0.20m;
        }

        // Calculate vehicle bonus
        decimal vehicleBonus = courier.VehicleType switch
        {
            "Motosiklet" => 5.00m,
            "Araba" => 10.00m,
            _ => 0
        };

        decimal totalEarning = baseFee + distanceBonus + timeBonus + vehicleBonus + (orderCourier.CourierTip ?? 0);

        var earning = new CourierEarning
        {
            CourierId = courier.Id,
            OrderId = order.Id,
            BaseDeliveryFee = baseFee + timeBonus + vehicleBonus,
            DistanceBonus = distanceBonus,
            TipAmount = orderCourier.CourierTip ?? 0,
            TotalEarning = totalEarning,
            EarnedAt = DateTime.UtcNow,
            IsPaid = false
        };

        _context.CourierEarnings.Add(earning);

        // Update courier totals
        courier.TotalEarnings += totalEarning;
        courier.CurrentDayEarnings += totalEarning;
    }
}

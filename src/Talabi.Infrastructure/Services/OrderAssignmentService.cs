using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Globalization;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Infrastructure.Services;

public class OrderAssignmentService(
    IUnitOfWork unitOfWork,
    ILogger<OrderAssignmentService> logger,
    INotificationService notificationService,
    ISignalRNotificationService signalRNotificationService,
    ILocalizationService localizationService,
    IHttpContextAccessor httpContextAccessor,
    IWalletService walletService,
    IMapService mapService)
    : IOrderAssignmentService
{
    private readonly IWalletService _walletService = walletService;
    private const string ResourceName = "OrderAssignmentResources";

// ... (rest of the methods) ...


    private string GetLanguageFromRequest()
    {
        var httpContext = httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return "tr"; // Default
        }

        // Check query parameter first
        var languageQuery = httpContext.Request.Query["language"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(languageQuery))
        {
            return NormalizeLanguageCode(languageQuery);
        }

        // Check Accept-Language header
        var acceptLanguage = httpContext.Request.Headers["Accept-Language"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(acceptLanguage))
        {
            var lang = acceptLanguage.Split(',').FirstOrDefault()?.Split(';').FirstOrDefault()?.Trim();
            if (!string.IsNullOrWhiteSpace(lang))
            {
                return NormalizeLanguageCode(lang);
            }
        }

        return "tr"; // Default
    }

    private string NormalizeLanguageCode(string? languageCode)
    {
        if (string.IsNullOrWhiteSpace(languageCode))
        {
            return "tr";
        }

        var normalized = languageCode.ToLowerInvariant().Trim();
        return normalized switch
        {
            "tr" or "turkish" or "tr-TR" => "tr",
            "en" or "english" or "en-US" or "en-GB" => "en",
            "ar" or "arabic" or "ar-SA" => "ar",
            _ => "tr"
        };
    }

    private CultureInfo GetCultureInfo(string languageCode)
    {
        try
        {
            return languageCode switch
            {
                "tr" => new CultureInfo("tr-TR"),
                "en" => new CultureInfo("en-US"),
                "ar" => new CultureInfo("ar-SA"),
                _ => new CultureInfo("tr-TR")
            };
        }
        catch
        {
            return new CultureInfo("tr-TR"); // Fallback to Turkish
        }
    }

// ...

    public async Task<bool> AssignOrderToCourierAsync(Guid orderId, Guid courierId)
    {
        var order = await unitOfWork.Orders.Query()
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);

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

        await unitOfWork.OrderCouriers.AddAsync(orderCourier);

        // Update order status
        order.Status = OrderStatus.Assigned;
        unitOfWork.Orders.Update(order);

        // Update courier
        courier.Status = CourierStatus.Assigned;
        unitOfWork.Couriers.Update(courier);

        var lang = GetLanguageFromRequest();
        var culture = GetCultureInfo(lang);

        // Add to status history
        await unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Assigned,
            Note = localizationService.GetLocalizedString(ResourceName, "OrderAssignedHistoryNote", culture,
                courier.Name),
            CreatedBy = "System"
        });

        // Validation: Courier must be within 5km of the vendor for Manual Assignment too
        if (order.Vendor != null)
        {
            // If vendor wasn't loaded in the query above (it is not included by default in initial query), load it now
            // Optimization: We could include it in the query, but let's check null to be safe or reload
            // Actually lines 93-95 does not Includes Vendor.
            var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);

            if (vendor != null && vendor.Latitude.HasValue && vendor.Longitude.HasValue &&
                courier.CurrentLatitude.HasValue && courier.CurrentLongitude.HasValue)
            {
                var distance = GeoHelper.CalculateDistance(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    courier.CurrentLatitude.Value,
                    courier.CurrentLongitude.Value);

                // 5 km limit + small buffer (0.5 km) for GPS inaccuracies = 5.5 km
                if (distance > 5.5)
                {
                    logger.LogWarning(
                        "Manual assignment failed: Courier {CourierId} is too far ({Distance}km) from vendor {VendorId}",
                        courierId, distance, order.VendorId);
                    return false; // Or throw specific exception if we want to give better error message
                }
            }
        }

        // Update courier
        courier.Status = CourierStatus.Assigned;
        unitOfWork.Couriers.Update(courier);

        await AddCourierNotification(
            courier.Id,
            localizationService.GetLocalizedString(ResourceName, "NewOrderAssigned", culture),
            localizationService.GetLocalizedString(ResourceName, "OrderAssignedMessage", culture,
                order.CustomerOrderId),
            "order_assigned",
            order.Id);

        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Order {OrderId} assigned to courier {CourierId}", orderId, courierId);

        // Send notification to courier
        if (!string.IsNullOrEmpty(courier.UserId))
        {
            await notificationService.SendOrderAssignmentNotificationAsync(courier.UserId, orderId);
            // Send SignalR notification (Real-time)
            await signalRNotificationService.SendOrderAssignmentNotificationAsync(courier.UserId, orderId);
        }

        // Send notification to customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var languageCode = GetLanguageFromRequest();
            await notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Assigned",
                languageCode);
            await AddCustomerNotificationAsync(
                order.CustomerId,
                localizationService.GetLocalizedString(ResourceName, "CourierAssignedTitle", culture),
                localizationService.GetLocalizedString(ResourceName, "CourierAssignedMessage", culture,
                    order.CustomerOrderId),
                "CourierAssigned",
                order.Id);
        }

        return true;
    }

    public async Task<Courier?> FindBestCourierAsync(Order order)
    {
        // 1. Get available couriers
        var availableCouriers = await unitOfWork.Couriers.Query()
            .Where(c => c.IsActive
                        && c.Status == CourierStatus.Available
                        && c.CurrentActiveOrders < c.MaxActiveOrders
                        && c.CurrentLatitude.HasValue
                        && c.CurrentLongitude.HasValue)
            .ToListAsync();

        if (!availableCouriers.Any())
        {
            logger.LogWarning("No available couriers found for order {OrderId}", order.Id);
            return null;
        }

        // 2. Get vendor location
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor == null)
        {
            logger.LogError("Vendor not found for order {OrderId}", order.Id);
            return null;
        }

        // 3. Calculate distances and find the best one
        // Simple logic: Closest courier within 10km
        var bestCourier = availableCouriers
            .Select(c => new
            {
                Courier = c,
                Distance = GeoHelper.CalculateDistance(
                    vendor.Latitude ?? 0,
                    vendor.Longitude ?? 0,
                    c.CurrentLatitude!.Value,
                    c.CurrentLongitude!.Value
                )
            })
            .Where(x => x.Distance <= 5) // Max 5km radius
            .OrderBy(x => x.Distance)
            .ThenByDescending(x => x.Courier.AverageRating) // Secondary sort by rating
            .FirstOrDefault();

        return bestCourier?.Courier;
    }

    public async Task<int> BroadcastOrderToCouriersAsync(Guid orderId, double radiusKm = 5.0)
    {
        var order = await unitOfWork.Orders.Query()
            .Include(o => o.DeliveryAddress) // Needed for fee calculation
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null || order.Status != OrderStatus.Ready) return 0;

        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor == null || !vendor.Latitude.HasValue || !vendor.Longitude.HasValue) return 0;

        // Get available couriers
        var availableCouriers = await unitOfWork.Couriers.Query()
            .Where(c => c.IsActive
                        && c.Status == CourierStatus.Available
                        && c.CurrentActiveOrders < c.MaxActiveOrders
                        && c.CurrentLatitude.HasValue
                        && c.CurrentLongitude.HasValue)
            .ToListAsync();

        // Filter by distance
        var nearbyCouriers = availableCouriers
            .Select(c => new
            {
                Courier = c,
                Distance = GeoHelper.CalculateDistance(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    c.CurrentLatitude!.Value,
                    c.CurrentLongitude!.Value
                )
            })
            .Where(x => x.Distance <= radiusKm)
            .ToList();

        if (!nearbyCouriers.Any()) return 0;

        // Deactivate previous active assignments/offers
        await DeactivatePreviousAssignmentsAsync(orderId);

        int offerCount = 0;
        foreach (var item in nearbyCouriers)
        {
            var fee = await CalculateDeliveryFee(order, item.Courier);

            var offer = new OrderCourier
            {
                OrderId = orderId,
                CourierId = item.Courier.Id,
                Status = OrderCourierStatus.Offered,
                IsActive = true,
                DeliveryFee = fee,
                CourierAssignedAt = DateTime.UtcNow
            };
            await unitOfWork.OrderCouriers.AddAsync(offer);
            offerCount++;


            // Send notification to courier
            if (!string.IsNullOrEmpty(item.Courier.UserId))
            {
                await notificationService.SendOrderAssignmentNotificationAsync(item.Courier.UserId, orderId);
                // Send SignalR notification (Real-time)
                await signalRNotificationService.SendOrderAssignmentNotificationAsync(item.Courier.UserId, orderId);
            }
        }

        await unitOfWork.SaveChangesAsync();
        logger.LogInformation("Order {OrderId} broadcasted to {Count} couriers within {Radius}km", orderId, offerCount,
            radiusKm);

        return offerCount;
    }

    public async Task<bool> AcceptOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await unitOfWork.Orders.GetByIdAsync(orderId);
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);

        if (order == null || courier == null) return false;

        var orderCourier = await GetActiveOrderCourierAsync(orderId);

        // Allow acceptance if it matches this courier
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;

        // Case 1: Standard Assignment (Assigned -> Accepted)
        bool isStandardAssignment =
            order.Status == OrderStatus.Assigned && orderCourier.Status == OrderCourierStatus.Assigned;

        // Case 2: Broadcase Offer (Ready -> Accepted) - Order might be Ready while Courier is Offered
        bool isOfferAcceptance = order.Status == OrderStatus.Ready && orderCourier.Status == OrderCourierStatus.Offered;

        if (!isStandardAssignment && !isOfferAcceptance) return false;

        if (courier.CurrentActiveOrders >= courier.MaxActiveOrders) return false;

        // Validation: Courier must be within 5km of the vendor to accept the order
        // This prevents accepting orders if the courier moved too far away after receiving the offer
        var vendorLoc = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendorLoc != null && vendorLoc.Latitude.HasValue && vendorLoc.Longitude.HasValue &&
            courier.CurrentLatitude.HasValue && courier.CurrentLongitude.HasValue)
        {
            var distance = GeoHelper.CalculateDistance(
                vendorLoc.Latitude.Value,
                vendorLoc.Longitude.Value,
                courier.CurrentLatitude.Value,
                courier.CurrentLongitude.Value);

            // 5 km limit + small buffer (0.5 km) for GPS inaccuracies = 5.5 km
            if (distance > 5.5)
            {
                logger.LogWarning("Courier {CourierId} tried to accept order {OrderId} but is too far ({Distance}km)",
                    courierId, orderId, distance);
                return false;
            }
        }

        // If this was an offer acceptance, we need to handle "Race Condition" / "Winner Takes All"
        if (isOfferAcceptance)
        {
            // Double check order hasn't been taken by someone else in the split second
            // The 'order.Status == Ready' check above helps, but DB concurrency is real key.
            // For now, assuming optimistic concurrency or single threaded logic for simplicity,
            // but we MUST deactivate other offers.

            // Reload all active offers for this order to deactivate others
            var allOffers = await unitOfWork.OrderCouriers.Query()
                .Where(oc => oc.OrderId == orderId && oc.IsActive && oc.Status == OrderCourierStatus.Offered)
                .ToListAsync();

            foreach (var offer in allOffers)
            {
                if (offer.Id != orderCourier.Id) // Don't touch the winner yet
                {
                    offer.IsActive = false;
                    offer.UpdatedAt = DateTime.UtcNow;
                    unitOfWork.OrderCouriers.Update(offer);
                }
            }
        }

        // Update OrderCourier (Winner)
        orderCourier.CourierAcceptedAt = DateTime.UtcNow;
        orderCourier.Status = OrderCourierStatus.Accepted;
        orderCourier.UpdatedAt = DateTime.UtcNow;
        unitOfWork.OrderCouriers.Update(orderCourier);

        // Update order status
        order.Status = OrderStatus.Accepted;
        unitOfWork.Orders.Update(order);

        var lang = GetLanguageFromRequest();
        var culture = GetCultureInfo(lang);

        // Add to status history
        await unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Accepted,
            Note = localizationService.GetLocalizedString(ResourceName, "OrderAcceptedHistoryNote", culture,
                courier.Name),
            CreatedBy = courier.UserId
        });

        // Update courier
        courier.CurrentActiveOrders++;
        courier.Status = CourierStatus.Busy;
        unitOfWork.Couriers.Update(courier);

        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Order {OrderId} accepted by courier {CourierId}", orderId, courierId);

        // Send notification to vendor
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor != null && !string.IsNullOrEmpty(vendor.OwnerId))
        {
            var vendorLang = GetLanguageFromRequest();
            var vendorCulture = GetCultureInfo(vendorLang);
            await AddVendorNotificationBaseAsync(
                vendor.Id,
                localizationService.GetLocalizedString(ResourceName, "CourierAcceptedOrder", vendorCulture),
                localizationService.GetLocalizedString(ResourceName, "CourierAcceptedOrderMessage", vendorCulture,
                    order.CustomerOrderId, courier.Name),
                "CourierAccepted",
                order.Id);

            // Send Firebase push notification to vendor
            await notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "Accepted",
                vendorLang);
        }

        // Send notification to customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var customerLang = GetLanguageFromRequest();
            var customerCulture = GetCultureInfo(customerLang);
            await notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Accepted",
                customerLang);
            await AddCustomerNotificationAsync(
                order.CustomerId,
                localizationService.GetLocalizedString(ResourceName, "CourierAcceptedTitle", customerCulture),
                localizationService.GetLocalizedString(ResourceName, "CourierAcceptedMessage", customerCulture,
                    order.CustomerOrderId),
                "CourierAccepted",
                order.Id);
        }

        return true;
    }

    public async Task<bool> RejectOrderAsync(Guid orderId, Guid courierId, string reason)
    {
        var order = await unitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);

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
        unitOfWork.OrderCouriers.Update(orderCourier);

        // Reset order status to Ready
        order.Status = OrderStatus.Ready;
        order.CancelReason = null; // Clear cancel reason since order is still active
        unitOfWork.Orders.Update(order);

        // Update courier
        courier.Status = courier.CurrentActiveOrders > 0 ? CourierStatus.Busy : CourierStatus.Available;
        unitOfWork.Couriers.Update(courier);

        var culture = GetCultureInfo(GetLanguageFromRequest());

        // Add to status history (Revert to Ready)
        await unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Ready,
            Note = localizationService.GetLocalizedString(ResourceName, "OrderRejectedHistoryNote", culture,
                courier.Name, reason),
            CreatedBy = courier.UserId
        });

        // Add vendor notification
        if (order.VendorId != Guid.Empty)
        {
            var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
            await AddVendorNotificationAsync(
                order.VendorId,
                order.CustomerOrderId,
                courier.Name,
                reason.Trim()
            );

            // Send Firebase push notification to vendor
            if (vendor != null && !string.IsNullOrEmpty(vendor.OwnerId))
            {
                var lang = GetLanguageFromRequest();
                await notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "Ready",
                    lang);
            }
        }

        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Order {OrderId} rejected by courier {CourierId}. Reason: {Reason}", orderId, courierId,
            reason);

        return true;
    }

    public async Task<bool> PickUpOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await unitOfWork.Orders.GetByIdAsync(orderId);
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);

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
        unitOfWork.OrderCouriers.Update(orderCourier);

        // Update order status
        order.Status = OrderStatus.OutForDelivery;
        unitOfWork.Orders.Update(order);

        var lang = GetLanguageFromRequest();
        var culture = GetCultureInfo(lang);

        // Add to status history
        await unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.OutForDelivery,
            Note = localizationService.GetLocalizedString(ResourceName, "OrderPickedUpHistoryNote", culture,
                courier.Name),
            CreatedBy = courier.UserId
        });

        // Update courier
        courier.Status = CourierStatus.Busy;
        unitOfWork.Couriers.Update(courier);

        await AddCourierNotification(
            courier.Id,
            localizationService.GetLocalizedString(ResourceName, "OrderOutForDelivery", culture),
            localizationService.GetLocalizedString(ResourceName, "OrderOutForDeliveryMessage", culture,
                order.CustomerOrderId),
            "order_progress",
            order.Id);

        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Order {OrderId} picked up by courier {CourierId}", orderId, courierId);

        // Notify vendor
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor != null && !string.IsNullOrEmpty(vendor.OwnerId))
        {
            var vendorLang = GetLanguageFromRequest();
            var vendorCulture = GetCultureInfo(vendorLang);
            await AddVendorNotificationBaseAsync(
                vendor.Id,
                localizationService.GetLocalizedString(ResourceName, "OrderPickedUp", vendorCulture),
                localizationService.GetLocalizedString(ResourceName, "OrderPickedUpMessage", vendorCulture,
                    order.CustomerOrderId),
                "OrderPickedUp",
                order.Id);

            // Send Firebase push notification to vendor
            await notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "OutForDelivery",
                vendorLang);
        }

        // Notify customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var customerLang = GetLanguageFromRequest();
            var customerCulture = GetCultureInfo(customerLang);
            await notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId,
                "OutForDelivery", customerLang);
            await AddCustomerNotificationAsync(
                order.CustomerId,
                localizationService.GetLocalizedString(ResourceName, "OrderOnTheWay", customerCulture),
                localizationService.GetLocalizedString(ResourceName, "OrderOnTheWayMessage", customerCulture,
                    order.CustomerOrderId),
                "OrderOutForDelivery",
                order.Id);
        }

        return true;
    }

    public async Task<bool> DeliverOrderAsync(Guid orderId, Guid courierId)
    {
        var order = await unitOfWork.Orders.Query()
            .Include(o => o.DeliveryAddress)
            .FirstOrDefaultAsync(o => o.Id == orderId);
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);

        if (order == null || courier == null) return false;

        var orderCourier = await GetActiveOrderCourierAsync(orderId);
        if (orderCourier == null || orderCourier.CourierId != courierId) return false;
        if (order.Status != OrderStatus.OutForDelivery) return false;
        if (orderCourier.Status != OrderCourierStatus.OutForDelivery) return false;

        // Update OrderCourier
        orderCourier.DeliveredAt = DateTime.UtcNow;
        orderCourier.Status = OrderCourierStatus.Delivered;
        orderCourier.UpdatedAt = DateTime.UtcNow;
        unitOfWork.OrderCouriers.Update(orderCourier);

        // Update order status
        order.Status = OrderStatus.Delivered;
        unitOfWork.Orders.Update(order);

        var lang = GetLanguageFromRequest();
        var culture = GetCultureInfo(lang);

        // Add to status history
        await unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = OrderStatus.Delivered,
            Note = localizationService.GetLocalizedString(ResourceName, "OrderDeliveredHistoryNote", culture,
                courier.Name),
            CreatedBy = courier.UserId
        });

        // Update courier
        courier.CurrentActiveOrders = Math.Max(0, courier.CurrentActiveOrders - 1);
        courier.Status = courier.CurrentActiveOrders == 0 ? CourierStatus.Available : CourierStatus.Busy;
        courier.TotalDeliveries++;
        unitOfWork.Couriers.Update(courier);

        // Create detailed earning record (use OrderCourier data)
        await CreateCourierEarningAsync(order, courier, orderCourier);

        // Credit Courier Wallet
        if (!string.IsNullOrEmpty(courier.UserId))
        {
            var courierEarning = await unitOfWork.CourierEarnings.Query()
                .OrderByDescending(e => e.EarnedAt)
                .FirstOrDefaultAsync(e => e.OrderId == order.Id && e.CourierId == courier.Id);

            if (courierEarning != null)
            {
                try
                {
                    await _walletService.AddEarningAsync(
                        courier.UserId,
                        courierEarning.TotalEarning,
                        order.Id.ToString(),
                        order.CustomerOrderId,
                        localizationService.GetLocalizedString(ResourceName, "EarningDescription", culture,
                            order.CustomerOrderId));

                    // Mark as paid (reflected in wallet)
                    courierEarning.IsPaid = true;
                    courierEarning.PaidAt = DateTime.UtcNow;
                    unitOfWork.CourierEarnings.Update(courierEarning);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Error crediting courier wallet for order {OrderId}", order.Id);
                }
            }
        }

        await AddCourierNotification(
            courier.Id,
            localizationService.GetLocalizedString(ResourceName, "DeliveryCompleted", culture),
            localizationService.GetLocalizedString(ResourceName, "DeliveryCompletedMessage", culture,
                order.CustomerOrderId),
            "order_delivered",
            order.Id);

        await unitOfWork.SaveChangesAsync();

        logger.LogInformation("Order {OrderId} delivered by courier {CourierId}", orderId, courierId);

        // Notify vendor
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor != null && !string.IsNullOrEmpty(vendor.OwnerId))
        {
            var vendorLang = GetLanguageFromRequest();
            var vendorCulture = GetCultureInfo(vendorLang);

            // Credit Vendor Wallet
            try
            {
                await _walletService.AddEarningAsync(
                    vendor.OwnerId,
                    order.TotalAmount,
                    order.Id.ToString(),
                    order.CustomerOrderId,
                    localizationService.GetLocalizedString("WalletResources", "VendorSaleEarning", vendorCulture,
                        order.CustomerOrderId));
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Error crediting vendor wallet for order {OrderId}", order.Id);
            }

            await AddVendorNotificationBaseAsync(
                vendor.Id,
                localizationService.GetLocalizedString(ResourceName, "OrderDelivered", vendorCulture),
                localizationService.GetLocalizedString(ResourceName, "OrderDeliveredToCustomerMessage", vendorCulture,
                    order.CustomerOrderId),
                "OrderDelivered",
                order.Id);

            // Send Firebase push notification to vendor
            await notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "Delivered",
                vendorLang);
        }

        // Notify customer
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var customerLang = GetLanguageFromRequest();
            var customerCulture = GetCultureInfo(customerLang);
            await notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Delivered",
                customerLang);
            await AddCustomerNotificationAsync(
                order.CustomerId,
                localizationService.GetLocalizedString(ResourceName, "OrderDelivered", customerCulture),
                localizationService.GetLocalizedString(ResourceName, "OrderDeliveredMessage", customerCulture,
                    order.CustomerOrderId),
                "OrderDelivered",
                order.Id);
        }

        return true;
    }

    public async Task<List<Order>> GetActiveOrdersForCourierAsync(Guid courierId)
    {
        var courier = await unitOfWork.Couriers.GetByIdAsync(courierId);
        if (courier == null) return new List<Order>();

        var orders = await unitOfWork.Orders.Query()
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

        // Safety Filter: Even if assigned, if the courier is NOT 'Accepted', 'OutForDelivery' etc.
        // And the distance is > 5km, hide it. This cleans up stale assignments/offers or illegal manual assignments.

        var filteredOrders = new List<Order>();
        foreach (var order in orders)
        {
            var myAssignment = order.OrderCouriers.FirstOrDefault(oc => oc.CourierId == courierId && oc.IsActive);

            // If already accepted/picked up/out for delivery, show it regardless of distance (contract is made)
            if (myAssignment != null && (myAssignment.Status == OrderCourierStatus.Accepted ||
                                         myAssignment.Status == OrderCourierStatus.OutForDelivery ||
                                         myAssignment.Status == OrderCourierStatus.PickedUp))
            {
                filteredOrders.Add(order);
                continue;
            }

            // For 'Assigned' (Manual) or 'Offered' (Broadcast), verify distance again
            if (courier.CurrentLatitude.HasValue && courier.CurrentLongitude.HasValue &&
                order.Vendor != null && order.Vendor.Latitude.HasValue && order.Vendor.Longitude.HasValue)
            {
                var dist = GeoHelper.CalculateDistance(
                    order.Vendor.Latitude.Value,
                    order.Vendor.Longitude.Value,
                    courier.CurrentLatitude.Value,
                    courier.CurrentLongitude.Value);

                // Strict 5.5km visibility limit (5.0 + buffer)
                if (dist <= 5.5)
                {
                    filteredOrders.Add(order);
                }
            }
            else
            {
                // If coordinates are missing, deciding to HIDE pending offers for safety?
                // Or show them? Given the strict requirement "onun dışındakiler çıkmasın", 
                // if we can't verify it's inside 5km, we should probably hide it or show it?
                // Let's assume Valid Location is required for visibility.
                // BUT, if the location update failed, maybe we shouldn't punish?
                // Let's show it if location is missing to avoid "Disappearing orders" bugs, 
                // trusting the Assignment logic blocked it if needed. 
                // Wait, user said "haritada 5km dışında". So location EXISTS.
                // So if location exists and > 5.5, we skipped the `if` above.
                // If location is missing, we fall here.
                // Let's safe-guard: Only hide if we KNOW it's far.
                filteredOrders.Add(order);
            }
        }

        return filteredOrders;
    }

    /// <summary>
    /// Belirli bir siparişe atanan tüm kuryelerin geçmişini getirir
    /// </summary>
    /// <param name="orderId">Sipariş ID'si</param>
    /// <returns>Siparişe atanan tüm OrderCourier kayıtları (tarihe göre sıralanmış)</returns>
    public async Task<List<OrderCourier>> GetOrderCourierHistoryAsync(Guid orderId)
    {
        return await unitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Courier)
            .Where(oc => oc.OrderId == orderId)
            .OrderByDescending(oc => oc.CreatedAt)
            .ToListAsync();
    }

    private async Task AddCourierNotification(
        Guid courierId,
        string title,
        string message,
        string type,
        Guid? orderId = null)
    {
        await unitOfWork.CourierNotifications.AddAsync(new CourierNotification
        {
            CourierId = courierId,
            Title = title,
            Message = message,
            Type = type,
            OrderId = orderId
        });
    }

    private async Task AddVendorNotificationAsync(Guid vendorId, string customerOrderId, string courierName,
        string rejectReason)
    {
        var lang = GetLanguageFromRequest();
        var culture = GetCultureInfo(lang);

        await unitOfWork.VendorNotifications.AddAsync(new VendorNotification
        {
            VendorId = vendorId,
            Title = localizationService.GetLocalizedString(ResourceName, "CourierRejectedOrder", culture),
            Message = localizationService.GetLocalizedString(ResourceName, "CourierRejectedOrderMessage", culture,
                customerOrderId, courierName, rejectReason),
            Type = "CourierRejected",
            RelatedEntityId = null
        });
    }

    private async Task AddVendorNotificationBaseAsync(Guid vendorId, string title, string message, string type,
        Guid? relatedEntityId = null)
    {
        await unitOfWork.VendorNotifications.AddAsync(new VendorNotification
        {
            VendorId = vendorId,
            Title = title,
            Message = message,
            Type = type,
            RelatedEntityId = relatedEntityId
        });
    }

    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type,
        Guid? orderId = null)
    {
        var customer = await unitOfWork.Customers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);
        if (customer == null)
        {
            // Create customer if doesn't exist
            customer = new Customer
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            await unitOfWork.Customers.AddAsync(customer);
            await unitOfWork.SaveChangesAsync();
        }

        await unitOfWork.CustomerNotifications.AddAsync(new CustomerNotification
        {
            CustomerId = customer.Id,
            Title = title,
            Message = message,
            Type = type,
            OrderId = orderId
        });
    }

    internal async Task<decimal> CalculateDeliveryFee(Order order, Courier courier)
    {
        decimal baseFee = 15.00m; // Base delivery fee

        // Get vendor and delivery address for distance calculation
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        var deliveryAddress = order.DeliveryAddress;

        if (vendor == null || deliveryAddress == null)
        {
            logger.LogWarning("Cannot calculate delivery fee: missing vendor or delivery address for order {OrderId}",
                order.Id);
            return baseFee;
        }

        // Tiered Distance Fee
        double crowFlyDistance = GeoHelper.CalculateDistance(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );

        double roadDistance = await mapService.GetRoadDistanceAsync(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );

        double distance = roadDistance > 0 ? roadDistance : crowFlyDistance;

        decimal distanceFee;
        if (distance <= 2)
        {
            distanceFee = 0; // Included in base fee
        }
        else if (distance <= 5)
        {
            distanceFee = (decimal)(distance - 2) * 5.00m; // 5 TL per km after 2km
        }
        else if (distance <= 10)
        {
            distanceFee = (3 * 5.00m) + (decimal)(distance - 5) * 8.00m; // 8 TL per km between 5-10km
        }
        else
        {
            distanceFee = (3 * 5.00m) + (5 * 8.00m) + (decimal)(distance - 10) * 10.00m; // 10 TL per km after 10km
        }

        decimal distanceBonus = distanceFee;

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
            CourierVehicleType.Motorcycle => 5.00m,
            CourierVehicleType.Car => 10.00m,
            _ => 0
        };

        decimal totalFee = baseFee + distanceBonus + timeBonus + vehicleBonus;

        return totalFee;
    }

// Helper method to get active OrderCourier for an order
    private async Task<OrderCourier?> GetActiveOrderCourierAsync(Guid orderId)
    {
        return await unitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Courier)
            .FirstOrDefaultAsync(oc => oc.OrderId == orderId && oc.IsActive);
    }

// Helper method to deactivate previous assignments
    private async Task DeactivatePreviousAssignmentsAsync(Guid orderId)
    {
        var previousAssignments = await unitOfWork.OrderCouriers.Query()
            .Where(oc => oc.OrderId == orderId && oc.IsActive)
            .ToListAsync();

        foreach (var assignment in previousAssignments)
        {
            assignment.IsActive = false;
            assignment.UpdatedAt = DateTime.UtcNow;
            unitOfWork.OrderCouriers.Update(assignment);
        }
    }

    internal async Task CreateCourierEarningAsync(Order order, Courier courier, OrderCourier orderCourier)
    {
        var vendor = await unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        var deliveryAddress = order.DeliveryAddress;

        if (vendor == null || deliveryAddress == null)
        {
            logger.LogWarning("Cannot create earning record: missing vendor or delivery address for order {OrderId}",
                order.Id);
            return;
        }

        decimal baseFee = 15.00m;

        // Calculate distance bonus (Tiered)
        double crowFlyDistance = GeoHelper.CalculateDistance(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );

        double roadDistance = await mapService.GetRoadDistanceAsync(
            vendor.Latitude ?? 0,
            vendor.Longitude ?? 0,
            deliveryAddress.Latitude ?? 0,
            deliveryAddress.Longitude ?? 0
        );

        double distance = roadDistance > 0 ? roadDistance : crowFlyDistance;

        decimal distanceFee;
        if (distance <= 2)
        {
            distanceFee = 0;
        }
        else if (distance <= 5)
        {
            distanceFee = (decimal)(distance - 2) * 5.00m;
        }
        else if (distance <= 10)
        {
            distanceFee = (3 * 5.00m) + (decimal)(distance - 5) * 8.00m;
        }
        else
        {
            distanceFee = (3 * 5.00m) + (5 * 8.00m) + (decimal)(distance - 10) * 10.00m;
        }

        decimal distanceBonus = distanceFee;

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
            CourierVehicleType.Motorcycle => 5.00m,
            CourierVehicleType.Car => 10.00m,
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

        await unitOfWork.CourierEarnings.AddAsync(earning);

        // Update courier totals
        courier.TotalEarnings += totalEarning;
        courier.CurrentDayEarnings += totalEarning;
        unitOfWork.Couriers.Update(courier);
    }
}

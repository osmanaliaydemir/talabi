using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.Helpers;
using Talabi.Core.Models;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Sipariş işlemleri için service implementation
/// </summary>
public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILocalizationService _localizationService;
    private readonly INotificationService _notificationService;
    private readonly IRuleValidatorService _ruleValidatorService;
    private readonly ISystemSettingsService _systemSettingsService;
    private readonly IMapService _mapService;
    private const string ResourceName = "OrderResources";

    public OrderService(
        IUnitOfWork unitOfWork,
        ILocalizationService localizationService,
        INotificationService notificationService,
        IRuleValidatorService ruleValidatorService,
        ISystemSettingsService systemSettingsService,
        IMapService mapService)
    {
        _unitOfWork = unitOfWork;
        _localizationService = localizationService;
        _notificationService = notificationService;
        _ruleValidatorService = ruleValidatorService;
        _systemSettingsService = systemSettingsService;
        _mapService = mapService;
    }

    /// <summary>
    /// Benzersiz müşteri sipariş ID'si oluşturur
    /// </summary>
    public async Task<string> GenerateUniqueCustomerOrderIdAsync()
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
    public async Task<string> GenerateUniqueCustomerOrderItemIdAsync()
    {
        var random = new Random();
        string customerOrderItemId;
        bool isUnique;

        do
        {
            customerOrderItemId = random.Next(100000, 999999).ToString();
            isUnique = !await _unitOfWork.OrderItems.Query()
                .AnyAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);
        } while (!isUnique);

        return customerOrderItemId;
    }

    /// <summary>
    /// Yeni sipariş oluşturur
    /// </summary>
    public async Task<Order> CreateOrderAsync(CreateOrderDto dto, string customerId, CultureInfo culture)
    {
        // 1. Validate vendor exists
        var vendor = await _unitOfWork.Vendors.GetByIdAsync(dto.VendorId);
        if (vendor == null)
        {
            throw new KeyNotFoundException(
                _localizationService.GetLocalizedString(ResourceName, "VendorNotFound", culture));
        }

        // 2. Calculate total and create order items
        decimal totalAmount = 0;
        var orderItems = new List<OrderItem>();
        // Keep track of RuleCartItems for validation
        var ruleCartItems = new List<RuleValidationContext.RuleCartItem>();

        foreach (var item in dto.Items)
        {
            var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId);
            if (product == null)
            {
                throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "ProductNotFound",
                    culture, item.ProductId));
            }

            decimal itemUnitPrice = product.Price;
            if (item.SelectedOptions != null)
            {
                foreach (var option in item.SelectedOptions)
                {
                    itemUnitPrice += option.PriceAdjustment;
                }
            }

            totalAmount += itemUnitPrice * item.Quantity;
            var customerOrderItemId = await GenerateUniqueCustomerOrderItemIdAsync();
            orderItems.Add(new OrderItem
            {
                ProductId = item.ProductId,
                Quantity = item.Quantity,
                UnitPrice = itemUnitPrice,
                CustomerOrderItemId = customerOrderItemId,
                SelectedOptions = item.SelectedOptions != null
                    ? System.Text.Json.JsonSerializer.Serialize(item.SelectedOptions)
                    : null
            });

            ruleCartItems.Add(new RuleValidationContext.RuleCartItem
            {
                ProductId = product.Id,
                CategoryId = product.CategoryId,
                VendorId = product.VendorId,
                Quantity = item.Quantity,
                Price = product.Price,
                VendorType = (int)(product.VendorType ?? VendorType.Market) // Default to Market if null
            });
        }

        // 3. Validate Delivery Address and Distance
        if (!dto.DeliveryAddressId.HasValue)
        {
            throw new ArgumentException(
                _localizationService.GetLocalizedString(ResourceName, "AddressRequired", culture));
        }

        var userAddress = await _unitOfWork.UserAddresses.GetByIdAsync(dto.DeliveryAddressId.Value);
        if (userAddress == null)
        {
            throw new KeyNotFoundException(
                _localizationService.GetLocalizedString(ResourceName, "AddressNotFound", culture));
        }

        // Validate vendor and address locations are available
        if (!vendor.Latitude.HasValue || !vendor.Longitude.HasValue)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "VendorLocationNotAvailable", culture));
        }

        if (!userAddress.Latitude.HasValue || !userAddress.Longitude.HasValue)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "AddressLocationNotAvailable", culture));
        }

        // Distance and Radius Check (Crow-fly)
        // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
        var deliveryRadius = vendor.DeliveryRadiusInKm == 0 ? 5 : vendor.DeliveryRadiusInKm;
        
        double crowFlyDistance = GeoHelper.CalculateDistance(
            vendor.Latitude.Value,
            vendor.Longitude.Value,
            userAddress.Latitude.Value,
            userAddress.Longitude.Value
        );

        if (crowFlyDistance > deliveryRadius)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "OutOfDeliveryRadius", culture));
        }

        // Router Check (Real Road Distance)
        double roadDistance = await _mapService.GetRoadDistanceAsync(
            vendor.Latitude.Value,
            vendor.Longitude.Value,
            userAddress.Latitude.Value,
            userAddress.Longitude.Value
        );

        double orderDistance = roadDistance > 0 ? roadDistance : crowFlyDistance;

        if (orderDistance > deliveryRadius)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "OutOfDeliveryRadius", culture));
        }

        // Dynamic Minimum Order Amount Check
        decimal dynamicMinAmount = vendor.MinimumOrderAmount ?? 0;
        if (orderDistance > 5)
        {
            dynamicMinAmount = Math.Max(dynamicMinAmount, 300.00m);
        }
        else if (orderDistance > 2)
        {
            dynamicMinAmount = Math.Max(dynamicMinAmount, 200.00m);
        }

        if (totalAmount < dynamicMinAmount)
        {
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName,
                "MinimumOrderAmountNotMet", culture, dynamicMinAmount));
        }

        // Fetch Delivery Fee and Free Delivery Threshold from System Settings
        decimal deliveryFee = 0;
        var deliveryFeeStr = await _systemSettingsService.GetSettingAsync("DeliveryFee");
        if (!string.IsNullOrEmpty(deliveryFeeStr) && decimal.TryParse(deliveryFeeStr, NumberStyles.Any,
                CultureInfo.InvariantCulture, out var parsedFee))
        {
            deliveryFee = parsedFee;
        }

        var freeDeliveryThresholdStr = await _systemSettingsService.GetSettingAsync("FreeDeliveryThreshold");
        if (!string.IsNullOrEmpty(freeDeliveryThresholdStr) && decimal.TryParse(freeDeliveryThresholdStr,
                NumberStyles.Any, CultureInfo.InvariantCulture, out var threshold))
        {
            if (totalAmount >= threshold)
            {
                deliveryFee = 0;
            }
        }

        // 4. Validate and Apply Coupon (if provided)
        decimal discountAmount = 0;
        Coupon? appliedCoupon = null;

        if (!string.IsNullOrEmpty(dto.CouponCode))
        {
            var coupon = await _unitOfWork.Coupons.Query()
                .AsNoTracking() // Just reading logic
                .Include(c => c.CouponCities)
                .Include(c => c.CouponDistricts)
                .Include(c => c.CouponCategories)
                .Include(c => c.CouponProducts)
                .FirstOrDefaultAsync(c => c.Code == dto.CouponCode && c.IsActive);

            if (coupon != null)
            {
                Guid.TryParse(customerId, out var userIdGuid);

                var validationContext = new RuleValidationContext
                {
                    UserId = userIdGuid != Guid.Empty ? userIdGuid : null,
                    CityId = userAddress.CityId,
                    DistrictId = userAddress.DistrictId,
                    RequestTime = DateTime.UtcNow,
                    Items = ruleCartItems,
                    CartTotal = totalAmount,
                    IsFirstOrder = !await _unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == customerId)
                };

                if (_ruleValidatorService.ValidateCoupon(coupon, validationContext, out var _))
                {
                    // Calculate discount
                    if (coupon.DiscountType == DiscountType.Percentage)
                    {
                        discountAmount = totalAmount * (coupon.DiscountValue / 100);
                    }
                    else
                    {
                        discountAmount = coupon.DiscountValue;
                    }

                    // Max discount check? (If needed based on business rules)
                    // Ensure discount doesn't exceed total
                    if (discountAmount > totalAmount) discountAmount = totalAmount;

                    appliedCoupon = coupon;
                }
            }
        }

        // Campaign Logic
        Campaign? appliedCampaign = null;
        if (dto.CampaignId.HasValue)
        {
            var campaign = await _unitOfWork.Campaigns.Query()
                .AsNoTracking()
                .Include(c => c.CampaignCities)
                .Include(c => c.CampaignDistricts)
                .Include(c => c.CampaignCategories)
                .Include(c => c.CampaignProducts)
                .FirstOrDefaultAsync(c => c.Id == dto.CampaignId.Value && c.IsActive);

            if (campaign != null)
            {
                Guid.TryParse(customerId, out var userIdGuid);
                var validationContext = new RuleValidationContext
                {
                    UserId = userIdGuid != Guid.Empty ? userIdGuid : null,
                    CityId = userAddress.CityId,
                    DistrictId = userAddress.DistrictId,
                    RequestTime = DateTime.UtcNow,
                    Items = ruleCartItems,
                    CartTotal = totalAmount,
                    IsFirstOrder = !await _unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == customerId)
                };

                if (_ruleValidatorService.ValidateCampaign(campaign, validationContext, out var _))
                {
                    decimal campaignDiscount;
                    if (campaign.DiscountType == DiscountType.Percentage)
                    {
                        campaignDiscount = totalAmount * (campaign.DiscountValue / 100);
                    }
                    else
                    {
                        campaignDiscount = campaign.DiscountValue;
                    }

                    if (campaignDiscount > totalAmount) campaignDiscount = totalAmount;

                    if (campaignDiscount > 0)
                    {
                        if (campaignDiscount >= discountAmount)
                        {
                            discountAmount = campaignDiscount;
                            appliedCampaign = campaign;
                            appliedCoupon = null; // Campaign wins
                        }
                    }
                }
            }
        }

        // Apply discount to total (before delivery fee)
        var finalAmount = totalAmount - discountAmount;
        if (finalAmount < 0) finalAmount = 0;


        // 5. Create order
        var customerOrderId = await GenerateUniqueCustomerOrderIdAsync();

        var order = new Order
        {
            VendorId = dto.VendorId,
            CustomerId = customerId,
            CustomerOrderId = customerOrderId,
            TotalAmount = finalAmount + deliveryFee, // Add Delivery Fee to FINAL amount
            DeliveryFee = deliveryFee,
            Status = OrderStatus.Pending,
            OrderItems = orderItems,
            CreatedAt = DateTime.UtcNow,
            DeliveryAddressId = dto.DeliveryAddressId,
            // New Fields
            CouponId = appliedCoupon?.Id,
            CampaignId = appliedCampaign?.Id,
            DiscountAmount = discountAmount
        };

        if (appliedCoupon != null)
        {
            // Optional: Increment usage count for coupon if we tracked it
        }

        await _unitOfWork.Orders.AddAsync(order);
        await _unitOfWork.SaveChangesAsync();

        // Add vendor notification
        await AddVendorNotificationAsync(
            order.VendorId,
            _localizationService.GetLocalizedString(ResourceName, "NewOrderTitle", culture),
            _localizationService.GetLocalizedString(ResourceName, "NewOrderMessage", culture, order.CustomerOrderId,
                order.TotalAmount.ToString("N2")),
            "NewOrder",
            order.Id);

        // Send Firebase push notification to vendor
        if (!string.IsNullOrEmpty(vendor.OwnerId))
        {
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, order.Id, "Pending",
                languageCode);
        }

        // Add customer notification
        if (customerId != "anonymous")
        {
            await AddCustomerNotificationAsync(
                customerId,
                _localizationService.GetLocalizedString(ResourceName, "OrderCreatedTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCreatedMessage", culture,
                    order.CustomerOrderId, order.TotalAmount.ToString("N2")),
                "OrderCreated",
                order.Id);

            // Send Firebase push notification to customer
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(customerId, order.Id, "Pending",
                languageCode);
        }

        await _unitOfWork.SaveChangesAsync();

        return order;
    }

    /// <summary>
    /// Siparişi iptal eder
    /// </summary>
    /// <summary>
    /// Siparişi iptal eder
    /// </summary>
    public async Task<bool> CancelOrderAsync(Guid orderId, string? userId, CancelOrderDto dto, CultureInfo culture)
    {
        // Authorization: userId must be provided
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new UnauthorizedAccessException(
                _localizationService.GetLocalizedString(ResourceName, "Unauthorized", culture));
        }

        var order = await _unitOfWork.Orders.Query()
            .AsNoTracking() // Read-only check
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            throw new KeyNotFoundException(
                _localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
        }

        // Authorization: Only the customer who owns the order can cancel it
        if (order.CustomerId != userId)
        {
            throw new UnauthorizedAccessException(
                _localizationService.GetLocalizedString(ResourceName, "Forbidden", culture));
        }

        // Check if order can be cancelled
        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Cancelled)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "OrderCannotBeCancelled", culture));
        }

        // Customers can only cancel Pending or Preparing orders
        if (order.Status != OrderStatus.Pending && order.Status != OrderStatus.Preparing)
        {
            throw new InvalidOperationException(
                _localizationService.GetLocalizedString(ResourceName, "InvalidCancellationStatus", culture));
        }

        // Validate reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
        {
            throw new ArgumentException(
                _localizationService.GetLocalizedString(ResourceName, "InvalidCancellationReason", culture));
        }

        // --- BULK UPDATE LOGIC START ---
        var now = DateTime.UtcNow;

        try
        {
            // 1. Bulk Update Order Items
            // Mark all items as cancelled
            await _unitOfWork.OrderItems.Query()
                .Where(oi => oi.OrderId == orderId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(oi => oi.IsCancelled, true)
                    .SetProperty(oi => oi.CancelReason, dto.Reason)
                    .SetProperty(oi => oi.CancelledAt, now));

            // 2. Bulk Update Order
            // Updates status directly avoiding Concurrency Checks
            await _unitOfWork.Orders.Query()
                .Where(o => o.Id == orderId)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(o => o.Status, OrderStatus.Cancelled)
                    .SetProperty(o => o.CancelReason, dto.Reason)
                    .SetProperty(o => o.CancelledAt, now));
        }
        catch (NotSupportedException)
        {
            // Fallback for non-relational providers (e.g., EF InMemory) that don't support ExecuteUpdate.
            var trackedOrder = await _unitOfWork.Orders.Query().FirstOrDefaultAsync(o => o.Id == orderId);
            if (trackedOrder == null)
            {
                throw new KeyNotFoundException(
                    _localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
            }

            var trackedItems = await _unitOfWork.OrderItems.Query()
                .Where(oi => oi.OrderId == orderId)
                .ToListAsync();

            foreach (var item in trackedItems)
            {
                item.IsCancelled = true;
                item.CancelReason = dto.Reason;
                item.CancelledAt = now;
                _unitOfWork.OrderItems.Update(item);
            }

            trackedOrder.Status = OrderStatus.Cancelled;
            trackedOrder.CancelReason = dto.Reason;
            trackedOrder.CancelledAt = now;
            _unitOfWork.Orders.Update(trackedOrder);
        }
        catch (InvalidOperationException ex) when (
            ex.Message.Contains("ExecuteUpdate", StringComparison.OrdinalIgnoreCase) ||
            ex.Message.Contains("not supported by the current database provider", StringComparison.OrdinalIgnoreCase))
        {
            // Same fallback for providers that throw InvalidOperationException instead of NotSupportedException.
            var trackedOrder = await _unitOfWork.Orders.Query().FirstOrDefaultAsync(o => o.Id == orderId);
            if (trackedOrder == null)
            {
                throw new KeyNotFoundException(
                    _localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
            }

            var trackedItems = await _unitOfWork.OrderItems.Query()
                .Where(oi => oi.OrderId == orderId)
                .ToListAsync();

            foreach (var item in trackedItems)
            {
                item.IsCancelled = true;
                item.CancelReason = dto.Reason;
                item.CancelledAt = now;
                _unitOfWork.OrderItems.Update(item);
            }

            trackedOrder.Status = OrderStatus.Cancelled;
            trackedOrder.CancelReason = dto.Reason;
            trackedOrder.CancelledAt = now;
            _unitOfWork.Orders.Update(trackedOrder);
        }

        // 3. Add History Record (Manual Insert)
        // Since we bypassed tracking/hooks, we need to add history manually
        await _unitOfWork.OrderStatusHistories.AddAsync(new OrderStatusHistory
        {
            OrderId = orderId,
            Status = OrderStatus.Cancelled,
            Note = $"Cancelled: {dto.Reason}",
            CreatedBy = userId,
            CreatedAt = now
        });

        await _unitOfWork.SaveChangesAsync();
        // --- BULK UPDATE LOGIC END ---

        // Notification logic remains the same, but we might need to fetch fresh data if needed
        // For notifications below, we use the 'order' object we fetched at the start.
        // It has the OLD status but correct ID, CustomerId, VendorId etc.

        // Add customer notification for cancellation
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            await AddCustomerNotificationAsync(
                order.CustomerId,
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledMessage", culture,
                    order.Id.ToString(), dto.Reason),
                "OrderCancelled",
                order.Id);

            // Send Firebase push notification to customer
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Cancelled",
                languageCode);
        }

        // Add vendor notification for cancellation
        var vendor = await _unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor != null)
        {
            await AddVendorNotificationAsync(
                order.VendorId,
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledByCustomerTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledByCustomerMessage", culture,
                    order.CustomerOrderId, dto.Reason),
                "OrderCancelledByCustomer",
                order.Id);

            // Send Firebase push notification to vendor
            if (!string.IsNullOrEmpty(vendor.OwnerId))
            {
                var languageCode = culture.TwoLetterISOLanguageName;
                await _notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "Cancelled",
                    languageCode);
            }
        }

        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Sipariş durumunu günceller
    /// </summary>
    public async Task<bool> UpdateOrderStatusAsync(Guid orderId, UpdateOrderStatusDto dto, string? userId,
        CultureInfo culture)
    {
        // Authorization: userId must be provided
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new UnauthorizedAccessException(
                _localizationService.GetLocalizedString(ResourceName, "Unauthorized", culture));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.StatusHistory)
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            throw new KeyNotFoundException(
                _localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
        }

        // Authorization: Check if user has permission to update order status
        // Vendor owner, assigned courier, or customer (for their own orders) can update
        var isVendorOwner = order.Vendor != null && order.Vendor.OwnerId == userId;
        var isCustomer = order.CustomerId == userId;

        // Check if user is assigned courier
        var isAssignedCourier = await _unitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Courier)
            .AnyAsync(oc => oc.OrderId == orderId &&
                            oc.Courier != null &&
                            oc.Courier.UserId == userId &&
                            oc.IsActive);

        if (!isVendorOwner && !isAssignedCourier && !isCustomer)
        {
            throw new UnauthorizedAccessException(
                _localizationService.GetLocalizedString(ResourceName, "Forbidden", culture));
        }

        // Parse status
        if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
        {
            throw new ArgumentException(
                _localizationService.GetLocalizedString(ResourceName, "InvalidStatus", culture));
        }

        // Validate status transition
        if (!IsValidStatusTransition(order.Status, newStatus))
        {
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName,
                "InvalidStatusTransition", culture, order.Status, newStatus));
        }

        // Update order status
        order.Status = newStatus;

        // Add to status history
        order.StatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = newStatus,
            Note = dto.Note,
            CreatedBy = userId
        });

        _unitOfWork.Orders.Update(order);
        await _unitOfWork.SaveChangesAsync();

        // Add customer notification for status change
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var statusMessage = newStatus switch
            {
                OrderStatus.Preparing => _localizationService.GetLocalizedString(ResourceName, "StatusPreparing",
                    culture),
                OrderStatus.Ready => _localizationService.GetLocalizedString(ResourceName, "StatusReady", culture),
                OrderStatus.Assigned =>
                    _localizationService.GetLocalizedString(ResourceName, "StatusAssigned", culture),
                OrderStatus.Accepted =>
                    _localizationService.GetLocalizedString(ResourceName, "StatusAccepted", culture),
                OrderStatus.OutForDelivery => _localizationService.GetLocalizedString(ResourceName,
                    "StatusOutForDelivery", culture),
                OrderStatus.Delivered => _localizationService.GetLocalizedString(ResourceName, "StatusDelivered",
                    culture),
                OrderStatus.Cancelled => _localizationService.GetLocalizedString(ResourceName, "StatusCancelled",
                    culture),
                _ => _localizationService.GetLocalizedString(ResourceName, "StatusUpdated", culture)
            };

            await AddCustomerNotificationAsync(
                order.CustomerId,
                _localizationService.GetLocalizedString(ResourceName, "OrderStatusChangedTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderStatusChangedMessage", culture,
                    order.CustomerOrderId, statusMessage),
                "OrderStatusChanged",
                order.Id);

            // Send Firebase push notification to customer
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, order.Id,
                newStatus.ToString(), languageCode);
        }

        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Satıcı bildirimi ekler
    /// </summary>
    private async Task AddVendorNotificationAsync(Guid vendorId, string title, string message, string type,
        Guid? relatedEntityId = null)
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
    private async Task AddCustomerNotificationAsync(string userId, string title, string message, string type,
        Guid? orderId = null)
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

    /// <summary>
    /// Geçerli durum geçişi kontrolü
    /// </summary>
    private static bool IsValidStatusTransition(OrderStatus current, OrderStatus next)
    {
        return current switch
        {
            OrderStatus.Pending => next is OrderStatus.Preparing or OrderStatus.Cancelled,
            OrderStatus.Preparing => next is OrderStatus.Ready or OrderStatus.Cancelled,
            OrderStatus.Ready => next is OrderStatus.Assigned or OrderStatus.Cancelled,
            OrderStatus.Assigned => next is OrderStatus.Accepted or OrderStatus.Cancelled,
            OrderStatus.Accepted => next is OrderStatus.OutForDelivery or OrderStatus.Cancelled,
            OrderStatus.OutForDelivery => next is OrderStatus.Delivered,
            _ => false
        };
    }


    /// <summary>
    /// Sipariş tutarlarını hesaplar
    /// </summary>
    public async Task<OrderCalculationResultDto> CalculateOrderAsync(CalculateOrderDto dto, string? userId,
        CultureInfo culture)
    {
        // 1. Validate vendor exists
        var vendor = await _unitOfWork.Vendors.GetByIdAsync(dto.VendorId);
        if (vendor == null)
        {
            throw new KeyNotFoundException(
                _localizationService.GetLocalizedString(ResourceName, "VendorNotFound", culture));
        }

        // 2. Calculate total and create item details
        decimal subtotal = 0;
        var calculationItems = new List<OrderItemCalculationDto>();
        // Keep track of RuleCartItems for validation context
        var ruleCartItems = new List<RuleValidationContext.RuleCartItem>();

        foreach (var item in dto.Items)
        {
            var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId);
            if (product == null)
            {
                // If product not found, we could throw or skip. Throwing ensures integrity.
                throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "ProductNotFound",
                    culture, item.ProductId));
            }

            decimal itemUnitPrice = product.Price;
            if (item.SelectedOptions != null)
            {
                foreach (var option in item.SelectedOptions)
                {
                    itemUnitPrice += option.PriceAdjustment;
                }
            }

            var lineTotal = itemUnitPrice * item.Quantity;
            subtotal += lineTotal;

            calculationItems.Add(new OrderItemCalculationDto
            {
                ProductId = item.ProductId,
                ProductName = product.Name,
                UnitPrice = itemUnitPrice,
                Quantity = item.Quantity,
                TotalPrice = lineTotal
            });

            ruleCartItems.Add(new RuleValidationContext.RuleCartItem
            {
                ProductId = product.Id,
                CategoryId = product.CategoryId,
                VendorId = product.VendorId,
                Quantity = item.Quantity,
                Price = product.Price,
                VendorType = (int)(product.VendorType ?? VendorType.Market)
            });
        }

        // 3. Calculate Delivery Fee and Validate Distance
        decimal deliveryFee = 0;

        // Fetch Base Delivery Fee
        var deliveryFeeStr = await _systemSettingsService.GetSettingAsync("DeliveryFee");
        if (!string.IsNullOrEmpty(deliveryFeeStr) && decimal.TryParse(deliveryFeeStr, NumberStyles.Any,
                CultureInfo.InvariantCulture, out var parsedFee))
        {
            deliveryFee = parsedFee;
        }

        // Apply Free Delivery Threshold
        var freeDeliveryThresholdStr = await _systemSettingsService.GetSettingAsync("FreeDeliveryThreshold");
        if (!string.IsNullOrEmpty(freeDeliveryThresholdStr) && decimal.TryParse(freeDeliveryThresholdStr,
                NumberStyles.Any, CultureInfo.InvariantCulture, out var threshold))
        {
            if (subtotal >= threshold)
            {
                deliveryFee = 0;
            }
        }

        // Validate Distance and Min Amount if address provided
        if (dto.DeliveryAddressId.HasValue)
        {
            var userAddress = await _unitOfWork.UserAddresses.GetByIdAsync(dto.DeliveryAddressId.Value);
            if (userAddress != null)
            {
                // Validate vendor and address locations are available
                if (!vendor.Latitude.HasValue || !vendor.Longitude.HasValue)
                {
                    throw new InvalidOperationException(
                        _localizationService.GetLocalizedString(ResourceName, "VendorLocationNotAvailable", culture));
                }

                if (!userAddress.Latitude.HasValue || !userAddress.Longitude.HasValue)
                {
                    throw new InvalidOperationException(
                        _localizationService.GetLocalizedString(ResourceName, "AddressLocationNotAvailable", culture));
                }

                // Distance and Radius Check (Crow-fly first)
                // DeliveryRadiusInKm = 0 ise, 5 km olarak kabul et (default)
                var deliveryRadius = vendor.DeliveryRadiusInKm == 0 ? 5 : vendor.DeliveryRadiusInKm;
                
                double crowFlyDistance = GeoHelper.CalculateDistance(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    userAddress.Latitude.Value,
                    userAddress.Longitude.Value
                );

                if (crowFlyDistance > deliveryRadius)
                {
                    throw new InvalidOperationException(
                        _localizationService.GetLocalizedString(ResourceName, "OutOfDeliveryRadius", culture));
                }

                // Router Check (Real Road Distance)
                double roadDistance = await _mapService.GetRoadDistanceAsync(
                    vendor.Latitude.Value,
                    vendor.Longitude.Value,
                    userAddress.Latitude.Value,
                    userAddress.Longitude.Value
                );

                double orderDistance = roadDistance > 0 ? roadDistance : crowFlyDistance;

                if (orderDistance > deliveryRadius)
                {
                    throw new InvalidOperationException(
                        _localizationService.GetLocalizedString(ResourceName, "OutOfDeliveryRadius", culture));
                }

                // Dynamic Minimum Order Amount Check
                decimal dynamicMinAmount = vendor.MinimumOrderAmount ?? 0;
                if (orderDistance > 5)
                {
                    dynamicMinAmount = Math.Max(dynamicMinAmount, 300.00m);
                }
                else if (orderDistance > 2)
                {
                    dynamicMinAmount = Math.Max(dynamicMinAmount, 200.00m);
                }

                if (subtotal < dynamicMinAmount)
                {
                    throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName,
                        "MinimumOrderAmountNotMet", culture, dynamicMinAmount));
                }
            }
        }

        // 4. Validate and Apply Promotions
        decimal discountAmount = 0;
        CouponDto? appliedCouponDto = null;
        Guid? appliedCampaignId = null;

        // Shared Validation Context Construction
        Guid? userCityId = null;
        Guid? userDistrictId = null;

        if (dto.DeliveryAddressId.HasValue)
        {
            var userAddress = await _unitOfWork.UserAddresses.GetByIdAsync(dto.DeliveryAddressId.Value);
            if (userAddress != null)
            {
                userCityId = userAddress.CityId;
                userDistrictId = userAddress.DistrictId;
            }
        }

        Guid.TryParse(userId, out var userIdGuid);

        var validationContext = new RuleValidationContext
        {
            UserId = userIdGuid != Guid.Empty ? userIdGuid : null,
            CityId = userCityId,
            DistrictId = userDistrictId,
            RequestTime = DateTime.UtcNow,
            Items = ruleCartItems,
            CartTotal = subtotal,
            IsFirstOrder = userId != null && !await _unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == userId)
        };

        // Coupon Logic
        if (!string.IsNullOrEmpty(dto.CouponCode))
        {
            var coupon = await _unitOfWork.Coupons.Query()
                .AsNoTracking()
                .Include(c => c.CouponCities)
                .Include(c => c.CouponDistricts)
                .Include(c => c.CouponCategories)
                .Include(c => c.CouponProducts)
                .FirstOrDefaultAsync(c => c.Code == dto.CouponCode && c.IsActive);

            if (coupon != null)
            {
                if (_ruleValidatorService.ValidateCoupon(coupon, validationContext, out var _))
                {
                    if (coupon.DiscountType == DiscountType.Percentage)
                    {
                        discountAmount = subtotal * (coupon.DiscountValue / 100);
                    }
                    else
                    {
                        discountAmount = coupon.DiscountValue;
                    }

                    if (discountAmount > subtotal) discountAmount = subtotal;

                    appliedCouponDto = new CouponDto
                    {
                        Id = coupon.Id,
                        Code = coupon.Code,
                        DiscountType = (int)coupon.DiscountType,
                        DiscountValue = coupon.DiscountValue,
                        DiscountAmount = discountAmount,
                        Description = coupon.Description ?? ""
                    };
                }
            }
        }

        // Campaign Logic
        if (dto.CampaignId.HasValue)
        {
            var campaign = await _unitOfWork.Campaigns.Query()
                .AsNoTracking()
                .Include(c => c.CampaignCities)
                .Include(c => c.CampaignDistricts)
                .Include(c => c.CampaignCategories)
                .Include(c => c.CampaignProducts)
                .FirstOrDefaultAsync(c => c.Id == dto.CampaignId.Value && c.IsActive);

            if (campaign != null)
            {
                if (_ruleValidatorService.ValidateCampaign(campaign, validationContext, out var _))
                {
                    decimal campaignDiscount;
                    if (campaign.DiscountType == DiscountType.Percentage)
                    {
                        campaignDiscount = subtotal * (campaign.DiscountValue / 100);
                    }
                    else
                    {
                        campaignDiscount = campaign.DiscountValue;
                    }

                    if (campaignDiscount > subtotal) campaignDiscount = subtotal;

                    // Campaign overrides coupon if explicitly selected and valid (or better specific logic)
                    // Here: If Campaign provides a discount, we use it and verify vs coupon
                    if (campaignDiscount > 0)
                    {
                        if (campaignDiscount >= discountAmount)
                        {
                            discountAmount = campaignDiscount;
                            appliedCampaignId = campaign.Id;
                            appliedCouponDto = null;
                        }
                    }
                }
            }
        }

        // Final Totals
        // Discount is applied to subtotal
        var finalSubtotal = subtotal - discountAmount;
        if (finalSubtotal < 0) finalSubtotal = 0;

        var totalAmount = finalSubtotal + deliveryFee;

        return new OrderCalculationResultDto
        {
            Subtotal = subtotal,
            DeliveryFee = deliveryFee,
            DiscountAmount = discountAmount,
            TotalAmount = totalAmount,
            AppliedCoupon = appliedCouponDto,
            AppliedCampaignId = appliedCampaignId,
            Items = calculationItems
        };
    }
}

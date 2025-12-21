using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Sipariş işlemleri için service implementation
/// </summary>
public class OrderService : IOrderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<OrderService> _logger;
    private readonly ILocalizationService _localizationService;
    private readonly INotificationService _notificationService;
    private readonly IRuleValidatorService _ruleValidatorService;
    private const string ResourceName = "OrderResources";

    public OrderService(
        IUnitOfWork unitOfWork,
        ILogger<OrderService> logger,
        ILocalizationService localizationService,
        INotificationService notificationService,
        IRuleValidatorService ruleValidatorService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _localizationService = localizationService;
        _notificationService = notificationService;
        _ruleValidatorService = ruleValidatorService;
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
            isUnique = !await _unitOfWork.OrderItems.Query().AnyAsync(oi => oi.CustomerOrderItemId == customerOrderItemId);
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
            throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "VendorNotFound", culture));
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
                throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "ProductNotFound", culture, item.ProductId));
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

        // 3. Validate Delivery Address and Zone
        if (!dto.DeliveryAddressId.HasValue)
        {
            throw new ArgumentException(_localizationService.GetLocalizedString(ResourceName, "AddressRequired", culture));
        }

        var userAddress = await _unitOfWork.UserAddresses.GetByIdAsync(dto.DeliveryAddressId.Value);
        if (userAddress == null)
        {
            throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "AddressNotFound", culture));
        }

        // Check Delivery Zone
        var deliveryZone = await _unitOfWork.VendorDeliveryZones.Query()
            .FirstOrDefaultAsync(z => z.VendorId == dto.VendorId && z.DistrictId == userAddress.DistrictId && z.IsActive);

        if (deliveryZone == null)
        {
             throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "OutOfDeliveryZone", culture));
        }

        if (totalAmount < deliveryZone.MinimumOrderAmount)
        {
             throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "MinimumOrderAmountNotMet", culture, deliveryZone.MinimumOrderAmount));
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
            TotalAmount = finalAmount + deliveryZone.DeliveryFee.GetValueOrDefault(), // Add Delivery Fee to FINAL amount
            DeliveryFee = deliveryZone.DeliveryFee.GetValueOrDefault(),
            Status = OrderStatus.Pending,
            OrderItems = orderItems,
            CreatedAt = DateTime.UtcNow,
            DeliveryAddressId = dto.DeliveryAddressId,
            // New Fields
            CouponId = appliedCoupon?.Id,
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
            _localizationService.GetLocalizedString(ResourceName, "NewOrderMessage", culture, order.CustomerOrderId, order.TotalAmount.ToString("N2")),
            "NewOrder",
            order.Id);

        // Send Firebase push notification to vendor
        if (vendor != null && !string.IsNullOrEmpty(vendor.OwnerId))
        {
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, order.Id, "Pending", languageCode);
        }

        // Add customer notification
        if (customerId != "anonymous")
        {
            await AddCustomerNotificationAsync(
                customerId,
                _localizationService.GetLocalizedString(ResourceName, "OrderCreatedTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCreatedMessage", culture, order.CustomerOrderId, order.TotalAmount.ToString("N2")),
                "OrderCreated",
                order.Id);

            // Send Firebase push notification to customer
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(customerId, order.Id, "Pending", languageCode);
        }

        await _unitOfWork.SaveChangesAsync();

        return order;
    }

    /// <summary>
    /// Siparişi iptal eder
    /// </summary>
    public async Task<bool> CancelOrderAsync(Guid orderId, string? userId, CancelOrderDto dto, CultureInfo culture)
    {
        // Authorization: userId must be provided
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new UnauthorizedAccessException(_localizationService.GetLocalizedString(ResourceName, "Unauthorized", culture));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.StatusHistory)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
        }

        // Authorization: Only the customer who owns the order can cancel it
        if (order.CustomerId != userId)
        {
            throw new UnauthorizedAccessException(_localizationService.GetLocalizedString(ResourceName, "Forbidden", culture));
        }

        // Check if order can be cancelled
        if (order.Status == OrderStatus.Delivered || order.Status == OrderStatus.Cancelled)
        {
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "OrderCannotBeCancelled", culture));
        }

        // Customers can only cancel Pending or Preparing orders
        var isCustomer = order.CustomerId == userId;
        if (isCustomer && order.Status != OrderStatus.Pending && order.Status != OrderStatus.Preparing)
        {
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "InvalidCancellationStatus", culture));
        }

        // Validate reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Length < 10)
        {
            throw new ArgumentException(_localizationService.GetLocalizedString(ResourceName, "InvalidCancellationReason", culture));
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
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledMessage", culture, order.Id.ToString(), dto.Reason),
                "OrderCancelled",
                order.Id);

            // Send Firebase push notification to customer
            var languageCode = culture.TwoLetterISOLanguageName;
            await _notificationService.SendOrderStatusUpdateNotificationAsync(order.CustomerId, orderId, "Cancelled", languageCode);
        }

        // Add vendor notification for cancellation
        var vendor = await _unitOfWork.Vendors.GetByIdAsync(order.VendorId);
        if (vendor != null)
        {
            await AddVendorNotificationAsync(
                order.VendorId,
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledByCustomerTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderCancelledByCustomerMessage", culture, order.CustomerOrderId, dto.Reason),
                "OrderCancelledByCustomer",
                order.Id);

            // Send Firebase push notification to vendor
            if (!string.IsNullOrEmpty(vendor.OwnerId))
            {
                var languageCode = culture.TwoLetterISOLanguageName;
                await _notificationService.SendOrderStatusUpdateNotificationAsync(vendor.OwnerId, orderId, "Cancelled", languageCode);
            }
        }

        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Sipariş durumunu günceller
    /// </summary>
    public async Task<bool> UpdateOrderStatusAsync(Guid orderId, UpdateOrderStatusDto dto, string? userId, CultureInfo culture)
    {
        // Authorization: userId must be provided
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new UnauthorizedAccessException(_localizationService.GetLocalizedString(ResourceName, "Unauthorized", culture));
        }

        var order = await _unitOfWork.Orders.Query()
            .Include(o => o.StatusHistory)
            .Include(o => o.Vendor)
            .FirstOrDefaultAsync(o => o.Id == orderId);

        if (order == null)
        {
            throw new KeyNotFoundException(_localizationService.GetLocalizedString(ResourceName, "OrderNotFound", culture));
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
            throw new UnauthorizedAccessException(_localizationService.GetLocalizedString(ResourceName, "Forbidden", culture));
        }

        // Parse status
        if (!Enum.TryParse<OrderStatus>(dto.Status, out var newStatus))
        {
            throw new ArgumentException(_localizationService.GetLocalizedString(ResourceName, "InvalidStatus", culture));
        }

        // Validate status transition
        if (!IsValidStatusTransition(order.Status, newStatus))
        {
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "InvalidStatusTransition", culture, order.Status, newStatus));
        }

        // Update order status
        order.Status = newStatus;

        // Add to status history
        order.StatusHistory.Add(new OrderStatusHistory
        {
            OrderId = order.Id,
            Status = newStatus,
            Note = dto.Note,
            CreatedBy = userId ?? "System"
        });

        _unitOfWork.Orders.Update(order);
        await _unitOfWork.SaveChangesAsync();

        // Add customer notification for status change
        if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        {
            var statusMessage = newStatus switch
            {
                OrderStatus.Preparing => _localizationService.GetLocalizedString(ResourceName, "StatusPreparing", culture),
                OrderStatus.Ready => _localizationService.GetLocalizedString(ResourceName, "StatusReady", culture),
                OrderStatus.Assigned => _localizationService.GetLocalizedString(ResourceName, "StatusAssigned", culture),
                OrderStatus.Accepted => _localizationService.GetLocalizedString(ResourceName, "StatusAccepted", culture),
                OrderStatus.OutForDelivery => _localizationService.GetLocalizedString(ResourceName, "StatusOutForDelivery", culture),
                OrderStatus.Delivered => _localizationService.GetLocalizedString(ResourceName, "StatusDelivered", culture),
                OrderStatus.Cancelled => _localizationService.GetLocalizedString(ResourceName, "StatusCancelled", culture),
                _ => _localizationService.GetLocalizedString(ResourceName, "StatusUpdated", culture)
            };

            await AddCustomerNotificationAsync(
                order.CustomerId,
                _localizationService.GetLocalizedString(ResourceName, "OrderStatusChangedTitle", culture),
                _localizationService.GetLocalizedString(ResourceName, "OrderStatusChangedMessage", culture, order.CustomerOrderId, statusMessage),
                "OrderStatusChanged",
                order.Id);
        }

        await _unitOfWork.SaveChangesAsync();

        return true;
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
            OrderStatus.Delivered => false,
            OrderStatus.Cancelled => false,
            _ => false
        };
    }
}


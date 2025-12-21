using Microsoft.EntityFrameworkCore.Storage;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Repositories;

/// <summary>
/// Unit of Work pattern implementation - Tüm repository'leri ve transaction yönetimini sağlar
/// </summary>
public class UnitOfWork : IUnitOfWork
{
    private readonly TalabiDbContext _context;
    private IDbContextTransaction? _transaction;

    // Repository instances (lazy initialization)
    private IRepository<Order>? _orders;
    private IRepository<Product>? _products;
    private IRepository<Vendor>? _vendors;
    private IRepository<Category>? _categories;
    private IRepository<CategoryTranslation>? _categoryTranslations;
    private IRepository<OrderItem>? _orderItems;
    private IRepository<OrderCourier>? _orderCouriers;
    private IRepository<Cart>? _carts;
    private IRepository<CartItem>? _cartItems;
    private IRepository<UserAddress>? _userAddresses;
    private IRepository<FavoriteProduct>? _favoriteProducts;
    private IRepository<NotificationSettings>? _notificationSettings;
    private IRepository<OrderStatusHistory>? _orderStatusHistories;
    private IRepository<Courier>? _couriers;
    private IRepository<CourierNotification>? _courierNotifications;
    private IRepository<VendorNotification>? _vendorNotifications;
    private IRepository<CustomerNotification>? _customerNotifications;
    private IRepository<UserPreferences>? _userPreferences;
    private IRepository<Review>? _reviews;
    private IRepository<DeliveryProof>? _deliveryProofs;
    private IRepository<CourierEarning>? _courierEarnings;
    private IRepository<Customer>? _customers;
    private IRepository<LegalDocument>? _legalDocuments;
    private IRepository<UserActivityLog>? _userActivityLogs;
    private IRepository<UserDeviceToken>? _userDeviceTokens;
    private IRepository<PromotionalBanner>? _promotionalBanners;
    private IRepository<PromotionalBannerTranslation>? _promotionalBannerTranslations;
    private IRepository<ErrorLog>? _errorLogs;
    private IRepository<VendorDeliveryZone>? _vendorDeliveryZones;
    private IRepository<CourierWorkingHour>? _courierWorkingHours;
    private IRepository<VendorWorkingHour>? _vendorWorkingHours;
    private IRepository<Coupon>? _coupons;
    private IRepository<Campaign>? _campaigns;
    private IRepository<City>? _cities;
    private IRepository<District>? _districts;


    /// <summary>
    /// UnitOfWork constructor
    /// </summary>
    /// <param name="context">DbContext instance</param>
    public UnitOfWork(TalabiDbContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }

    /// <summary>
    /// Order entity'leri için repository
    /// </summary>
    public IRepository<Order> Orders => _orders ??= new Repository<Order>(_context);

    /// <summary>
    /// Product entity'leri için repository
    /// </summary>
    public IRepository<Product> Products => _products ??= new Repository<Product>(_context);

    /// <summary>
    /// Vendor entity'leri için repository
    /// </summary>
    public IRepository<Vendor> Vendors => _vendors ??= new Repository<Vendor>(_context);

    /// <summary>
    /// Category entity'leri için repository
    /// </summary>
    public IRepository<Category> Categories => _categories ??= new Repository<Category>(_context);

    /// <summary>
    /// CategoryTranslation entity'leri için repository
    /// </summary>
    public IRepository<CategoryTranslation> CategoryTranslations => _categoryTranslations ??= new Repository<CategoryTranslation>(_context);

    /// <summary>
    /// OrderItem entity'leri için repository
    /// </summary>
    public IRepository<OrderItem> OrderItems => _orderItems ??= new Repository<OrderItem>(_context);

    /// <summary>
    /// OrderCourier entity'leri için repository
    /// </summary>
    public IRepository<OrderCourier> OrderCouriers => _orderCouriers ??= new Repository<OrderCourier>(_context);

    /// <summary>
    /// Cart entity'leri için repository
    /// </summary>
    public IRepository<Cart> Carts => _carts ??= new Repository<Cart>(_context);

    /// <summary>
    /// CartItem entity'leri için repository
    /// </summary>
    public IRepository<CartItem> CartItems => _cartItems ??= new Repository<CartItem>(_context);

    /// <summary>
    /// UserAddress entity'leri için repository
    /// </summary>
    public IRepository<UserAddress> UserAddresses => _userAddresses ??= new Repository<UserAddress>(_context);

    /// <summary>
    /// FavoriteProduct entity'leri için repository
    /// </summary>
    public IRepository<FavoriteProduct> FavoriteProducts => _favoriteProducts ??= new Repository<FavoriteProduct>(_context);

    /// <summary>
    /// NotificationSettings entity'leri için repository
    /// </summary>
    public IRepository<NotificationSettings> NotificationSettings => _notificationSettings ??= new Repository<NotificationSettings>(_context);

    /// <summary>
    /// OrderStatusHistory entity'leri için repository
    /// </summary>
    public IRepository<OrderStatusHistory> OrderStatusHistories => _orderStatusHistories ??= new Repository<OrderStatusHistory>(_context);

    /// <summary>
    /// Courier entity'leri için repository
    /// </summary>
    public IRepository<Courier> Couriers => _couriers ??= new Repository<Courier>(_context);

    /// <summary>
    /// CourierNotification entity'leri için repository
    /// </summary>
    public IRepository<CourierNotification> CourierNotifications => _courierNotifications ??= new Repository<CourierNotification>(_context);

    /// <summary>
    /// VendorNotification entity'leri için repository
    /// </summary>
    public IRepository<VendorNotification> VendorNotifications => _vendorNotifications ??= new Repository<VendorNotification>(_context);

    /// <summary>
    /// CustomerNotification entity'leri için repository
    /// </summary>
    public IRepository<CustomerNotification> CustomerNotifications => _customerNotifications ??= new Repository<CustomerNotification>(_context);

    /// <summary>
    /// UserPreferences entity'leri için repository
    /// </summary>
    public IRepository<UserPreferences> UserPreferences => _userPreferences ??= new Repository<UserPreferences>(_context);

    /// <summary>
    /// Review entity'leri için repository
    /// </summary>
    public IRepository<Review> Reviews => _reviews ??= new Repository<Review>(_context);

    /// <summary>
    /// DeliveryProof entity'leri için repository
    /// </summary>
    public IRepository<DeliveryProof> DeliveryProofs => _deliveryProofs ??= new Repository<DeliveryProof>(_context);

    /// <summary>
    /// CourierEarning entity'leri için repository
    /// </summary>
    public IRepository<CourierEarning> CourierEarnings => _courierEarnings ??= new Repository<CourierEarning>(_context);

    /// <summary>
    /// Customer entity'leri için repository
    /// </summary>
    public IRepository<Customer> Customers => _customers ??= new Repository<Customer>(_context);

    /// <summary>
    /// LegalDocument entity'leri için repository
    /// </summary>
    public IRepository<LegalDocument> LegalDocuments => _legalDocuments ??= new Repository<LegalDocument>(_context);

    /// <summary>
    /// UserActivityLog entity'leri için repository
    /// </summary>
    public IRepository<UserActivityLog> UserActivityLogs => _userActivityLogs ??= new Repository<UserActivityLog>(_context);

    /// <summary>
    /// UserDeviceToken entity'leri için repository
    /// </summary>
    public IRepository<UserDeviceToken> UserDeviceTokens => _userDeviceTokens ??= new Repository<UserDeviceToken>(_context);

    /// <summary>
    /// PromotionalBanner entity'leri için repository
    /// </summary>
    public IRepository<PromotionalBanner> PromotionalBanners => _promotionalBanners ??= new Repository<PromotionalBanner>(_context);

    /// <summary>
    /// PromotionalBannerTranslation entity'leri için repository
    /// </summary>
    public IRepository<PromotionalBannerTranslation> PromotionalBannerTranslations => _promotionalBannerTranslations ??= new Repository<PromotionalBannerTranslation>(_context);

    /// <summary>
    /// ErrorLog entity'leri için repository
    /// </summary>
    public IRepository<ErrorLog> ErrorLogs => _errorLogs ??= new Repository<ErrorLog>(_context);

    /// <summary>
    /// VendorDeliveryZone entity'leri için repository
    /// </summary>
    public IRepository<VendorDeliveryZone> VendorDeliveryZones => _vendorDeliveryZones ??= new Repository<VendorDeliveryZone>(_context);

    /// <summary>
    /// CourierWorkingHour entity'leri için repository
    /// </summary>
    public IRepository<CourierWorkingHour> CourierWorkingHours => _courierWorkingHours ??= new Repository<CourierWorkingHour>(_context);

    /// <summary>
    /// VendorWorkingHour entity'leri için repository
    /// </summary>
    public IRepository<VendorWorkingHour> VendorWorkingHours => _vendorWorkingHours ??= new Repository<VendorWorkingHour>(_context);

    /// <summary>
    /// Coupon entity'leri için repository
    /// </summary>
    public IRepository<Coupon> Coupons => _coupons ??= new Repository<Coupon>(_context);

    /// <summary>
    /// Campaign entity'leri için repository
    /// </summary>
    public IRepository<Campaign> Campaigns => _campaigns ??= new Repository<Campaign>(_context);

    /// <summary>
    /// City entity'leri için repository
    /// </summary>
    public IRepository<City> Cities => _cities ??= new Repository<City>(_context);

    /// <summary>
    /// District entity'leri için repository
    /// </summary>
    public IRepository<District> Districts => _districts ??= new Repository<District>(_context);


    /// <summary>
    /// Tüm değişiklikleri asenkron olarak veritabanına kaydeder
    /// </summary>
    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    /// <summary>
    /// Tüm değişiklikleri senkron olarak veritabanına kaydeder
    /// </summary>
    public int SaveChanges()
    {
        return _context.SaveChanges();
    }

    /// <summary>
    /// Yeni bir transaction başlatır
    /// </summary>
    public async Task BeginTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction != null)
        {
            throw new InvalidOperationException("Zaten aktif bir transaction mevcut.");
        }

        _transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
    }

    /// <summary>
    /// Aktif transaction'ı commit eder
    /// </summary>
    public async Task CommitTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction == null)
        {
            throw new InvalidOperationException("Aktif bir transaction bulunamadı.");
        }

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
            await _transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await RollbackTransactionAsync(cancellationToken);
            throw;
        }
        finally
        {
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    /// <summary>
    /// Aktif transaction'ı rollback eder
    /// </summary>
    public async Task RollbackTransactionAsync(CancellationToken cancellationToken = default)
    {
        if (_transaction == null)
        {
            return; // Transaction yoksa sessizce çık
        }

        try
        {
            await _transaction.RollbackAsync(cancellationToken);
        }
        finally
        {
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    /// <summary>
    /// Resources'ları temizler
    /// </summary>
    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}


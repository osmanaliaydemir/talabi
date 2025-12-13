using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

/// <summary>
/// Unit of Work pattern interface'i - Tüm repository'leri ve transaction yönetimini kapsar
/// </summary>
public interface IUnitOfWork : IDisposable
{
    /// <summary>
    /// Order entity'leri için repository
    /// </summary>
    IRepository<Order> Orders { get; }

    /// <summary>
    /// Product entity'leri için repository
    /// </summary>
    IRepository<Product> Products { get; }

    /// <summary>
    /// Vendor entity'leri için repository
    /// </summary>
    IRepository<Vendor> Vendors { get; }

    /// <summary>
    /// Category entity'leri için repository
    /// </summary>
    IRepository<Category> Categories { get; }

    /// <summary>
    /// CategoryTranslation entity'leri için repository
    /// </summary>
    IRepository<CategoryTranslation> CategoryTranslations { get; }

    /// <summary>
    /// OrderItem entity'leri için repository
    /// </summary>
    IRepository<OrderItem> OrderItems { get; }

    /// <summary>
    /// OrderCourier entity'leri için repository
    /// </summary>
    IRepository<OrderCourier> OrderCouriers { get; }

    /// <summary>
    /// Cart entity'leri için repository
    /// </summary>
    IRepository<Cart> Carts { get; }

    /// <summary>
    /// CartItem entity'leri için repository
    /// </summary>
    IRepository<CartItem> CartItems { get; }

    /// <summary>
    /// UserAddress entity'leri için repository
    /// </summary>
    IRepository<UserAddress> UserAddresses { get; }

    /// <summary>
    /// FavoriteProduct entity'leri için repository
    /// </summary>
    IRepository<FavoriteProduct> FavoriteProducts { get; }

    /// <summary>
    /// NotificationSettings entity'leri için repository
    /// </summary>
    IRepository<NotificationSettings> NotificationSettings { get; }

    /// <summary>
    /// OrderStatusHistory entity'leri için repository
    /// </summary>
    IRepository<OrderStatusHistory> OrderStatusHistories { get; }

    /// <summary>
    /// Courier entity'leri için repository
    /// </summary>
    IRepository<Courier> Couriers { get; }

    /// <summary>
    /// CourierNotification entity'leri için repository
    /// </summary>
    IRepository<CourierNotification> CourierNotifications { get; }

    /// <summary>
    /// VendorNotification entity'leri için repository
    /// </summary>
    IRepository<VendorNotification> VendorNotifications { get; }

    /// <summary>
    /// CustomerNotification entity'leri için repository
    /// </summary>
    IRepository<CustomerNotification> CustomerNotifications { get; }

    /// <summary>
    /// UserPreferences entity'leri için repository
    /// </summary>
    IRepository<UserPreferences> UserPreferences { get; }

    /// <summary>
    /// Review entity'leri için repository
    /// </summary>
    IRepository<Review> Reviews { get; }

    /// <summary>
    /// DeliveryProof entity'leri için repository
    /// </summary>
    IRepository<DeliveryProof> DeliveryProofs { get; }

    /// <summary>
    /// CourierEarning entity'leri için repository
    /// </summary>
    IRepository<CourierEarning> CourierEarnings { get; }

    /// <summary>
    /// Customer entity'leri için repository
    /// </summary>
    IRepository<Customer> Customers { get; }

    /// <summary>
    /// LegalDocument entity'leri için repository
    /// </summary>
    IRepository<LegalDocument> LegalDocuments { get; }

    /// <summary>
    /// UserActivityLog entity'leri için repository
    /// </summary>
    IRepository<UserActivityLog> UserActivityLogs { get; }

    /// <summary>
    /// UserDeviceToken entity'leri için repository
    /// </summary>
    IRepository<UserDeviceToken> UserDeviceTokens { get; }

    /// <summary>
    /// PromotionalBanner entity'leri için repository
    /// </summary>
    IRepository<PromotionalBanner> PromotionalBanners { get; }

    /// <summary>
    /// PromotionalBannerTranslation entity'leri için repository
    /// </summary>
    IRepository<PromotionalBannerTranslation> PromotionalBannerTranslations { get; }

    /// <summary>
    /// ErrorLog entity'leri için repository
    /// </summary>
    IRepository<ErrorLog> ErrorLogs { get; }

    /// <summary>
    /// VendorDeliveryZone entity'leri için repository
    /// </summary>
    IRepository<VendorDeliveryZone> VendorDeliveryZones { get; }


    /// <summary>
    /// Tüm değişiklikleri asenkron olarak veritabanına kaydeder
    /// </summary>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Etkilenen satır sayısı</returns>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Tüm değişiklikleri senkron olarak veritabanına kaydeder
    /// </summary>
    /// <returns>Etkilenen satır sayısı</returns>
    int SaveChanges();

    /// <summary>
    /// Yeni bir transaction başlatır
    /// </summary>
    /// <param name="cancellationToken">İptal token'ı</param>
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Aktif transaction'ı commit eder
    /// </summary>
    /// <param name="cancellationToken">İptal token'ı</param>
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Aktif transaction'ı rollback eder
    /// </summary>
    /// <param name="cancellationToken">İptal token'ı</param>
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
}


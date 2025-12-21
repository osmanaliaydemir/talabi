using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;

namespace Talabi.Infrastructure.Data;

public class TalabiDbContext : IdentityDbContext<AppUser>
{
    public TalabiDbContext(DbContextOptions<TalabiDbContext> options) : base(options)
    {
    }

    public DbSet<Vendor> Vendors { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Category> Categories { get; set; }
    public DbSet<CategoryTranslation> CategoryTranslations { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<OrderCourier> OrderCouriers { get; set; }
    public DbSet<Cart> Carts { get; set; }
    public DbSet<CartItem> CartItems { get; set; }
    public DbSet<UserAddress> UserAddresses { get; set; }
    public DbSet<FavoriteProduct> FavoriteProducts { get; set; }
    public DbSet<NotificationSettings> NotificationSettings { get; set; }
    public DbSet<OrderStatusHistory> OrderStatusHistories { get; set; }
    public DbSet<Courier> Couriers { get; set; }
    public DbSet<CourierNotification> CourierNotifications { get; set; }
    public DbSet<VendorNotification> VendorNotifications { get; set; }
    public DbSet<CustomerNotification> CustomerNotifications { get; set; }
    public DbSet<UserPreferences> UserPreferences { get; set; }
    public DbSet<Review> Reviews { get; set; }
    public DbSet<DeliveryProof> DeliveryProofs { get; set; }
    public DbSet<CourierEarning> CourierEarnings { get; set; }
    public DbSet<Customer> Customers { get; set; }
    public DbSet<LegalDocument> LegalDocuments { get; set; }
    public DbSet<UserActivityLog> UserActivityLogs { get; set; }
    public DbSet<UserDeviceToken> UserDeviceTokens { get; set; }
    public DbSet<PromotionalBanner> PromotionalBanners { get; set; }
    public DbSet<PromotionalBannerTranslation> PromotionalBannerTranslations { get; set; }
    public DbSet<ErrorLog> ErrorLogs { get; set; }
    public DbSet<VendorDeliveryZone> VendorDeliveryZones { get; set; }
    public DbSet<CourierDeliveryZone> CourierDeliveryZones { get; set; }
    public DbSet<Country> Countries { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<District> Districts { get; set; }
    public DbSet<Locality> Localities { get; set; }
    public DbSet<VendorWorkingHour> VendorWorkingHours { get; set; }
    public DbSet<CourierWorkingHour> CourierWorkingHours { get; set; }
    public DbSet<Coupon> Coupons { get; set; }
    public DbSet<Campaign> Campaigns { get; set; }

    // Advanced Rules Relations
    public DbSet<CampaignCity> CampaignCities { get; set; }
    public DbSet<CampaignDistrict> CampaignDistricts { get; set; }
    public DbSet<CampaignCategory> CampaignCategories { get; set; }
    public DbSet<CampaignProduct> CampaignProducts { get; set; }
    public DbSet<CouponCity> CouponCities { get; set; }
    public DbSet<CouponDistrict> CouponDistricts { get; set; }
    public DbSet<CouponCategory> CouponCategories { get; set; }
    public DbSet<CouponProduct> CouponProducts { get; set; }


    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateTimestamps();
        return base.SaveChangesAsync(cancellationToken);
    }

    public override int SaveChanges()
    {
        UpdateTimestamps();
        return base.SaveChanges();
    }

    private void UpdateTimestamps()
    {
        var entries = ChangeTracker.Entries()
            .Where(e => e.Entity is BaseEntity && (e.State == EntityState.Added || e.State == EntityState.Modified));

        foreach (var entry in entries)
        {
            var entity = (BaseEntity)entry.Entity;

            if (entry.State == EntityState.Added)
            {
                entity.CreatedAt = DateTime.UtcNow;
                entity.UpdatedAt = DateTime.UtcNow;
            }
            else if (entry.State == EntityState.Modified)
            {
                entity.UpdatedAt = DateTime.UtcNow;
            }
        }
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Additional configuration if needed
        builder.Entity<Product>()
            .Property(p => p.Price)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Category>()
            .HasMany(c => c.Products)
            .WithOne(p => p.ProductCategory)
            .HasForeignKey(p => p.CategoryId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.Entity<CategoryTranslation>()
            .HasOne(ct => ct.Category)
            .WithMany(c => c.Translations)
            .HasForeignKey(ct => ct.CategoryId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint for Category + Language
        builder.Entity<CategoryTranslation>()
            .HasIndex(ct => new { ct.CategoryId, ct.LanguageCode })
            .IsUnique();

        // PromotionalBannerTranslation configuration
        builder.Entity<PromotionalBannerTranslation>()
            .HasOne(pbt => pbt.PromotionalBanner)
            .WithMany(pb => pb.Translations)
            .HasForeignKey(pbt => pbt.PromotionalBannerId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint for PromotionalBanner + Language
        builder.Entity<PromotionalBannerTranslation>()
            .HasIndex(pbt => new { pbt.PromotionalBannerId, pbt.LanguageCode })
            .IsUnique();

        builder.Entity<Order>()
            .Property(o => o.TotalAmount)
            .HasColumnType("decimal(18,2)");

        builder.Entity<OrderItem>()
            .Property(oi => oi.UnitPrice)
            .HasColumnType("decimal(18,2)");

        // OrderItem - Order relationship
        builder.Entity<OrderItem>()
            .HasOne(oi => oi.Order)
            .WithMany(o => o.OrderItems)
            .HasForeignKey(oi => oi.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        // OrderItem - Product relationship
        builder.Entity<OrderItem>()
            .HasOne(oi => oi.Product)
            .WithMany()
            .HasForeignKey(oi => oi.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        // Vendor configuration
        builder.Entity<Vendor>()
            .Property(v => v.Rating)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Vendor>()
            .Property(v => v.DeliveryFee)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Vendor>()
            .Property(v => v.MinimumOrderAmount)
            .HasColumnType("decimal(18,2)");

        // Fix for: Introducing FOREIGN KEY constraint ... may cause cycles or multiple cascade paths.
        builder.Entity<Order>()
            .HasOne(o => o.Vendor)
            .WithMany(v => v.Orders)
            .HasForeignKey(o => o.VendorId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Order>()
            .HasOne(o => o.Customer)
            .WithMany()
            .HasForeignKey(o => o.CustomerId)
            .OnDelete(DeleteBehavior.Restrict);

        // Cart configuration
        builder.Entity<Cart>()
            .HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CartItem>()
            .HasOne(ci => ci.Cart)
            .WithMany(c => c.CartItems)
            .HasForeignKey(ci => ci.CartId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CartItem>()
            .HasOne(ci => ci.Product)
            .WithMany()
            .HasForeignKey(ci => ci.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        // UserAddress configuration
        builder.Entity<UserAddress>()
            .HasOne(ua => ua.User)
            .WithMany()
            .HasForeignKey(ua => ua.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // FavoriteProduct configuration
        builder.Entity<FavoriteProduct>()
            .HasOne(fp => fp.User)
            .WithMany()
            .HasForeignKey(fp => fp.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<FavoriteProduct>()
            .HasOne(fp => fp.Product)
            .WithMany()
            .HasForeignKey(fp => fp.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        // Unique constraint: user can favorite a product only once
        builder.Entity<FavoriteProduct>()
            .HasIndex(fp => new { fp.UserId, fp.ProductId })
            .IsUnique();

        // NotificationSettings configuration
        builder.Entity<NotificationSettings>()
            .HasOne(ns => ns.User)
            .WithMany()
            .HasForeignKey(ns => ns.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint: one settings per user
        builder.Entity<NotificationSettings>()
            .HasIndex(ns => ns.UserId)
            .IsUnique();

        // OrderStatusHistory configuration
        builder.Entity<OrderStatusHistory>()
            .HasOne(osh => osh.Order)
            .WithMany(o => o.StatusHistory)
            .HasForeignKey(osh => osh.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        // Courier configuration
        builder.Entity<Courier>()
            .HasOne(c => c.User)
            .WithMany()
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<CourierNotification>()
            .HasOne(cn => cn.Courier)
            .WithMany(c => c.Notifications)
            .HasForeignKey(cn => cn.CourierId)
            .OnDelete(DeleteBehavior.Cascade);

        // VendorNotification configuration
        builder.Entity<VendorNotification>()
            .HasOne(vn => vn.Vendor)
            .WithMany()
            .HasForeignKey(vn => vn.VendorId)
            .OnDelete(DeleteBehavior.Cascade);

        // CustomerNotification configuration
        builder.Entity<CustomerNotification>()
            .HasOne(cn => cn.Customer)
            .WithMany()
            .HasForeignKey(cn => cn.CustomerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CustomerNotification>()
            .HasOne(cn => cn.Order)
            .WithMany()
            .HasForeignKey(cn => cn.OrderId)
            .OnDelete(DeleteBehavior.Restrict);

        // Order - DeliveryAddress relationship
        builder.Entity<Order>()
            .HasOne(o => o.DeliveryAddress)
            .WithMany()
            .HasForeignKey(o => o.DeliveryAddressId)
            .OnDelete(DeleteBehavior.Restrict);

        // Order - Courier relationship removed (now using OrderCouriers table)
        // ActiveOrderCourier is a computed navigation property, ignore it for EF Core
        builder.Entity<Order>()
            .Ignore(o => o.ActiveOrderCourier);

        // OrderCourier Configuration
        builder.Entity<OrderCourier>()
            .HasOne(oc => oc.Order)
            .WithMany(o => o.OrderCouriers)
            .HasForeignKey(oc => oc.OrderId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<OrderCourier>()
            .HasOne(oc => oc.Courier)
            .WithMany(c => c.OrderCouriers)
            .HasForeignKey(oc => oc.CourierId)
            .OnDelete(DeleteBehavior.Restrict);

        // OrderCourier Indexes
        builder.Entity<OrderCourier>()
            .HasIndex(oc => oc.OrderId);

        builder.Entity<OrderCourier>()
            .HasIndex(oc => oc.CourierId);

        builder.Entity<OrderCourier>()
            .HasIndex(oc => new { oc.OrderId, oc.IsActive })
            .HasFilter("[IsActive] = 1");

        // OrderCourier Decimal precision
        builder.Entity<OrderCourier>()
            .Property(oc => oc.DeliveryFee)
            .HasColumnType("decimal(18,2)");

        builder.Entity<OrderCourier>()
            .Property(oc => oc.CourierTip)
            .HasColumnType("decimal(18,2)");

        // UserPreferences configuration
        builder.Entity<UserPreferences>()
            .HasOne(up => up.User)
            .WithMany()
            .HasForeignKey(up => up.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint: one preferences per user
        builder.Entity<UserPreferences>()
            .HasIndex(up => up.UserId)
            .IsUnique();

        // Review configuration
        builder.Entity<Review>()
            .HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Review>()
            .HasOne(r => r.Product)
            .WithMany()
            .HasForeignKey(r => r.ProductId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<Review>()
            .HasOne(r => r.Vendor)
            .WithMany()
            .HasForeignKey(r => r.VendorId)
            .OnDelete(DeleteBehavior.Restrict);

        // DeliveryProof configuration
        builder.Entity<DeliveryProof>()
            .HasOne(dp => dp.Order)
            .WithOne(o => o.DeliveryProof)
            .HasForeignKey<DeliveryProof>(dp => dp.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        // CourierEarning configuration
        builder.Entity<CourierEarning>()
            .HasOne(ce => ce.Courier)
            .WithMany()
            .HasForeignKey(ce => ce.CourierId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<CourierEarning>()
            .HasOne(ce => ce.Order)
            .WithOne(o => o.CourierEarning)
            .HasForeignKey<CourierEarning>(ce => ce.OrderId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.Entity<CourierEarning>()
            .Property(ce => ce.BaseDeliveryFee)
            .HasColumnType("decimal(18,2)");

        builder.Entity<CourierEarning>()
            .Property(ce => ce.DistanceBonus)
            .HasColumnType("decimal(18,2)");

        builder.Entity<CourierEarning>()
            .Property(ce => ce.TipAmount)
            .HasColumnType("decimal(18,2)");

        builder.Entity<CourierEarning>()
            .Property(ce => ce.TotalEarning)
            .HasColumnType("decimal(18,2)");

        // Customer configuration
        builder.Entity<Customer>()
            .HasOne(c => c.User)
            .WithOne()
            .HasForeignKey<Customer>(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Unique constraint: one customer record per user
        builder.Entity<Customer>()
            .HasIndex(c => c.UserId)
            .IsUnique();

        // Courier decimal properties
        builder.Entity<Courier>()
            .Property(c => c.TotalEarnings)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Courier>()
            .Property(c => c.CurrentDayEarnings)
            .HasColumnType("decimal(18,2)");

        // Order delivery fee (customer fee - stays in Order table)
        builder.Entity<Order>()
            .Property(o => o.DeliveryFee)
            .HasColumnType("decimal(18,2)");

        // LegalDocument configuration
        builder.Entity<LegalDocument>()
            .HasIndex(ld => new { ld.Type, ld.LanguageCode })
            .IsUnique();

        // ErrorLog configuration
        builder.Entity<ErrorLog>()
            .HasIndex(el => el.LogId)
            .IsUnique();

        builder.Entity<ErrorLog>()
            .HasIndex(el => el.UserId);

        builder.Entity<ErrorLog>()
            .HasIndex(el => el.Level);

        builder.Entity<ErrorLog>()
            .HasIndex(el => el.Timestamp);

        builder.Entity<ErrorLog>()
            .Property(el => el.LogId)
            .HasMaxLength(100);

        // VendorDeliveryZone configuration
        builder.Entity<VendorDeliveryZone>()
            .Property(v => v.DeliveryFee)
            .HasColumnType("decimal(18,2)");

        builder.Entity<VendorDeliveryZone>()
            .Property(v => v.MinimumOrderAmount)
            .HasColumnType("decimal(18,2)");

        // Coupon configuration
        builder.Entity<Coupon>()
            .Property(c => c.DiscountValue)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Coupon>()
            .Property(c => c.MinCartAmount)
            .HasColumnType("decimal(18,2)");

        // Campaign Configuration
        builder.Entity<Campaign>()
            .Property(c => c.MinCartAmount)
            .HasColumnType("decimal(18,2)");

        // Campaign Relations Configuration
        builder.Entity<CampaignCity>()
            .HasKey(cc => new { cc.CampaignId, cc.CityId });

        builder.Entity<CampaignCity>()
            .HasOne(cc => cc.Campaign)
            .WithMany(c => c.CampaignCities)
            .HasForeignKey(cc => cc.CampaignId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignCity>()
            .HasOne(cc => cc.City)
            .WithMany()
            .HasForeignKey(cc => cc.CityId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignDistrict>()
            .HasKey(cd => new { cd.CampaignId, cd.DistrictId });

        builder.Entity<CampaignDistrict>()
            .HasOne(cd => cd.Campaign)
            .WithMany(c => c.CampaignDistricts)
            .HasForeignKey(cd => cd.CampaignId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.Entity<CampaignDistrict>()
            .HasOne(cd => cd.District)
            .WithMany()
            .HasForeignKey(cd => cd.DistrictId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignCategory>()
            .HasKey(cc => new { cc.CampaignId, cc.CategoryId });

        builder.Entity<CampaignCategory>()
            .HasOne(cc => cc.Campaign)
            .WithMany(c => c.CampaignCategories)
            .HasForeignKey(cc => cc.CampaignId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignCategory>()
            .HasOne(cc => cc.Category)
            .WithMany()
            .HasForeignKey(cc => cc.CategoryId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignProduct>()
            .HasKey(cp => new { cp.CampaignId, cp.ProductId });

        builder.Entity<CampaignProduct>()
            .HasOne(cp => cp.Campaign)
            .WithMany(c => c.CampaignProducts)
            .HasForeignKey(cp => cp.CampaignId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CampaignProduct>()
            .HasOne(cp => cp.Product)
            .WithMany()
            .HasForeignKey(cp => cp.ProductId)
            .OnDelete(DeleteBehavior.Cascade);

        // Coupon Relations Configuration
        builder.Entity<CouponCity>()
            .HasKey(cc => new { cc.CouponId, cc.CityId });

        builder.Entity<CouponCity>()
            .HasOne(cc => cc.Coupon)
            .WithMany(c => c.CouponCities)
            .HasForeignKey(cc => cc.CouponId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponCity>()
            .HasOne(cc => cc.City)
            .WithMany()
            .HasForeignKey(cc => cc.CityId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponDistrict>()
            .HasKey(cd => new { cd.CouponId, cd.DistrictId });
        
        builder.Entity<CouponDistrict>()
            .HasOne(cd => cd.Coupon)
            .WithMany(c => c.CouponDistricts)
            .HasForeignKey(cd => cd.CouponId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponDistrict>()
            .HasOne(cd => cd.District)
            .WithMany()
            .HasForeignKey(cd => cd.DistrictId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponCategory>()
            .HasKey(cc => new { cc.CouponId, cc.CategoryId });
        
        builder.Entity<CouponCategory>()
            .HasOne(cc => cc.Coupon)
            .WithMany(c => c.CouponCategories)
            .HasForeignKey(cc => cc.CouponId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponCategory>()
            .HasOne(cc => cc.Category)
            .WithMany()
            .HasForeignKey(cc => cc.CategoryId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponProduct>()
            .HasKey(cp => new { cp.CouponId, cp.ProductId });

        builder.Entity<CouponProduct>()
            .HasOne(cp => cp.Coupon)
            .WithMany(c => c.CouponProducts)
            .HasForeignKey(cp => cp.CouponId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<CouponProduct>()
            .HasOne(cp => cp.Product)
            .WithMany()
            .HasForeignKey(cp => cp.ProductId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

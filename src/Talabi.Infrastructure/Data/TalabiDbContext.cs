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
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
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

        builder.Entity<Order>()
            .Property(o => o.TotalAmount)
            .HasColumnType("decimal(18,2)");

        builder.Entity<OrderItem>()
            .Property(oi => oi.UnitPrice)
            .HasColumnType("decimal(18,2)");

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

        // Order - Courier relationship
        builder.Entity<Order>()
            .HasOne(o => o.Courier)
            .WithMany(c => c.Orders)
            .HasForeignKey(o => o.CourierId)
            .OnDelete(DeleteBehavior.Restrict);

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

        // Order delivery fee
        builder.Entity<Order>()
            .Property(o => o.DeliveryFee)
            .HasColumnType("decimal(18,2)");

        builder.Entity<Order>()
            .Property(o => o.CourierTip)
            .HasColumnType("decimal(18,2)");

        // LegalDocument configuration
        builder.Entity<LegalDocument>()
            .HasIndex(ld => new { ld.Type, ld.LanguageCode })
            .IsUnique();
    }
}

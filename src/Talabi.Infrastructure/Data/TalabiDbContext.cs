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
    public DbSet<UserPreferences> UserPreferences { get; set; }

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
    }
}

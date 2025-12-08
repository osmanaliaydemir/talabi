# OrderCouriers Entity Detaylı Tasarım

## Tablo Karşılaştırması

### Mevcut Yapı (Orders Tablosu)
```
Orders
├── Id
├── CustomerId
├── VendorId
├── TotalAmount
├── Status
├── CourierId ❌ (Taşınacak)
├── CourierAssignedAt ❌ (Taşınacak)
├── CourierAcceptedAt ❌ (Taşınacak)
├── PickedUpAt ❌ (Taşınacak)
├── OutForDeliveryAt ❌ (Taşınacak)
├── DeliveredAt ❌ (Taşınacak)
├── DeliveryFee ❌ (Taşınacak - kurye ödemesi için)
└── CourierTip ❌ (Taşınacak)
```

### Yeni Yapı
```
Orders
├── Id
├── CustomerId
├── VendorId
├── TotalAmount
├── Status
├── DeliveryFee ✅ (Müşteriden alınan ücret - kalıyor)
└── ActiveOrderCourier (Navigation) ✅

OrderCouriers (YENİ)
├── Id
├── OrderId (FK)
├── CourierId (FK)
├── CourierAssignedAt ✅
├── CourierAcceptedAt ✅
├── CourierRejectedAt ✅ (YENİ - reddetme zamanı)
├── RejectReason ✅ (YENİ - reddetme sebebi)
├── PickedUpAt ✅
├── OutForDeliveryAt ✅
├── DeliveredAt ✅
├── DeliveryFee ✅ (Kuryeye ödenen ücret)
├── CourierTip ✅
├── IsActive ✅ (YENİ - aktif atama mı?)
└── Status ✅ (YENİ - enum)
```

---

## Entity Sınıf Detayları

### OrderCourier.cs

```csharp
using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public enum OrderCourierStatus
{
    Assigned = 0,        // Kurye atandı
    Accepted = 1,        // Kurye kabul etti
    Rejected = 2,        // Kurye reddetti
    PickedUp = 3,        // Sipariş alındı
    OutForDelivery = 4,  // Yola çıktı
    Delivered = 5        // Teslim edildi
}

public class OrderCourier : BaseEntity
{
    // Foreign Keys
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    
    public Guid CourierId { get; set; }
    public Courier? Courier { get; set; }
    
    // İşlem Zamanları
    public DateTime? CourierAssignedAt { get; set; }
    public DateTime? CourierAcceptedAt { get; set; }
    public DateTime? CourierRejectedAt { get; set; }
    public string? RejectReason { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    
    // Finansal Bilgiler
    public decimal DeliveryFee { get; set; } = 0;
    public decimal? CourierTip { get; set; }
    
    // Meta Bilgiler
    public bool IsActive { get; set; } = true;  // Bu atama aktif mi?
    public OrderCourierStatus Status { get; set; } = OrderCourierStatus.Assigned;
    
    // Navigation Properties (opsiyonel - performans için)
    // public ICollection<OrderCourierStatusHistory>? StatusHistory { get; set; }
}
```

### Order.cs Güncellemesi

```csharp
public class Order : BaseEntity
{
    // ... mevcut alanlar ...
    
    // YENİ: Aktif kurye ataması (navigation)
    public OrderCourier? ActiveOrderCourier { get; set; }
    
    // YENİ: Tüm kurye atama geçmişi
    public ICollection<OrderCourier> OrderCouriers { get; set; } = new List<OrderCourier>();
    
    // BACKWARD COMPATIBILITY (Obsolete - yavaş yavaş kaldırılacak)
    [Obsolete("Use ActiveOrderCourier.CourierId instead")]
    public Guid? CourierId 
    { 
        get => ActiveOrderCourier?.CourierId; 
        private set { /* Deprecated */ } 
    }
    
    [Obsolete("Use ActiveOrderCourier.CourierAssignedAt instead")]
    public DateTime? CourierAssignedAt 
    { 
        get => ActiveOrderCourier?.CourierAssignedAt; 
        private set { /* Deprecated */ } 
    }
    
    // ... diğer deprecated alanlar ...
    
    // DeliveryFee: Müşteriden alınan ücret (Order'da kalıyor)
    public decimal DeliveryFee { get; set; } = 0;
}
```

---

## Senaryo Örnekleri

### Senaryo 1: Normal Akış
```
1. Sipariş hazır → OrderCourier oluştur (Status: Assigned, IsActive: true)
2. Kurye kabul → OrderCourier güncelle (Status: Accepted)
3. Teslim al → OrderCourier güncelle (Status: PickedUp)
4. Yola çık → OrderCourier güncelle (Status: OutForDelivery)
5. Teslim et → OrderCourier güncelle (Status: Delivered)
```

**OrderCouriers Tablosu:**
```
Id          OrderId    CourierId  Status     IsActive  CourierAssignedAt  CourierAcceptedAt  ...
oc-001      ord-001    cou-001    Delivered  true      2024-01-01 10:00   2024-01-01 10:05   ...
```

### Senaryo 2: Reddetme ve Yeniden Atama
```
1. Sipariş hazır → OrderCourier-1 oluştur (Status: Assigned, IsActive: true)
2. Kurye reddet → OrderCourier-1 güncelle (Status: Rejected, IsActive: false)
3. Yeni kurye atan → OrderCourier-2 oluştur (Status: Assigned, IsActive: true)
4. İkinci kurye kabul → OrderCourier-2 güncelle (Status: Accepted)
...
```

**OrderCouriers Tablosu:**
```
Id          OrderId    CourierId  Status     IsActive  CourierAssignedAt  CourierRejectedAt  RejectReason
oc-001      ord-001    cou-001    Rejected   false     2024-01-01 10:00   2024-01-01 10:03   "Müsait değilim"
oc-002      ord-001    cou-002    Accepted   true      2024-01-01 10:05   NULL               NULL
```

---

## DbContext Konfigürasyonu

```csharp
// TalabiDbContext.cs

public DbSet<OrderCourier> OrderCouriers { get; set; }

protected override void OnModelCreating(ModelBuilder builder)
{
    base.OnModelCreating(builder);
    
    // OrderCourier Configuration
    builder.Entity<OrderCourier>()
        .HasOne(oc => oc.Order)
        .WithMany(o => o.OrderCouriers)
        .HasForeignKey(oc => oc.OrderId)
        .OnDelete(DeleteBehavior.Restrict);
    
    builder.Entity<OrderCourier>()
        .HasOne(oc => oc.Courier)
        .WithMany()
        .HasForeignKey(oc => oc.CourierId)
        .OnDelete(DeleteBehavior.Restrict);
    
    // Indexes
    builder.Entity<OrderCourier>()
        .HasIndex(oc => oc.OrderId);
    
    builder.Entity<OrderCourier>()
        .HasIndex(oc => oc.CourierId);
    
    builder.Entity<OrderCourier>()
        .HasIndex(oc => new { oc.OrderId, oc.IsActive })
        .HasFilter("[IsActive] = 1");
    
    // Decimal precision
    builder.Entity<OrderCourier>()
        .Property(oc => oc.DeliveryFee)
        .HasColumnType("decimal(18,2)");
    
    builder.Entity<OrderCourier>()
        .Property(oc => oc.CourierTip)
        .HasColumnType("decimal(18,2)");
    
    // Order - ActiveOrderCourier relationship (One-to-One)
    builder.Entity<Order>()
        .HasOne(o => o.ActiveOrderCourier)
        .WithOne()
        .HasForeignKey<OrderCourier>(oc => oc.OrderId)
        .HasPrincipalKey<Order>(o => o.Id)
        .OnDelete(DeleteBehavior.Restrict);
    
    // Filter: ActiveOrderCourier should only have IsActive = true
    builder.Entity<Order>()
        .HasOne(o => o.ActiveOrderCourier)
        .WithOne()
        .HasPrincipalKey<Order>(o => o.Id)
        .HasForeignKey<OrderCourier>(oc => oc.OrderId)
        .OnDelete(DeleteBehavior.Restrict);
}
```

---

## Query Örnekleri

### Aktif Kurye Atamasını Getir
```csharp
var activeCourier = await _context.OrderCouriers
    .Include(oc => oc.Courier)
    .FirstOrDefaultAsync(oc => 
        oc.OrderId == orderId && 
        oc.IsActive == true);
```

### Tüm Kurye Geçmişini Getir
```csharp
var courierHistory = await _context.OrderCouriers
    .Include(oc => oc.Courier)
    .Where(oc => oc.OrderId == orderId)
    .OrderByDescending(oc => oc.CreatedAt)
    .ToListAsync();
```

### Bir Kuryenin Tüm Siparişlerini Getir
```csharp
var courierOrders = await _context.OrderCouriers
    .Include(oc => oc.Order)
        .ThenInclude(o => o.Vendor)
    .Where(oc => oc.CourierId == courierId)
    .OrderByDescending(oc => oc.CreatedAt)
    .ToListAsync();
```

---

## Service Metod Örnekleri

### AssignOrderToCourierAsync Güncelleme
```csharp
public async Task<bool> AssignOrderToCourierAsync(Guid orderId, Guid courierId)
{
    var order = await _context.Orders.FindAsync(orderId);
    var courier = await _context.Couriers.FindAsync(courierId);
    
    if (order == null || courier == null) return false;
    if (order.Status != OrderStatus.Ready) return false;
    if (!courier.IsActive || courier.Status != CourierStatus.Available) return false;
    
    // Önceki atamaları pasif yap
    var previousAssignments = await _context.OrderCouriers
        .Where(oc => oc.OrderId == orderId && oc.IsActive)
        .ToListAsync();
    
    foreach (var prev in previousAssignments)
    {
        prev.IsActive = false;
    }
    
    // Yeni atama oluştur
    var orderCourier = new OrderCourier
    {
        OrderId = orderId,
        CourierId = courierId,
        CourierAssignedAt = DateTime.UtcNow,
        Status = OrderCourierStatus.Assigned,
        IsActive = true,
        DeliveryFee = await CalculateDeliveryFee(order, courier)
    };
    
    _context.OrderCouriers.Add(orderCourier);
    
    // Order'ı güncelle
    order.Status = OrderStatus.Assigned;
    
    await _context.SaveChangesAsync();
    
    return true;
}
```

---

## Migration Script Örneği

```csharp
public partial class AddOrderCouriersTable : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Tablo oluştur
        migrationBuilder.CreateTable(
            name: "OrderCouriers",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                OrderId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                CourierId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                CourierAssignedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                CourierAcceptedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                CourierRejectedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                RejectReason = table.Column<string>(type: "nvarchar(max)", nullable: true),
                PickedUpAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                OutForDeliveryAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                DeliveredAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                DeliveryFee = table.Column<decimal>(type: "decimal(18,2)", nullable: false, defaultValue: 0m),
                CourierTip = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                Status = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_OrderCouriers", x => x.Id);
                table.ForeignKey(
                    name: "FK_OrderCouriers_Orders_OrderId",
                    column: x => x.OrderId,
                    principalTable: "Orders",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
                table.ForeignKey(
                    name: "FK_OrderCouriers_Couriers_CourierId",
                    column: x => x.CourierId,
                    principalTable: "Couriers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Restrict);
            });
        
        // Index'ler
        migrationBuilder.CreateIndex(
            name: "IX_OrderCouriers_OrderId",
            table: "OrderCouriers",
            column: "OrderId");
        
        migrationBuilder.CreateIndex(
            name: "IX_OrderCouriers_CourierId",
            table: "OrderCouriers",
            column: "CourierId");
        
        migrationBuilder.CreateIndex(
            name: "IX_OrderCouriers_OrderId_IsActive",
            table: "OrderCouriers",
            columns: new[] { "OrderId", "IsActive" },
            filter: "[IsActive] = 1");
        
        // Veri migration (SQL)
        migrationBuilder.Sql(@"
            INSERT INTO OrderCouriers (
                Id, OrderId, CourierId,
                CourierAssignedAt, CourierAcceptedAt, PickedUpAt, 
                OutForDeliveryAt, DeliveredAt,
                DeliveryFee, CourierTip,
                IsActive, Status, CreatedAt, UpdatedAt
            )
            SELECT 
                NEWID() AS Id,
                Id AS OrderId,
                CourierId,
                CourierAssignedAt,
                CourierAcceptedAt,
                PickedUpAt,
                OutForDeliveryAt,
                DeliveredAt,
                DeliveryFee,
                CourierTip,
                1 AS IsActive,
                CASE 
                    WHEN DeliveredAt IS NOT NULL THEN 5
                    WHEN OutForDeliveryAt IS NOT NULL THEN 4
                    WHEN PickedUpAt IS NOT NULL THEN 3
                    WHEN CourierAcceptedAt IS NOT NULL THEN 1
                    WHEN CourierAssignedAt IS NOT NULL THEN 0
                    ELSE 0
                END AS Status,
                CreatedAt,
                UpdatedAt
            FROM Orders
            WHERE CourierId IS NOT NULL;
        ");
    }
    
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "OrderCouriers");
    }
}
```

---

## Önemli Notlar

1. **DeliveryFee İkilemi:**
   - `Order.DeliveryFee`: Müşteriden alınan ücret (kalıyor)
   - `OrderCourier.DeliveryFee`: Kuryeye ödenen ücret (yeni tablo)

2. **IsActive Mantığı:**
   - Bir sipariş için aynı anda sadece bir `IsActive = true` olabilir
   - Yeni atama yapılırken öncekiler pasif yapılır

3. **Status Yönetimi:**
   - Status enum ile yönetilir
   - Her adımda status güncellenir

4. **Backward Compatibility:**
   - Eski alanlar `[Obsolete]` olarak işaretlenir
   - Yeni kodlar OrderCourier kullanır
   - Eski API'ler çalışmaya devam eder


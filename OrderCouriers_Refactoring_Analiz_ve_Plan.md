# OrderCouriers Tablosu Refactoring - Analiz ve İş Planı

## 1. Mevcut Durum Analizi

### 1.1. Orders Tablosunda Kurye İşlemleri
Şu anda `Orders` tablosunda şu alanlar tutuluyor:
- `CourierId` (Guid?)
- `CourierAssignedAt` (DateTime?)
- `CourierAcceptedAt` (DateTime?)
- `PickedUpAt` (DateTime?)
- `OutForDeliveryAt` (DateTime?)
- `DeliveredAt` (DateTime?)
- `DeliveryFee` (decimal)
- `CourierTip` (decimal?)

### 1.2. Mevcut Kullanım Noktaları

#### Backend:
1. **OrderAssignmentService.cs**
   - `AssignOrderToCourierAsync`: CourierId, CourierAssignedAt güncelleniyor
   - `AcceptOrderAsync`: CourierAcceptedAt güncelleniyor
   - `RejectOrderAsync`: Tüm kurye alanları sıfırlanıyor
   - `PickUpOrderAsync`: PickedUpAt, OutForDeliveryAt güncelleniyor
   - `DeliverOrderAsync`: DeliveredAt güncelleniyor, DeliveryFee kullanılıyor

2. **CourierController.cs**
   - Aktif siparişlerde DeliveryFee gösteriliyor
   - Sipariş geçmişinde kurye alanları kullanılıyor

3. **Entity: Order.cs**
   - Tüm kurye alanları direkt entity'de

#### Frontend (Mobile):
- `courier_order.dart`: DeliveryFee gösteriliyor
- Kurye işlem ekranları bu alanları kullanıyor

### 1.3. Sorunlar ve İhtiyaçlar

**Sorunlar:**
1. ✅ Bir siparişe birden fazla kurye atanabilir ama geçmiş tutulmuyor (reddedilme durumunda)
2. ✅ Kurye işlemlerinin zaman çizelgesi takip edilemiyor
3. ✅ Orders tablosu kurye bilgileriyle karmaşık hale gelmiş

**Faydalar:**
1. ✅ Kurye atama geçmişi tutulabilir
2. ✅ Aynı siparişe birden fazla kurye atanabilir (reject sonrası)
3. ✅ Orders tablosu daha temiz ve odaklanmış olur
4. ✅ Kurye performans analizi yapılabilir

---

## 2. Yeni Yapı Önerisi

### 2.1. OrderCouriers Tablosu

```sql
CREATE TABLE OrderCouriers (
    Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OrderId UNIQUEIDENTIFIER NOT NULL,
    CourierId UNIQUEIDENTIFIER NOT NULL,
    
    -- İşlem zamanları
    CourierAssignedAt DATETIME2 NULL,
    CourierAcceptedAt DATETIME2 NULL,
    CourierRejectedAt DATETIME2 NULL,
    RejectReason NVARCHAR(MAX) NULL,
    PickedUpAt DATETIME2 NULL,
    OutForDeliveryAt DATETIME2 NULL,
    DeliveredAt DATETIME2 NULL,
    
    -- Finansal bilgiler
    DeliveryFee DECIMAL(18,2) NOT NULL DEFAULT 0,
    CourierTip DECIMAL(18,2) NULL,
    
    -- Meta bilgiler
    IsActive BIT NOT NULL DEFAULT 1,  -- Aktif atama mı? (en son atanan)
    Status INT NOT NULL,  -- Enum: Assigned, Accepted, Rejected, PickedUp, OutForDelivery, Delivered
    
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NULL,
    
    FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE RESTRICT,
    FOREIGN KEY (CourierId) REFERENCES Couriers(Id) ON DELETE RESTRICT
);

CREATE INDEX IX_OrderCouriers_OrderId ON OrderCouriers(OrderId);
CREATE INDEX IX_OrderCouriers_CourierId ON OrderCouriers(CourierId);
CREATE INDEX IX_OrderCouriers_IsActive ON OrderCouriers(OrderId, IsActive) WHERE IsActive = 1;
```

### 2.2. Orders Tablosundan Çıkarılacak Alanlar
Aşağıdaki alanlar Orders tablosundan kaldırılabilir (backward compatibility için geçici olarak tutulabilir):
- `CourierId` → OrderCouriers tablosuna taşınacak
- `CourierAssignedAt`
- `CourierAcceptedAt`
- `PickedUpAt`
- `OutForDeliveryAt`
- `DeliveredAt`
- `DeliveryFee` → **DİKKAT:** Müşteri için hesaplanan delivery fee olabilir, kuryeye ödenen ayrı olabilir
- `CourierTip`

**Önemli Not:** `DeliveryFee` iki anlamda kullanılıyor olabilir:
- Müşteriden alınan delivery fee (Order'da kalmalı)
- Kuryeye ödenen fee (OrderCouriers'da olmalı)

---

## 3. İş Planı ve Adımlar

### Faz 1: Yeni Entity ve Migration Hazırlığı

#### 1.1. Entity Oluşturma
- [x] `OrderCourier.cs` entity oluştur
- [x] Enum: `OrderCourierStatus` oluştur (Assigned, Accepted, Rejected, PickedUp, OutForDelivery, Delivered)
- [x] BaseEntity'den türet
- [x] Navigation properties: Order, Courier

#### 1.2. DbContext Güncelleme
- [x] DbSet<OrderCourier> ekle
- [x] OnModelCreating'de configuration ekle
- [x] Relationships tanımla

#### 1.3. Migration Oluşturma
- [x] `AddOrderCouriersTable` migration oluştur
- [x] Mevcut Orders verilerini OrderCouriers'a migrate et
- [x] Veri migration script'i yaz

### Faz 2: Service Katmanı Refactoring

#### 2.1. OrderAssignmentService Güncelleme
- [x] `AssignOrderToCourierAsync`: OrderCourier kaydı oluştur
- [x] `AcceptOrderAsync`: OrderCourier kaydını güncelle
- [x] `RejectOrderAsync`: OrderCourier kaydını güncelle (reject), yeni kayıt için hazırlık yap
- [x] `PickUpOrderAsync`: OrderCourier kaydını güncelle
- [x] `DeliverOrderAsync`: OrderCourier kaydını güncelle
- [x] `GetActiveOrdersForCourierAsync`: OrderCouriers üzerinden sorgula

#### 2.2. Helper Metodlar
- [x] `GetActiveOrderCourier(Guid orderId)`: Aktif OrderCourier'ı getir (GetActiveOrderCourierAsync olarak eklendi)
- [x] `GetOrderCourierHistory(Guid orderId)`: Tüm kurye geçmişini getir (GetOrderCourierHistoryAsync olarak eklendi)
- [x] `DeactivatePreviousAssignments(Guid orderId)`: Önceki atamaları pasif yap (DeactivatePreviousAssignmentsAsync olarak eklendi)

### Faz 3: DTO ve API Güncellemeleri

#### 3.1. DTO Güncellemeleri
- [x] `CourierOrderDto`: OrderCourier bilgilerini içerecek şekilde güncelle
- [ ] `OrderCourierDto`: Yeni DTO oluştur (Opsiyonel - CourierOrderDto içinde OrderCourier bilgileri mevcut)
- [ ] `OrderCourierHistoryDto`: Geçmiş için DTO (Opsiyonel - CourierOrderDto kullanılıyor)

#### 3.2. Controller Güncellemeleri
- [x] `CourierController`: OrderCourier bilgilerini dönecek şekilde güncelle
- [x] `OrdersController`: Gerekirse güncelle (VendorOrdersController ve MapController güncellendi)
- [x] `VendorOrdersController`: OrderCouriers kullanımına güncellendi
- [x] `AdminCourierController`: OrderCouriers kullanımına güncellendi
- [x] `MapController`: OrderCouriers kullanımına güncellendi

### Faz 4: Backward Compatibility

#### 4.1. Order Entity'de Geçici Alanlar
- [x] Order entity'de alanları `[Obsolete]` olarak işaretle (Başlangıçta yapıldı, sonra direkt kaldırıldı)
- [x] Deprecated property'ler ekle (OrderCourier'dan okusun) (Başlangıçta yapıldı, sonra kaldırıldı)
- [x] Eski kodların çalışması için compatibility layer (Tüm kodlar güncellendi, direkt kaldırıldı)

#### 4.2. Migration Stratejisi
- [x] Mevcut verileri OrderCouriers'a taşı
- [x] Eski alanları NULL yap veya tut (opsiyonel) (Eski alanlar Orders tablosundan kaldırıldı)

### Faz 5: Frontend Güncellemeleri

#### 5.1. Mobile App
- [x] `courier_order.dart` model güncelle
- [x] Kurye işlem ekranlarını güncelle
- [x] API response'larına göre uyarla

#### 5.2. Test
- [ ] Kurye atama akışını test et (Kullanıcı test edecek)
- [ ] Reddetme ve yeniden atama senaryosunu test et (Kullanıcı test edecek)
- [ ] Sipariş geçmişini test et (Kullanıcı test edecek)

### Faz 6: Temizlik ve Optimizasyon

#### 6.1. Eski Alanları Kaldırma
- [x] Order entity'den eski alanları kaldır (opsiyonel, backward compatibility gerekirse tut) (Kaldırıldı)
- [x] Gereksiz kodları temizle (Order.Courier navigation property kaldırıldı)

#### 6.2. Performans Optimizasyonu
- [x] Index'leri kontrol et (Index'ler eklendi: OrderId, CourierId, IsActive filtered index)
- [x] Query'leri optimize et (Include stratejileri uygulandı)
- [x] Include stratejilerini gözden geçir (Eager loading kullanılıyor)

---

## 4. Teknik Detaylar

### 4.1. OrderCourier Entity Yapısı

```csharp
public enum OrderCourierStatus
{
    Assigned = 0,
    Accepted = 1,
    Rejected = 2,
    PickedUp = 3,
    OutForDelivery = 4,
    Delivered = 5
}

public class OrderCourier : BaseEntity
{
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    
    public Guid CourierId { get; set; }
    public Courier? Courier { get; set; }
    
    public DateTime? CourierAssignedAt { get; set; }
    public DateTime? CourierAcceptedAt { get; set; }
    public DateTime? CourierRejectedAt { get; set; }
    public string? RejectReason { get; set; }
    public DateTime? PickedUpAt { get; set; }
    public DateTime? OutForDeliveryAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    
    public decimal DeliveryFee { get; set; } = 0;
    public decimal? CourierTip { get; set; }
    
    public bool IsActive { get; set; } = true;
    public OrderCourierStatus Status { get; set; } = OrderCourierStatus.Assigned;
}
```

### 4.2. Migration Stratejisi

**Veri Migration:**
```sql
-- Mevcut Orders verilerini OrderCouriers'a taşı
INSERT INTO OrderCouriers (
    Id, OrderId, CourierId,
    CourierAssignedAt, CourierAcceptedAt, PickedUpAt, 
    OutForDeliveryAt, DeliveredAt,
    DeliveryFee, CourierTip,
    IsActive, Status, CreatedAt, UpdatedAt
)
SELECT 
    NEWID(),
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
        WHEN DeliveredAt IS NOT NULL THEN 5 -- Delivered
        WHEN OutForDeliveryAt IS NOT NULL THEN 4 -- OutForDelivery
        WHEN PickedUpAt IS NOT NULL THEN 3 -- PickedUp
        WHEN CourierAcceptedAt IS NOT NULL THEN 1 -- Accepted
        WHEN CourierAssignedAt IS NOT NULL THEN 0 -- Assigned
        ELSE 0
    END AS Status,
    CreatedAt,
    UpdatedAt
FROM Orders
WHERE CourierId IS NOT NULL;
```

### 4.3. Backward Compatibility

Order entity'de geçici olarak:
```csharp
[Obsolete("Use OrderCouriers table instead")]
public Guid? CourierId 
{ 
    get => ActiveOrderCourier?.CourierId; 
    set { /* No-op for backward compatibility */ }
}

public OrderCourier? ActiveOrderCourier { get; set; }
```

---

## 5. Risk Analizi ve Çözümler

### Risk 1: Mevcut API'lerin Bozulması
**Çözüm:** Backward compatibility layer ile eski property'lerden OrderCourier'a yönlendirme

### Risk 2: Veri Kaybı
**Çözüm:** Migration'da tüm verileri taşı, test ortamında önce dene

### Risk 3: Performance Sorunları
**Çözüm:** Index'ler ekle, eager loading stratejisi kullan

### Risk 4: Frontend Uyumsuzluğu
**Çözüm:** API response formatını koru veya versioning kullan

---

## 6. Test Senaryoları

1. ✅ Yeni siparişe kurye atama
2. ✅ Kurye siparişi kabul etme
3. ✅ Kurye siparişi reddetme ve yeni kurye atama
4. ✅ Siparişi teslim alma
5. ✅ Siparişi teslim etme
6. ✅ Kurye geçmişini görüntüleme
7. ✅ Mevcut verilerin migration sonrası doğruluğu

---

## 7. Zaman Tahmini

- **Faz 1:** 2-3 saat (Entity + Migration)
- **Faz 2:** 4-5 saat (Service refactoring)
- **Faz 3:** 2-3 saat (DTO + API)
- **Faz 4:** 2 saat (Backward compatibility)
- **Faz 5:** 2-3 saat (Frontend)
- **Faz 6:** 1-2 saat (Test + Optimizasyon)

**Toplam:** 13-18 saat

---

## 8. Sonuç ve Öneriler

### Önerilen Yaklaşım:
1. ✅ Önce OrderCouriers tablosunu oluştur
2. ✅ Verileri migrate et
3. ✅ Service'leri güncelle
4. ✅ Test et
5. ✅ Backward compatibility sağla
6. ✅ Frontend'i güncelle
7. ✅ Eski alanları kaldır (opsiyonel)

### DeliveryFee Hakkında:
`DeliveryFee` iki farklı anlamda kullanılıyor olabilir:
- **Order.DeliveryFee**: Müşteriden alınan ücret (kalmalı)
- **OrderCourier.DeliveryFee**: Kuryeye ödenen ücret (yeni tabloda)

Bu durumu analiz edip gerekirse Order'da kalacak şekilde ayırmak gerekebilir.


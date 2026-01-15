# Konum ve Lojistik Altyapı Planı (Location & Logistics Roadmap)

Rastgele "5 km kare" mantığı yerine, her işletmenin kendi kapasitesine göre belirleyebileceği **"Dinamik Yarıçap (Dynamic Radius)"** modeline geçiş planıdır. Bu yapı, sistemi hem teknik olarak daha doğru hem de ticari olarak ölçeklenebilir kılacaktır.

## 📊 Genel Durum Özeti

| Kategori | Tamamlanan | Toplam | Durum |
|----------|------------|--------|-------|
| Veritabanı ve Backend Altyapısı | 4/4 | 4 | ✅ %100 |
| Müşteri Tarafı (Discovery) | 3/3 | 3 | ✅ %100 |
| Kurye Atama Sistemi | 2/2 | 2 | ✅ %100 |
| İleri Seviye Özellikler | 3/3 | 3 | ✅ %100 |
| Mobile Implementasyonu | 2/2 | 2 | ✅ %100 |
| **TOPLAM** | **14/14** | **14** | **✅ %100** |

---

## 1. Veritabanı ve Backend Altyapısı (Temel)

Bu aşama, sistemin "sabit 5 km" mantığından "dinamik mesafe" mantığına geçişi için zorunludur.

### ✅ Entity Güncellemesi (`Vendor`)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Core/Entities/Vendor.cs` (satır 18)
- **Detay:** `public int DeliveryRadiusInKm { get; set; } = 5;`
- **Varsayılan Değer:** `5` (km)
- **Açıklama:** Her restoranın varsayılan olarak 5 km menzili olacak, ancak bu değer panelden değiştirilebilecek.

### ✅ Veritabanı Migration
- **Durum:** Tamamlandı
- **Migration Dosyası:** `20260109090508_AddDeliveryRadiusToVendor.cs`
- **⚠️ Not:** Migration'da `defaultValue: 0` olarak ayarlanmış, ancak entity'de varsayılan değer 5. Mevcut kayıtlar için veri güncellemesi gerekebilir:
  ```sql
  UPDATE Vendors SET DeliveryRadiusInKm = 5 WHERE DeliveryRadiusInKm = 0;
  ```

### ✅ DTO Güncellemeleri
- **Durum:** Tamamlandı
- **DTO'lar:**
  - `VendorDto` (Okuma) - `src/Talabi.Core/DTOs/VendorDtos.cs`
  - `UpdateVendorProfileDto` (Yazma) - `src/Talabi.Core/DTOs/VendorProfileDtos.cs`
  - `VendorProfileDto` (Okuma) - `src/Talabi.Core/DTOs/VendorProfileDtos.cs`
- **JSON Mapping:** `[JsonPropertyName("deliveryRadiusInKm")]` attribute'ları eklendi

### ✅ API Endpoint Güncellemesi
- **Durum:** Tamamlandı
- **⚠️ ÖNEMLİ:** API yapısı ayrımı:
  - **Vendor Dashboard Endpoint'leri:** `Controllers/Vendors/` altında
    - `GET /api/vendors/dashboard/account/profile` - Vendor dashboard profil getirme
    - `PUT /api/vendors/dashboard/account/profile` - Vendor dashboard profil güncelleme
    - `PUT /api/vendors/dashboard/account/settings` - Vendor dashboard ayarlar güncelleme (DeliveryRadiusInKm dahil)
  - **Customer-Facing Endpoint'leri:** `Controllers` altında (direkt)
    - `GET /api/vendors` - Customer için vendor listesi (DeliveryRadiusInKm bilgisi dahil)
    - `GET /api/vendors/{id}/products` - Customer için vendor ürünleri
    - `GET /api/products` - Customer için ürün arama/listeleme
- **Not:** Customer ekranları **SADECE** `Controllers` altındaki endpoint'leri kullanır. `Controllers/Vendors/` altındaki endpoint'ler sadece vendor dashboard için kullanılır.

---

## 2. Müşteri Tarafı: Akıllı Listeleme (Discovery)

Müşterinin sipariş veremeyeceği restoranları görüp hayal kırıklığına uğramasını engellemek için filtreleme en başta yapılmalıdır.

**⚠️ ÖNEMLİ API YAPISI:**
- **Customer-Facing Endpoint'ler:** `Controllers` altında (direkt root seviyesinde)
- **Vendor Dashboard Endpoint'leri:** `Controllers/Vendors/` altında (customer tarafından kullanılmaz)

### ✅ Backend Query Güncellemesi (`VendorsController`)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Api/Controllers/VendorsController.cs` ⚠️ **Customer-Facing Controller**
- **Route:** `/api/vendors` (dashboard değil, direkt)
- **Metodlar:**
  - `GetVendors` (satır 103-106) - Dinamik yarıçap filtresi uygulanıyor
  - `Search` (satır 412-415) - Arama sonuçlarında dinamik yarıçap kullanılıyor
  - `GetProductsByVendor` (satır 220) - Vendor ürünlerini getirir (customer için)
- **Mantık:**
  - **Eski:** `Distance < SabitDeger`
  - **Yeni:** `Distance(Customer, Vendor) <= (Vendor.DeliveryRadiusInKm == 0 ? 5 : Vendor.DeliveryRadiusInKm)`
- **Fallback:** `DeliveryRadiusInKm = 0` ise varsayılan olarak 5 km kabul ediliyor
- **⚠️ Not:** Bu controller customer tarafından kullanılır. Vendor dashboard için `Controllers/Vendors/` altındaki controller'lar kullanılır.

### ✅ Ürün Arama Filtreleme (`ProductsController`)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Api/Controllers/ProductsController.cs` ⚠️ **Customer-Facing Controller**
- **Route:** `/api/products` (dashboard değil, direkt)
- **Metodlar:**
  - `Search` (satır 178, 294) - Ürün aramada vendor delivery radius kontrolü
  - `GetPopularProducts` (satır 480) - Popüler ürünlerde radius kontrolü
  - `GetSimilarProducts` (satır 654) - Benzer ürünlerde radius kontrolü
- **Mantık:** Müşteri konumu vendor'ın delivery radius içindeyse ürünler gösteriliyor
- **⚠️ Not:** Bu controller customer tarafından kullanılır. Vendor dashboard için `Controllers/Vendors/ProductsController` kullanılır.

### ✅ Sepet Kontrolü (`CartController`)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Api/Controllers/CartController.cs` ⚠️ **Customer-Facing Controller**
- **Route:** `/api/cart` (dashboard değil, direkt)
- **Metod:** `AddItem` (satır 254-265)
- **Mantık:** Ürün sepete eklenirken vendor'ın delivery radius kontrolü yapılıyor

---

## 3. Kurye Atama Sistemi (Dispatching)

Siparişin restorandan kuryeye aktarılması sürecinin lojistik optimizasyonu.

### ✅ Sipariş Yayını (Broadcast)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Infrastructure/Services/OrderAssignmentService.cs`
- **Metod:** `BroadcastOrderToCouriersAsync` (satır 234-303)
- **Tetikleme:** Sipariş durumu `Ready` (Hazır) olduğunda tetiklenir
- **Merkez Nokta:** Restoranın konumu (`vendor.Latitude`, `vendor.Longitude`)
- **Arama Alanı:** Restoranın çevresindeki **5 km yarıçap** (varsayılan, parametre olarak değiştirilebilir)
- **Filtreleme:**
  - `Status = Available` (Çevrimiçi)
  - `CurrentActiveOrders < MaxActiveOrders` (Kapasite kontrolü)
  - `Distance <= radiusKm` (Mesafe kontrolü)
- **Sonuç:** Uygun kuryelere `OrderCourier` kaydı oluşturulur ve bildirim gönderilir

### ✅ Otomatik Kurye Atama (Auto-Assign)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Infrastructure/Services/OrderAssignmentService.cs`
- **Metod:** `FindBestCourierAsync` (satır 188-232)
- **Mantık:**
  - 5 km yarıçap içindeki kuryeler arasından en yakın olanı seçilir
  - İkincil sıralama: Yüksek rating'e sahip kuryeler öncelikli
- **Kullanım:** Vendor dashboard'dan otomatik atama yapılabilir

---

## 4. İleri Seviye Lojistik & Ekonomi

Temel yapı oturduktan sonra, sistemin kârlılığını korumak için eklenecek kurallar.

### ✅ Kademeli Teslimat Ücreti (Tiered Delivery Fee)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Infrastructure/Services/OrderAssignmentService.cs`
- **Metod:** `CalculateDeliveryFee` (satır 838-909)
- **Ücret Yapısı:**
  - **0-2 km:** Ücretsiz (base fee içinde, 15 TL)
  - **2-5 km:** 5 TL/km (2 km'den sonraki her km için)
  - **5-10 km:** 8 TL/km (5 km'den sonraki her km için)
  - **10+ km:** 10 TL/km (10 km'den sonraki her km için)
- **Ek Bonuslar:**
  - **Zaman Bonusu:** 18:00-22:00 arası %20 ek ücret
  - **Araç Tipi Bonusu:** Motor, Araba, Bisiklet için farklı katsayılar
- **Hesaplama:** Gerçek yol mesafesi (Google Maps API) kullanılıyor, fallback olarak kuş uçuşu mesafesi

### ✅ Dinamik Minimum Sepet Tutarı (Dynamic Threshold)
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Infrastructure/Services/OrderService.cs`
- **Metodlar:** `CreateOrderAsync` (satır 199-214), `UpdateOrderAsync` (satır 857-872)
- **Mantık:**
  - **0-2 km:** Vendor'ın `MinimumOrderAmount` değeri (varsayılan 0)
  - **2-5 km:** Minimum 200 TL
  - **5+ km:** Minimum 300 TL
- **Kontrol:** Sipariş oluşturma ve güncelleme sırasında dinamik minimum tutar kontrol ediliyor

### ✅ Yol Mesafesi Doğrulaması (Router Check)
- **Durum:** Tamamlandı
- **Interface:** `src/Talabi.Core/Interfaces/IMapService.cs`
- **Implementasyon:** `src/Talabi.Infrastructure/Services/GoogleMapService.cs`
- **Metod:** `GetRoadDistanceAsync` (satır 22-69)
- **API:** Google Maps Distance Matrix API kullanılıyor
- **Özellikler:**
  - ✅ Gerçek yol mesafesi hesaplanıyor (kuş uçuşu değil)
  - ✅ Nehir, otoban gibi engeller dikkate alınıyor
  - ✅ Fallback mekanizması: API hatası durumunda kuş uçuşu mesafesi (`crowFlyDistance`) kullanılıyor
- **Kullanım:**
  - `OrderAssignmentService.CalculateDeliveryFee` (satır 861-868)
  - `OrderService.CreateOrderAsync` (satır 184-191)
  - `OrderService.UpdateOrderAsync` (satır 842-849)

---

## 5. Mobile Implementasyonu

### ✅ Vendor Dashboard - Delivery Radius Ayarları
- **Durum:** Tamamlandı
- **Dosya:** `mobile/lib/features/profile/presentation/screens/vendor/settings_screen.dart`
- **Endpoint:** `PUT /api/vendors/dashboard/account/settings` ⚠️ **Vendor Dashboard Endpoint**
- **Constants:** `mobile/lib/core/constants/vendor_api_constants.dart` kullanılıyor
- **Özellikler:**
  - Delivery radius slider ile ayarlanabiliyor (satır 343-390)
  - Vendor settings güncelleme endpoint'i kullanılıyor
  - `deliveryRadiusInKm` field'ı `int` olarak parse ediliyor (satır 117-119)

### ✅ Customer - Vendor Listeleme
- **Durum:** Tamamlandı
- **Endpoint:** `GET /api/vendors` ⚠️ **Customer-Facing Endpoint** (dashboard değil)
- **Constants:** `mobile/lib/core/constants/api_constants.dart` kullanılıyor
- **Parametreler:** `userLatitude` ve `userLongitude` parametreleri ile
- **Filtreleme:** Mobile tarafında backend'den gelen vendor listesi zaten filtrelenmiş olarak geliyor
- **Distance Display:** Vendor DTO'sunda `DistanceInKm` field'ı gösteriliyor
- **⚠️ Not:** Customer ekranları `Controllers/VendorsController.cs` kullanır, `Controllers/Vendors/` altındaki endpoint'leri kullanmaz.

---

## 6. Delivery Zone Sistemi (Mahalle Bazlı Teslimat)

Sistemde hem **dinamik yarıçap** hem de **mahalle bazlı teslimat alanları** (Delivery Zones) mevcut. İki sistem birlikte çalışabilir:

### ✅ VendorDeliveryZone Entity
- **Durum:** Tamamlandı
- **Dosya:** `src/Talabi.Core/Entities/VendorDeliveryZone.cs`
- **Özellikler:**
  - `CityId`, `DistrictId`, `LocalityId` ile mahalle bazlı teslimat alanları tanımlanabiliyor
  - Her zone için özel `DeliveryFee` ve `MinimumOrderAmount` ayarlanabiliyor
  - `IsActive` flag'i ile zone aktif/pasif yapılabiliyor

### ✅ API Endpoint'leri
- **Durum:** Tamamlandı
- **Controller:** `src/Talabi.Api/Controllers/Vendors/DeliveryZonesController.cs` ⚠️ **Vendor Dashboard Controller**
- **Route:** `/api/vendors/dashboard/delivery-zones`
- **Endpoint'ler:**
  - `GET /api/vendors/dashboard/delivery-zones?cityId={cityId}` - Zone'ları getirir
  - `PUT /api/vendors/dashboard/delivery-zones` - Zone'ları senkronize eder
- **⚠️ Not:** Bu endpoint'ler sadece vendor dashboard için kullanılır. Customer tarafından kullanılmaz.

### ✅ Mobile Implementasyonu
- **Durum:** Tamamlandı
- **Dosya:** `mobile/lib/features/profile/presentation/screens/vendor/delivery_zones_screen.dart`
- **Endpoint:** `VendorApiEndpoints.deliveryZones` kullanılıyor
- **Özellikler:**
  - Şehir seçimi
  - İlçe ve mahalle bazlı zone yönetimi
  - Zone'ları aktif/pasif yapma

### ⚠️ Not: Delivery Zone vs Delivery Radius
- **Delivery Radius:** Basit, dairesel teslimat alanı (5 km yarıçap gibi)
- **Delivery Zone:** Detaylı, mahalle bazlı teslimat alanları
- **Öneri:** İki sistem birlikte kullanılabilir. Delivery Zone varsa öncelikli, yoksa Delivery Radius kullanılabilir.

---

## 7. API Yapısı ve Endpoint Ayrımı

### ⚠️ ÖNEMLİ: Customer vs Vendor Dashboard Endpoint'leri

Sistemde iki farklı endpoint yapısı mevcuttur:

#### Customer-Facing Endpoint'ler (`Controllers` altında - direkt)
**Kullanım:** Mobile customer ekranları, web customer sayfaları
- `GET /api/vendors` - Vendor listesi (customer için)
- `GET /api/vendors/{id}/products` - Vendor ürünleri (customer için)
- `GET /api/products` - Ürün arama/listeleme (customer için)
- `GET /api/products/search` - Ürün arama (customer için)
- `GET /api/products/popular` - Popüler ürünler (customer için)
- `GET /api/products/similar` - Benzer ürünler (customer için)
- `GET /api/cart` - Sepet işlemleri (customer için)
- `POST /api/orders` - Sipariş oluşturma (customer için)

**Controller'lar:**
- `Controllers/VendorsController.cs` - Customer için vendor listeleme
- `Controllers/ProductsController.cs` - Customer için ürün listeleme/arama
- `Controllers/CartController.cs` - Customer için sepet işlemleri
- `Controllers/OrdersController.cs` - Customer için sipariş işlemleri

#### Vendor Dashboard Endpoint'leri (`Controllers/Vendors/` altında)
**Kullanım:** Sadece vendor dashboard (mobile vendor ekranları, portal vendor paneli)
- `GET /api/vendors/dashboard/account/profile` - Vendor profil getirme
- `PUT /api/vendors/dashboard/account/profile` - Vendor profil güncelleme
- `PUT /api/vendors/dashboard/account/settings` - Vendor ayarlar güncelleme (DeliveryRadiusInKm dahil)
- `GET /api/vendors/dashboard/products` - Vendor ürün listesi (dashboard için)
- `POST /api/vendors/dashboard/products` - Vendor ürün oluşturma
- `GET /api/vendors/dashboard/delivery-zones` - Delivery zone yönetimi
- `GET /api/vendors/dashboard/orders` - Vendor sipariş listesi
- `GET /api/vendors/dashboard/reports` - Vendor raporları

**Controller'lar:**
- `Controllers/Vendors/AccountController.cs` - Vendor profil ve ayarlar
- `Controllers/Vendors/ProductsController.cs` - Vendor ürün yönetimi
- `Controllers/Vendors/OrdersController.cs` - Vendor sipariş yönetimi
- `Controllers/Vendors/ReportsController.cs` - Vendor raporları
- `Controllers/Vendors/DeliveryZonesController.cs` - Delivery zone yönetimi
- `Controllers/Vendors/NotificationsController.cs` - Vendor bildirimleri

### 📱 Mobile Endpoint Kullanımı

#### Customer Mobile Ekranları
- **Constants:** `mobile/lib/core/constants/api_constants.dart`
- **Endpoint'ler:** `Controllers` altındaki direkt endpoint'ler
- **Örnek:** `ApiEndpoints.vendors`, `ApiEndpoints.products`, `ApiEndpoints.cart`

#### Vendor Mobile Dashboard
- **Constants:** `mobile/lib/core/constants/vendor_api_constants.dart`
- **Endpoint'ler:** `Controllers/Vendors/` altındaki dashboard endpoint'leri
- **Örnek:** `VendorApiEndpoints.profile`, `VendorApiEndpoints.products`, `VendorApiEndpoints.settings`

### ⚠️ Kritik Kural
**Customer ekranları ASLA `Controllers/Vendors/` altındaki endpoint'leri kullanmamalıdır.**
- ✅ Doğru: Customer için `GET /api/vendors` (Controllers/VendorsController.cs)
- ❌ Yanlış: Customer için `GET /api/vendors/dashboard/account/profile` (Controllers/Vendors/AccountController.cs)

Eğer customer için yeni bir endpoint gerekiyorsa, `Controllers` altında direkt oluşturulmalıdır.

---

## Teknik Notlar

### Coğrafi Hesaplama
- ✅ **Haversine Formülü:** `GeoHelper.CalculateDistance` metodu kullanılıyor
- ✅ **SQL Server Geography:** Şu an için kullanılmıyor (performans yeterli)
- ✅ **Memory-Based Filtering:** Entity Framework SQL'e çeviremediği için memory'de filtreleme yapılıyor

### Performans Optimizasyonları
- ✅ **Index Kullanımı:** Vendor tablosunda `Latitude`, `Longitude`, `IsActive` index'leri mevcut
- ✅ **Query Optimization:** Önce aktif vendor'lar filtreleniyor, sonra mesafe hesaplanıyor
- ✅ **Caching:** Vendor listesi için cache mekanizması mevcut (`ICacheService`)

### API Entegrasyonu
- ✅ **Google Maps API:** Distance Matrix API kullanılıyor
- ✅ **API Key Yapılandırması:** `appsettings.json` içinde `GoogleMaps:ApiKey`
- ✅ **API Key Endpoint:** `GET /api/map/api-key` (frontend için)
- ✅ **Error Handling:** API hatası durumunda fallback mekanizması çalışıyor

---

## ⚠️ Öneriler ve İyileştirmeler

### 1. Migration Veri Güncellemesi (Öncelikli)
Mevcut veritabanındaki kayıtlar için:
```sql
UPDATE Vendors SET DeliveryRadiusInKm = 5 WHERE DeliveryRadiusInKm = 0;
```

### 2. Delivery Zone Entegrasyonu
- **Öneri:** Delivery Zone sistemi ile Delivery Radius sistemini birleştir
- **Mantık:** Eğer vendor'ın aktif Delivery Zone'ları varsa, sadece o zone'lara teslimat yapılabilir. Zone yoksa Delivery Radius kullanılır.

### 3. Performans İyileştirmeleri
- **SQL Geography Tipi:** Büyük ölçekte performans için SQL Server `Geography` tipi kullanılabilir
- **Spatial Index:** Coğrafi sorgular için spatial index eklenebilir
- **Redis Cache:** Vendor listesi için Redis cache kullanılabilir

### 4. Test Kapsamı
- ✅ **Unit Testler:** `OrderAssignmentServiceTests`, `OrderServiceTests` mevcut
- ⚠️ **Integration Testler:** Delivery radius kontrolü için integration testler yazılabilir
- ⚠️ **E2E Testler:** Mobile'dan sipariş oluşturma akışı test edilebilir

### 5. Dokümantasyon
- ✅ **API Dokümantasyonu:** Swagger/OpenAPI dokümantasyonu mevcut
- ⚠️ **Business Logic Dokümantasyonu:** Delivery fee hesaplama mantığı dokümante edilebilir

### 6. Gelecek Özellikler
- [ ] **Dinamik Kurye Yarıçapı:** Kuryeler için de dinamik yarıçap sistemi
- [ ] **Zaman Bazlı Ücretlendirme:** Gece, hafta sonu gibi zaman dilimlerinde farklı ücretler
- [ ] **Trafik Durumu Entegrasyonu:** Google Maps Traffic API ile gerçek zamanlı teslimat süresi
- [ ] **Multi-Stop Delivery:** Bir kuryenin birden fazla siparişi aynı anda teslim etmesi
- [ ] **Delivery Zone Priority:** Zone bazlı öncelik sistemi (VIP bölgeler gibi)

---

## 📝 Sonuç

**Tüm temel maddeler başarıyla tamamlanmış durumda!** ✅

Sistem, dinamik yarıçap modeline tam olarak geçiş yapmış ve tüm özellikler kod tabanında mevcut. Delivery Zone sistemi de mevcut ve vendor'lar hem basit yarıçap hem de detaylı zone yönetimi yapabiliyor.

**Öncelikli Aksiyonlar:**
1. ✅ Mevcut veritabanındaki `DeliveryRadiusInKm = 0` olan kayıtları `5` olarak güncellemek için bir script çalıştırılmalı.
2. ⚠️ Delivery Zone ve Delivery Radius sistemlerinin birlikte çalışma mantığı netleştirilmeli.
3. ⚠️ Performans testleri yapılmalı (özellikle çok sayıda vendor olduğunda).

**Son Güncelleme:** 2025-01-09

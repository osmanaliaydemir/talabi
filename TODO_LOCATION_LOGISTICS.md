# Konum ve Lojistik Altyapı Planı (Location & Logistics Roadmap)

Rastgele "5 km kare" mantığı yerine, her işletmenin kendi kapasitesine göre belirleyebileceği **"Dinamik Yarıçap (Dynamic Radius)"** modeline geçiş planıdır. Bu yapı, sistemi hem teknik olarak daha doğru hem de ticari olarak ölçeklenebilir kılacaktır.

## 1. Veritabanı ve Backend Altyapısı (Temel)

Bu aşama, sistemin "sabit 5 km" mantığından "dinamik mesafe" mantığına geçişi için zorunludur.

- [x] **Entity Güncellemesi (`Vendor`):**
  - `DeliveryRadiusInKm` (int) sütunu eklenecek.
  - **Varsayılan Değer:** `5` (km).
  - *Açıklama:* Her restoranın varsayılan olarak 5 km menzili olacak, ancak bu değer panelden değiştirilebilecek.
  - ✅ **Durum:** `Vendor.cs` dosyasında satır 18'de `public int DeliveryRadiusInKm { get; set; } = 5;` olarak tanımlı.
- [x] **Veritabanı Migration:**
  - `dotnet ef migrations add AddDeliveryRadiusToVendor` işlemi ve veritabanı güncellemesi.
  - ✅ **Durum:** Migration dosyası mevcut: `20260109090508_AddDeliveryRadiusToVendor.cs`
  - ⚠️ **Not:** Migration'da `defaultValue: 0` olarak ayarlanmış, ancak entity'de varsayılan değer 5. Mevcut kayıtlar için veri güncellemesi gerekebilir.
- [x] **DTO Güncellemeleri:**
  - `VendorDto` (Okuma) ve `UpdateVendorDto` (Yazma) nesnelerine bu alanın eklenmesi.
- [x] **API Endpoint Güncellemesi:**
  - Satıcı kendi profilini güncellerken (`VendorProfileController`) bu alanı değiştirebilmeli.

## 2. Müşteri Tarafı: Akıllı Listeleme (Discovery)

Müşterinin sipariş veremeyeceği restoranları görüp hayal kırıklığına uğramasını engellemek için filtreleme en başta yapılmalıdır.

- [x] **Backend Query Güncellemesi (`VendorsController`):**
  - Mevcut "Yakındaki Restoranlar" sorgusu güncellenecek.
  - **Eski Mantık:** `Distance < SabitDeger`
  - **Yeni Mantık:** `Distance(Customer, Vendor) <= Vendor.DeliveryRadiusInKm`
  - *Müşteri restoranın kapsama alanındaysa restoran listelenecek.*

## 3. Kurye Atama Sistemi (Dispatching)

Siparişin restorandan kuryeye aktarılması sürecinin lojistik optimizasyonu.

- [x] **Sipariş Yayını (Broadcast):**
  - Sipariş durumu `Ready` (Hazır) olduğunda tetiklenir.
  - **Merkez Nokta:** Restoranın konumu.
  - **Arama Alanı:** Restoranın çevresindeki **5 km yarıçap** (sabit kalabilir veya sistem ayarı olabilir).
  - Bu alandaki `Status = Online` ve `State = Idle` (Boşta) olan kuryelere teklif gönderilir.

## 4. İleri Seviye Lojistik & Ekonomi (Future Features)

Temel yapı oturduktan sonra, sistemin kârlılığını korumak için eklenecek kurallar.

- [x] **Kademeli Teslimat Ücreti (Tiered Delivery Fee):** Mesafe arttıkça kuryeye ödenecek rakamın ve müşteriden alınacak ücretin artması (Örn: 0-2 km: Ücretsiz | 2-5 km: 20 TL | 5+ km: 35 TL).
- [x] **Dinamik Minimum Sepet Tutarı (Dynamic Threshold):** Yakın mesafe (0-2 km) için 100 TL, uzak mesafe (5+ km) için 300 TL gibi kurallar.
- [x] **Yol Mesafesi Doğrulaması (Router Check):** Harita API entegrasyonu ile kuş uçuşu yerine gerçek yol mesafesi kontrolü./nehir/otoban gibi engeller için Google Maps API ile gerçek sürüş rotasının kontrol edilmesi.
  - ✅ **Durum:** `GoogleMapService` implementasyonu mevcut ve `GetRoadDistanceAsync` metodu Google Maps Distance Matrix API kullanıyor.
  - ✅ **Kullanım:** `OrderAssignmentService.CalculateDeliveryFee` metodunda gerçek yol mesafesi hesaplanıyor (satır 861-866).
  - ✅ **Fallback:** API hatası durumunda kuş uçuşu mesafesi (`crowFlyDistance`) kullanılıyor (satır 868).

## Teknik Notlar

- **Coğrafi Hesaplama:** SQL Server `Geography` veri tipi veya `Haversine` formülü kullanılarak performanslı filtreleme yapılacak.

- **Varsayılan Davranış:** Sistem ilk açıldığında migration ile tüm mevcut restoranların menzili `5 km` olarak ayarlanacak, böylece mevcut işleyiş bozulmayacak.

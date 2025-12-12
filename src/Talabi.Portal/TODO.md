# Vendor Dashboard API Geliştirmeleri (Backend - Talabi.Api)

Bu liste, zengin bir Vendor Dashboard deneyimi için Talabi.Api projesinde yapılması gereken geliştirmeleri içerir.

## 1. Gelişmiş Özet İstatistikleri (Enriched Summary)
- [x] `VendorReportsController.GetSummary` endpoint'ini güncelle.
- [x] Eklenecek Alanlar:
    - [x] `AverageOrderValue` (Ortalama Sepet Tutarı)
    - [x] `CancellationRate` (İptal Oranı)
    - [x] `RatingSummary` (Ortalama Puan, Toplam Değerlendirme)
    - [x] `ActiveProductsCount` (Aktif Ürün Sayısı)

## 2. Son Aktiviteler Akışı (Recent Activity Feed)
- [x] Yeni Endpoint: `GET /api/vendor/dashboard/activities` (Portal içinde uygulandı)
- [x] Kapsam: Son X olayı listele (Yeni sipariş, yeni yorum, stok uyarısı vb.)
- [x] UI: Dashboard sayfasına "Son Aktiviteler" bölümü eklendi.

## 3. Anlık Mağaza Durumu (Real-time Status)
- [x] `Vendor` entity'sine `BusyStatus` (Normal, Busy, Overloaded) ekle.
- [x] Yoğunluğa göre tahmini teslimat süresi hesaplama mantığını güncelle.
- [x] Header'a `BusyStatus` dropdown'ı eklendi (Anlık güncelleme)

## 4. Grafik Verileri (Advanced Charts)
- [ ] Yeni Endpoint: `GET /api/vendor/reports/hourly-sales` (Saatlik satış yoğunluğu - Bugün için)
- [ ] Büyüme Oranları: Geçen haftanın aynı gününe göre değişim yüzdeleri.

## 5. Aksiyon Kartları (Alerts & Insights)
- [ ] Yeni Endpoint: `GET /api/vendor/dashboard/alerts`
- [ ] İçerik:
    - [ ] **Kritik Stok:** Stoğu azalan ürünler.
    - [ ] **Geciken Siparişler:** Hazırlanma süresini aşan siparişler.
    - [ ] **Cevaplanmayan Yorumlar:** Bekleyen yorum sayıları.

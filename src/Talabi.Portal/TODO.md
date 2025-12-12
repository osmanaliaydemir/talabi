# Vendor Dashboard API Geliştirmeleri (Backend - Talabi.Api)

Bu liste, zengin bir Vendor Dashboard deneyimi için Talabi.Api projesinde yapılması gereken geliştirmeleri içerir.

## 1. Gelişmiş Özet İstatistikleri (Enriched Summary)
- [ ] `VendorReportsController.GetSummary` endpoint'ini güncelle.
- [ ] Eklenecek Alanlar:
    - [ ] `AverageOrderValue` (Ortalama Sepet Tutarı)
    - [ ] `CancellationRate` (İptal Oranı)
    - [ ] `RatingSummary` (Ortalama Puan, Toplam Değerlendirme)
    - [ ] `ActiveProductsCount` (Aktif Ürün Sayısı)

## 2. Son Aktiviteler Akışı (Recent Activity Feed)
- [ ] Yeni Endpoint: `GET /api/vendor/dashboard/activities`
- [ ] Kapsam: Son X olayı listele (Yeni sipariş, yeni yorum, stok uyarısı vb.)

## 3. Anlık Mağaza Durumu (Real-time Status)
- [ ] `Vendor` entity'sine `BusyStatus` (Normal, Busy, Overloaded) ekle.
- [ ] Yoğunluğa göre tahmini teslimat süresi hesaplama mantığını güncelle.

## 4. Grafik Verileri (Advanced Charts)
- [ ] Yeni Endpoint: `GET /api/vendor/reports/hourly-sales` (Saatlik satış yoğunluğu - Bugün için)
- [ ] Büyüme Oranları: Geçen haftanın aynı gününe göre değişim yüzdeleri.

## 5. Aksiyon Kartları (Alerts & Insights)
- [ ] Yeni Endpoint: `GET /api/vendor/dashboard/alerts`
- [ ] İçerik:
    - [ ] **Kritik Stok:** Stoğu azalan ürünler.
    - [ ] **Geciken Siparişler:** Hazırlanma süresini aşan siparişler.
    - [ ] **Cevaplanmayan Yorumlar:** Bekleyen yorum sayıları.

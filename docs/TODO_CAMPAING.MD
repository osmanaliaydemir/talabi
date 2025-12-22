# 🚀 Talabi Kampanya Modülü Geliştirme Yol Haritası (TODO)

Bu belge, Kampanyalar modülünün profesyonel bir sadakat ve indirim sistemine dönüştürülmesi için gereken teknik ve fonksiyonel iyileştirmeleri içerir.

---

## 🏗️ 1. Veritabanı Katmanı (Database)

- [ ] **Kullanım Limitleri:**
  - `MaxUsageCount`: Kampanyanın toplam kaç kez kullanılabileceği (Bütçe yönetimi).
  - `UsageLimitPerUser`: Bir müşterinin bu kampanyadan en fazla kaç kez yararlanabileceği.
  - `CurrentUsageCount`: Mevcut kullanım sayısının takibi.
- [ ] **Gelişmiş Zamanlama:**
  - `ValidDaysOfWeek`: Kampanyanın haftanın hangi günlerinde (Pazartesi, Hafta Sonu vb.) aktif olacağının belirlenmesi.
- [ ] **Dışlama Kuralları (Exclusions):**
  - `ExcludedCategoryIds`: Belirli kategorileri indirim kapsamı dışında bırakma.
  - `ExcludedProductIds`: Belirli ürünleri indirim kapsamı dışında bırakma.
- [ ] **Bütçe Takibi:**
  - `TotalDiscountBudget`: Kampanya için ayrılan toplam indirim bütçesi (Bütçe dolunca kampanya otomatik durur).

---

## ⚙️ 2. Backend & İş Mantığı (API)

- [ ] **Öğe Bazlı İndirim Hesaplaması (Item-Based Calculation):**
  - İndirimin tüm sepet yerine sadece kampanya şartlarına uyan ürünlerin alt toplamına uygulanması.
  - *Örn:* "İçeceklerde %10 indirim" varken hamburgerin fiyata dahil edilmemesi.
- [ ] **İndirim Çakışma Yönetimi (Stacking Logic):**
  - `IsStackable`: Kampanyanın diğer kupon/kampanyalarla birleşip birleşemeyeceğinin kontrolü.
  - Birden fazla indirim mevcutsa "En yüksek indirim" veya "Öncelik sırasına göre" seçim algoritması.
- [ ] **Zenginleştirilmiş Hata Mesajları:**
  - Teknik hata kodları yerine kullanıcıyı aksiyona iten mesajların dönülmesi.
  - *Örn:* "İndirim için sepetinize 20 TL daha ürün eklemelisiniz."

---

## 📱 3. Mobil Uygulama (Mobile App)

- [ ] **Şeffaf Sipariş Özeti:**
  - İndirimin hangi kuralla (hangi kampanya/kupon) ve hangi ürünlere uygulandığının net gösterimi.
- [ ] **Kampanya Keşif Deneyimi:**
  - Kampanya detayına tıklandığında, o kampanyanın geçerli olduğu ürünleri filtreleyerek listeleyen özel bir ekran (In-App Search/Filter).
- [ ] **Dinamik Yönlendirmeler:**
  - Sepet sayfasında henüz uygulanmamış ama "uygulanmaya yakın" kampanyaların kullanıcıya önerilmesi.

---

## 🖥️ 4. Yönetim Portalı (Portal)

- [ ] **İstatistik Dashboard:**
  - Kampanya kullanım sayıları, toplam indirim maliyeti ve kampanya üzerinden gelen toplam ciro takibi.
  - ROI (Yatırım Getirisi) analizi.
- [ ] **Medya Yönetimi (File Upload):**
  - `ImageUrl` alanının manuel girilmesi yerine, portal üzerinden görsel yükleyerek (Azure/S3/Local) otomatik URL oluşturulması.
- [ ] **Kullanıcı Bazlı Kampanya Atama:**
  - Belirli bir müşteri grubuna veya sadece "yeni üyelere" özel kampanya oluşturma arayüzü.

---

## 📝 Notlar

* **Öncelik 1:** Kullanım limitleri ve bütçe yönetimi (Finansal güvenlik).
- **Öncelik 2:** Öğe bazlı indirim hesaplama (Doğru fiyatlandırma).
- **Öncelik 3:** Portal üzerinden raporlama ve görsel yükleme (Operasyonel kolaylık).

# 🚀 Talabi Gelişmiş Kampanya ve İndirim Modülü Rehberi

Bu belge, Talabi platformunun yenilenen gelişmiş kampanya altyapısının özelliklerini, kullanım kurallarını ve yönetim detaylarını kapsar.

---

## 📋 1. Kampanya Yönetimi (Genel Bakış)

Talabi Yönetim Portalı üzerinden oluşturulan kampanyalar, artık sadece basit görsel bannerlar değil; karmaşık kurallara, hedef kitlelere ve bütçe limitlerine sahip **akıllı indirim motorlarıdır**.

### Temel Özellikler

- **Görsel:** Kampanya afişi (Dosya yükleme destekli).
- **Başlık & Açıklama:** Kullanıcıya gösterilen metinler.
- **Öncelik (Priority):** Hangi kampanyanın listede üstte çıkacağı.
- **Durum:** Aktif/Pasif kontrolü.

---

## 🛡️ 2. Kurallar ve Kısıtlamalar (Rules & Limits)

Kampanyaların suistimal edilmesini önlemek ve pazarlama bütçesini korumak için aşağıdaki kısıtlamalar tanımlanabilir:

### 2.1 Kullanım Limitleri

- **Max Usage Count (Toplam Limit):** Kampanyadan toplamda kaç kez yararlanılabileceğini belirler. (Örn: "İlk 100 kişiye özel").

- **Usage Limit Per User (Kişi Başı Limit):** Bir kullanıcının kampanyayı en fazla kaç kez kullanabileceği. (Örn: "Her kullanıcı 1 kez faydalanabilir").
- **Total Discount Budget (Bütçe Limiti):** Kampanya kapsamında verilecek toplam indirim tutarı. Bu limite ulaşıldığında kampanya otomatik olarak durdurulur.

### 2.2 Zamanlama (Scheduling)

- **Tarih Aralığı:** Başlangıç ​​ve Bitiş tarihleri.
- **Saat Aralığı (Time Slots):** Gün içinde sadece belirli saatlerde geçerli olması (Örn: "Happy Hour 14:00 - 17:00").
- **Haftanın Günleri (Valid Days):** Sadece belirli günlerde aktif olması (Örn: "Sadece Hafta Sonları").

### 2.3 Hedef Kitle (Audience Targeting)

Kampanyanın kimlere gösterileceğini ve kimlerin yararlanabileceğini belirler:

- **All Users:** Herkese açık.
- **New Users:** Daha önce hiç sipariş vermemiş kullanıcılar (İlk Sipariş Kampanyası).
- **Returning Users:** Daha önce en az bir siparişi olan sadık müşteriler.
- **VIP Users:** Özel müşteri segmenti.

---

## 🧮 3. İndirim Mantığı (Calculation Logic)

İndirimlerin nasıl hesaplandığı ve hangi ürünlere uygulandığı bu bölümde detaylandırılmıştır.

### 3.1 İndirim Türleri

- **Percentage (%):** Sepet veya ürün tutarı üzerinden yüzde indirimi.
- **Fixed Amount (Tutar):** Sabit para miktarı kadar indirim (Örn: 50 TL).

### 3.2 İndirim Kapsamı (Scope)

- **Cart-Based:** İndirim sepetin toplam tutarına uygulanır.
- **Item-Based:** İndirim **sadece kampanya koşullarını sağlayan ürünlerin** toplamına uygulanır. Diğer ürünler etkilenmez.

### 3.3 Filtreleme ve Dışlamalar (Inclusions & Exclusions)

- **Vendor Type:** Sadece belirli satıcı tiplerinde (Market veya Restoran) geçerli olabilir.
- **Excluded Categories:** Belirli kategoriler (örn: Sigara, Temel Gıda) kampanya dışı bırakılabilir.
- **Excluded Products:** Spesifik ürünler kampanya dışı bırakılabilir.

### 3.4 Çakışma Yönetimi (Stacking)

- **Is Stackable:** Bu özellik işaretlenirse, kampanya diğer indirimlerle birleşebilir. İşaretli değilse, sistem en yüksek indirimi sağlayan tek kampanyayı uygular.

---

## 🖼️ 4. Medya Yönetimi

Kampanya görselleri artık harici URL girmek yerine doğrudan Portal üzerinden yüklenebilir.

- **Formatlar:** .jpg, .png, .webp
- **Boyut:** Maksimum 5MB
- **Depolama:** Güvenli bir şekilde sunucuda saklanır ve otomatik isimlendirilir.

---

## 📊 5. İstatistik ve Raporlama

Portal Dashboard ekranında kampanya performansları anlık izlenebilir:

- **En Çok Satanlar:** Kampanyalı ürünlerin satış performansı.
- **Kategori Bazlı Ciro:** Hangi kategorilerin kampanyalardan daha çok etkilendiği.
- **Sipariş Durumları:** Kampanyalı siparişlerin tamamlanma oranları.

---

## 📱 6. Mobil Uygulama Deneyimi

Kullanıcı tarafındaki deneyim şu şekildedir:

1. **Keşfet:** Kampanyalar ana ekranda ve Kampanyalar sekmesinde listelenir.
2. **Detay:** Kampanyaya tıklandığında, **sadece o kampanyaya dahil olan ürünlerin** listelendiği özel bir sayfaya gidilir.
3. **Sepet:**
    - İndirim otomatik uygulanır.
    - Hangi ürünlerin ne kadar indirim aldığı şeffaf şekilde gösterilir.
    - Minimum sepet tutarına yaklaşınca "X TL daha ekle, indirimi kap!" önerisi çıkar.

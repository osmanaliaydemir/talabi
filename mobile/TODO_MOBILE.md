# Mobile Yapılacaklar Listesi

## 1. Üyelik Sözleşmeleri (Üye Ol Ekranları)

Aşağıdaki kullanıcı rolleri için ayrı ayrı üyelik sözleşmesi onay alanları eklenecek:

- [x] **Müşteri (Customer):** Kayıt ekranına (`lib/features/auth/presentation/screens/customer/`) "Müşteri Üyelik Sözleşmesi" onay kutusu ve metni eklenecek.
- [x] **Satıcı (Vendor):** Kayıt ekranına (`lib/features/auth/presentation/screens/vendor/`) "Satıcı Üyelik Sözleşmesi" onay kutusu ve metni eklenecek.
- [x] **Kurye (Courier):** Kayıt ekranına (`lib/features/auth/presentation/screens/courier/`) "Kurye Üyelik Sözleşmesi" onay kutusu ve metni eklenecek.

**Teknik Detaylar:**

- [x] Sözleşme metinleri API üzerinden çekilecek.
- [x] Çoklu dil (Localization) desteği sağlanacak (TR, EN, AR).
- [x] Onay kutusu işaretlenmeden kayıt işlemine izin verilmeyecek.

## 2. Sipariş Sözleşmesi (Ödeme Ekranı)

Müşteri ödeme (Checkout) aşamasında, siparişi tamamlamadan önce onaylaması gereken bir sözleşme alanı eklenecek:

- [x] **Mesafeli Satış Sözleşmesi & Ön Bilgilendirme Formu:** Ödeme ekranına (`lib/features/orders/presentation/screens/customer/checkout_screen.dart`) onay kutusu ve metni eklenecek.

**Teknik Detaylar:**

- [x] Sözleşme metni API üzerinden dinamik olarak getirilecek.
- [x] Dil desteği (TR, EN, AR) aktif olacak.
- [x] Onay kutusu zorunlu tutulacak.

## 3. KVKK ve Pazarlama İzinleri (Kayıt Ekranları)

- [x] **KVKK Aydınlatma Metni:** Tüm kayıt ekranlarına (Customer, Vendor, Courier) "KVKK Aydınlatma Metni'ni okudum" onay alanı eklenecek.
- [x] **Ticari Elektronik İleti Onayı:** Kayıt ekranlarına "Kampanya, indirim ve duyurulardan haberdar olmak istiyorum" onay kutusu (isteğe bağlı/optional) eklenecek.

## 4. Uygulama Mağazası ve Yasal Uyumluluk (Profil/Ayarlar)

- [x] **Hesap Silme (Delete Account):** Kullanıcının hesabını uygulama içinden tamamen silebilmesi/kapatabilmesi için gerekli buton ve onay mekanizması eklenecek (App Store zorunluluğu).
- [x] **Künye ve İletişim Bilgileri:** ETK gereği firmanın resmi ünvanı, MERSİS no ve iletişim bilgilerinin yer alacağı bir alan eklenecek.

---
*Not: API bağlantıları için `services/` altındaki ilgili servisler güncellenmeli ve `l10n/` altındaki `.arb` dosyalarına gerekli anahtarlar eklenmelidir.*

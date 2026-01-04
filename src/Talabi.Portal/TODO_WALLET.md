# Wallet (Cüzdan) Modülü Yapılacaklar Listesi

Bu döküman, Talabi projesine eklenecek olan Wallet (Cüzdan) modülü için gerekli geliştirme adımlarını içerir.

## 1. Backend (Veritabanı & Core)

- [ ] **Entity'lerin Oluşturulması** (`Talabi.Core/Entities`)
  - [ ] `Wallet.cs`: Kullanıcı (`AppUser`) ile birebir ilişkili cüzdan varlığı.
    - Özellikler: `Id`, `AppUserId`, `Balance` (decimal), `Currency` (string, default "TRY"), `CreatedDate`, `UpdatedDate`.
  - [ ] `WalletTransaction.cs`: Cüzdan hareketlerini tutan varlık.
    - Özellikler: `Id`, `WalletId`, `Amount` (decimal), `TransactionType` (Enum), `Description`, `ReferenceId` (Sipariş No vb.), `TransactionDate`.
  - [ ] `TransactionType` Enum (`Talabi.Core/Enums`):
    - `Deposit` (Para Yükleme)
    - `Withdrawal` (Para Çekme)
    - `Payment` (Ödeme Yapma - Harcama)
    - `Refund` (İade Alma)
    - `Earning` (Satış veya Teslimat Kazancı)

- [ ] **Veritabanı Yapılandırması**
  - [ ] `ApplicationDbContext` üzerine `DbSet<Wallet>` ve `DbSet<WalletTransaction>` eklenmesi.
  - [ ] Entity configuration (Fluent API) ayarlarının yapılması (özellikle Decimal precision ayarları).
  - [ ] Migration oluşturulması: `dotnet ef migrations add AddWalletModule`
  - [ ] Veritabanı güncellemesi: `dotnet ef database update`

## 2. Backend (API & Business Logic)

- [ ] **Servis Katmanı (WalletService)**
  - [ ] `IWalletService` arayüzünün tanımlanması.
  - [ ] `GetBalanceAsync(string userId)`: Güncel bakiye sorgulama.
  - [ ] `DepositAsync(string userId, decimal amount, string description)`: Bakiye artırma.
  - [ ] `WithdrawAsync(string userId, decimal amount)`: Bakiye azaltma (Yetersiz bakiye kontrolü ile).
  - [ ] `ProcessPaymentAsync(string userId, decimal amount, string orderId)`: Sipariş ödemesi işleme (Transactional).

- [ ] **API Controller (WalletController)**
  - [ ] `GET /api/wallet`: Kullanıcının cüzdan özetini (Bakiye) getirir.
  - [ ] `GET /api/wallet/transactions`: İşlem geçmişini sayfalı (pagination) olarak getirir.
  - [ ] `POST /api/wallet/deposit`: Bakiye yükleme (Mock veya Payment Gateway entegrasyonu).
  - [ ] `POST /api/wallet/withdraw`: Para çekme talebi (IBAN'a aktarım isteği).

## 3. Mobil Uygulama (Müşteri Deneyimi)

- [ ] **Veri Katmanı (Data Domain)**
  - [ ] `Wallet` ve `WalletTransaction` modellerinin Dart (`lib/features/wallet/data/models`) tarafında oluşturulması.
  - [ ] `ApiService` içerisine Wallet endpoint isteklerinin eklenmesi.

- [ ] **Kullanıcı Arayüzü (UI)**
  - [ ] `WalletScreen`:
    - Cüzdan Kartı (Bakiye Gösterimi).
    - "Bakiye Yükle" butonu.
    - Son İşlemler Listesi (Transaction History).
  - [ ] `TopUpScreen`: Bakiye yükleme ekranı (Hazır tutarlar veya manuel giriş).
  - [ ] `ProfileScreen` menüsüne "Cüzdanım" seçeneğinin eklenmesi.

- [ ] **Ödeme Entegrasyonu**
  - [ ] `CheckoutScreen` (Ödeme Ekranı) revizyonu.
  - [ ] Ödeme yöntemleri arasına "Cüzdan ile Öde" seçeneğinin eklenmesi.
  - [ ] Cüzdan bakiyesi sipariş tutarını karşılıyorsa direkt ödeme, karşılamıyorsa "Yetersiz Bakiye" uyarısı.

## 4. Mobil Uygulama (Satıcı ve Kurye Entegrasyonu)

- [ ] **Satıcı (Vendor) Paneli**
  - [ ] Sipariş tamamlandığında hak edişin otomatik olarak satıcı cüzdanına `Earning` tipiyle eklenmesi (Backend tarafında Domain Event ile).
  - [ ] Satıcı Dashboard'unda "Toplam Kazanç" yerine "Cüzdan Bakiyesi" vurgusu.
  - [ ] Para Çekme (Withdraw) talep ekranı.

- [ ] **Kurye (Courier) Paneli**
  - [ ] `CourierEarning` tablosunun `WalletTransaction` yapısına entegre edilmesi veya senkronize çalışması.
  - [ ] Mevcut `EarningsScreen`'in Cüzdan yapısına dönüştürülmesi.
  - [ ] Teslimat başı kazançların anlık olarak cüzdana yansıması.

## 5. Test ve Güvenlik

- [ ] **Concurrency (Eşzamanlılık) Testleri:** Aynı anda birden fazla ödeme/yükleme işleminde bakiye tutarlılığı.
- [ ] **Transaction Log:** Her işlemin loglanması ve izlenebilirliği.
- [ ] **Validation:** Negatif bakiye yükleme/çekme engelleri.

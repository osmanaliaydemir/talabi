# Getir Merchant Portal

Modern, responsive ve kullanıcı dostu bir merchant (satıcı) yönetim paneli. Market ve restoran sahipleri için geliştirilmiş ASP.NET Core MVC uygulaması.

## 🎯 Özellikler

### ✅ Tamamlanan Özellikler

#### 1. Kimlik Doğrulama & Yetkilendirme
- JWT tabanlı API authentication
- Cookie-based session yönetimi
- Güvenli login/logout
- 12 saat token geçerliliği

#### 2. Dashboard (Ana Sayfa)
- **Gerçek zamanlı metrikler:**
  - Günlük ciro ve sipariş sayısı
  - Bekleyen sipariş sayısı
  - Aktif ürün sayısı
  - Ortalama değerlendirme
- **Haftalık ve aylık performans grafikleri**
- **Son siparişler listesi** (son 5)
- **En çok satılan ürünler** (top 5)
- 30 saniyede bir otomatik yenileme

#### 3. Ürün Yönetimi
- **Ürün listeleme** (sayfalama ile)
- **Yeni ürün ekleme** (CRUD)
  - Ürün adı, açıklama
  - Fiyat ve indirimli fiyat
  - Stok miktarı ve birim
  - Kategori seçimi
  - Görsel URL
  - Aktif/Pasif durumu
- **Ürün düzenleme**
- **Ürün silme** (onay ile)
- **Görsel önizleme**
- **Stok durumu gösterimi**

#### 4. Sipariş Yönetimi
- **Sipariş listeleme**
  - Tüm siparişler
  - Durum filtreleme (Bekleyen, Hazırlanıyor, Tamamlandı)
  - Sayfalama
- **Sipariş detayları**
  - Müşteri bilgileri
  - Teslimat adresi
  - Sipariş içeriği
  - Tutar detayları
- **Sipariş durumu güncelleme**
  - Pending → Confirmed → Preparing → Ready → OnTheWay → Delivered
  - Sipariş iptal etme
- **Sipariş timeline** (görsel takip)

#### 5. UI/UX Özellikleri
- **Modern ve responsive tasarım** (Bootstrap 5)
- **Getir marka renkleri** (Mor #5D3EBC, Sarı #FFD300)
- **Sidebar navigasyon**
- **Kullanıcı profil menüsü**
- **Toast bildirimleri** (başarı/hata)
- **Font Awesome ikonları**
- **Hover efektleri ve animasyonlar**
- **Mobil uyumlu**

### 🎉 NEW! SignalR Real-time Features (COMPLETED!)

1. **✅ Real-time Order Notifications**
   - Yeni sipariş anında bildirim
   - Toast notification + sound alert
   - Browser tab flash
   - Auto-update dashboard

2. **✅ Live Order Status Updates**
   - Sipariş durumu değişikliklerinde anında güncelleme
   - Visual timeline tracking
   - Connection status indicator

3. **✅ Toast Notification System**
   - Animated notifications (success, warning, danger, info)
   - Auto-dismiss with custom duration
   - Professional UI with smooth animations

4. **✅ Auto-Reconnection**
   - Network resilience
   - Automatic reconnect on connection loss
   - Visual connection status

### 🎉 NEW! Kategori Yönetimi (COMPLETED!)

1. **✅ Hierarchical Category Management**
   - Tree view ile görsel kategori ağacı
   - Ana kategori ve alt kategori desteği
   - Expand/collapse functionality
   - CRUD operasyonları (Create, Read, Update, Delete)
   - Smart delete protection (ürün/alt kategori kontrolü)
   - Parent category selection
   - Level-based visual indicators
   - Product count per category
   - Statistics panel

### 🎉 NEW! Merchant Profil Yönetimi (COMPLETED!)

2. **✅ Comprehensive Profile Management**
   - Profil düzenleme (temel bilgiler, iletişim, konum)
   - Çalışma saatleri yönetimi (7 gün, template support)
   - Logo ve kapak görseli yönetimi
   - Teslimat ayarları (min tutar, ücret, süre)
   - Durum kontrolleri (Aktif/Pasif, Yoğun)
   - GPS koordinat yönetimi
   - Bildirim tercihleri
   - Hızlı şablonlar (hafta içi, perakende, 7/24)
   - Quick action cards
   - Settings dashboard

### 🎉 NEW! Payment Tracking System (COMPLETED!)

3. **✅ Comprehensive Payment Management**
   - Payment dashboard (real-time statistics)
   - Payment history (filterable by date range)
   - Settlement reports (paginated list)
   - Revenue analytics (Chart.js with line & doughnut charts)
   - Commission breakdown
   - Payment method distribution
   - Performance metrics (daily/weekly/monthly)
   - Export to Excel (ready for implementation)

### 🚧 Gelecek Özellikler (Planlanmış)

4. **Gelişmiş Raporlama** 🟡 MEDIUM PRIORITY
   - Chart.js entegrasyonu
   - Satış raporları
   - Ürün performans analizi
   - Müşteri analitikleri

5. **Backend SignalR Events** ✅ COMPLETE
   - ✅ WebApi'de event triggering implemented
   - ✅ OrderService'de real-time event gönderimi
   - ✅ NewOrderReceived, OrderStatusChanged, OrderCancelled events
   - 📄 [Detaylı Dokümantasyon](BACKEND-SIGNALR-EVENTS-COMPLETE.md)

6. **UI/UX Modernization** ✅ COMPLETE 🆕
   - ✅ Modern gradient stat cards
   - ✅ Smooth animations & transitions
   - ✅ Products: Grid layout with hover effects
   - ✅ Orders: Enhanced cards with colored borders
   - ✅ Payments: Modern chart containers
   - ✅ Responsive mobile design
   - 📄 [Detaylı Dokümantasyon](UI-UX-IMPROVEMENTS.md)

## 🏗️ Teknik Mimari

### Teknolojiler
- **Framework:** ASP.NET Core 8.0 MVC
- **Authentication:** Cookie Authentication + JWT Token
- **HTTP Client:** HttpClient with DI
- **UI Framework:** Bootstrap 5
- **Icons:** Font Awesome 6.4
- **Serialization:** Newtonsoft.Json
- **SignalR Client:** (kurulu, entegrasyon beklemede)

### Proje Yapısı
```
MerchantPortal/
├── Controllers/          # MVC Controllers
│   ├── AuthController.cs
│   ├── DashboardController.cs
│   ├── ProductsController.cs
│   └── OrdersController.cs
├── Services/            # API Client Services
│   ├── ApiClient.cs
│   ├── AuthService.cs
│   ├── MerchantService.cs
│   ├── ProductService.cs
│   └── OrderService.cs
├── Models/             # DTOs & ViewModels
│   └── ApiModels.cs
├── Views/              # Razor Views
│   ├── Auth/
│   ├── Dashboard/
│   ├── Products/
│   ├── Orders/
│   └── Shared/
└── wwwroot/           # Static Files
```

### API Entegrasyonu
Tüm işlemler aşağıdaki API endpoint'leri ile yapılır:
- `POST /api/v1/auth/login` - Giriş
- `GET /api/v1/merchants/{id}/merchantdashboard` - Dashboard metrikleri
- `GET /api/v1/merchants/merchantproduct` - Ürün listesi
- `POST /api/v1/merchants/merchantproduct` - Yeni ürün
- `PUT /api/v1/merchants/merchantproduct/{id}` - Ürün güncelleme
- `DELETE /api/v1/merchants/merchantproduct/{id}` - Ürün silme
- `GET /api/v1/merchants/merchantorder` - Sipariş listesi
- `GET /api/v1/merchants/merchantorder/{id}` - Sipariş detayı
- `PUT /api/v1/merchants/merchantorder/{id}/status` - Durum güncelleme

## 🚀 Kurulum & Çalıştırma

### Gereksinimler
- .NET 8.0 SDK
- Çalışan Getir API (varsayılan: https://localhost:7001)

### Konfigürasyon
`appsettings.json` dosyasını düzenleyin:
```json
{
  "ApiSettings": {
    "BaseUrl": "https://localhost:7001",  // API URL
    "SignalRHubUrl": "https://localhost:7001/hubs"
  },
  "Authentication": {
    "CookieName": "GetirMerchantAuth",
    "ExpireTimeSpan": "12:00:00"
  }
}
```

### Çalıştırma
```bash
cd src/MerchantPortal
dotnet run
```

Tarayıcıda: `https://localhost:5001` (port değişebilir)

## 🔐 Güvenlik

- **Cookie-based authentication** (HttpOnly, Secure)
- **JWT token** session'da saklanır
- **AntiForgeryToken** tüm POST/PUT/DELETE işlemlerinde
- **Authorization** attribute'ları controller seviyesinde
- **12 saat sliding session**

## 🎨 Tasarım Prensipleri

1. **SOLID principles** uygulandı
2. **Dependency Injection** tam kullanım
3. **Interface-based** servis mimarisi
4. **Separation of Concerns** (Controller-Service-Model)
5. **Clean Code** ve okunabilir yapı

## 📝 Notlar

### Bilinen Sınırlamalar
1. `GetMyMerchantAsync` implementasyonu API'ye göre tamamlanmalı
2. SignalR entegrasyonu henüz aktif değil
3. Kategori yönetimi UI'ı eksik
4. Ödeme takibi henüz yok

### Öneriler
1. API'yi önce çalıştırın
2. Merchant hesabı ile giriş yapın (Admin veya MerchantOwner rolü)
3. Dashboard'dan başlayın
4. Önce ürün ekleyin, sonra sipariş testleri yapın

## 🤝 Katkı

Bu proje Getir'in merchant yönetim ihtiyaçları için geliştirilmiştir.

## 📄 Lisans

Bu proje özel bir projedir ve Getir'e aittir.

---

**Geliştirici Notları:**
- Modern MVC best practices uygulandı
- Bootstrap 5 ile responsive tasarım
- Font Awesome ikonları kullanıldı
- Türkçe dil desteği
- Performans optimize edildi (lazy loading, pagination)
- Error handling eksiksiz yapıldı
- Logging her seviyede mevcut


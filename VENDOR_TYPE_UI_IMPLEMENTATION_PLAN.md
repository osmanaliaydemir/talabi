# 🎨 VendorType UI Implementation Plan
## Dinamik Renk Sistemi ve VendorType Filtreleme

### 📋 Genel Bakış
- **Hedef:** UI yapısı aynı kalacak, sadece renkler ve API verileri VendorType'a göre değişecek
- **Restaurant:** Mevcut kırmızı renk paleti (primaryOrange)
- **Market:** Yeşil renk paleti
- **Nav Menu:** Kategori seçimi (Restaurant/Market) ile renk ve veri değişimi

---

## 📦 Faz 1: Dinamik Theme System (Kritik)

### 1.1. Theme Provider Oluşturma
**Dosya:** `mobile/lib/providers/theme_provider.dart`
- `VendorTypeThemeProvider` oluştur
- `MainCategory` (Restaurant/Market) state yönetimi
- `getCurrentTheme()` metodu - VendorType'a göre ThemeData döndürür
- `getCurrentColors()` metodu - VendorType'a göre ColorScheme döndürür

**Renk Paletleri:**
```dart
// Restaurant (Mevcut - Kırmızı)
- Primary: Color(0xFFCE181B)
- Dark: Color(0xFFB71518)
- Light: Color(0xFFEF5350)

// Market (Yeni - Yeşil)
- Primary: Color(0xFF4CAF50) // success color
- Dark: Color(0xFF388E3C) // successDark
- Light: Color(0xFF81C784) // successLight
```

### 1.2. AppTheme Güncelleme
**Dosya:** `mobile/lib/config/app_theme.dart`
- `getThemeForVendorType(MainCategory category)` static metodu ekle
- `getColorsForVendorType(MainCategory category)` static metodu ekle
- Market için yeşil renk paleti tanımla
- Restaurant için mevcut kırmızı renk paleti koru

### 1.3. MaterialApp Theme Entegrasyonu
**Dosya:** `mobile/lib/main.dart`
- `ThemeProvider` ekle
- `Consumer<ThemeProvider>` ile `MaterialApp` theme'ini dinamik yap
- `BottomNavProvider` ile senkronize et

**Bağımlılıklar:**
- `BottomNavProvider.selectedCategory` değiştiğinde theme güncellenecek

---

## 📦 Faz 2: State Management Güncellemeleri

### 2.1. BottomNavProvider Güncelleme
**Dosya:** `mobile/lib/providers/bottom_nav_provider.dart`
- ✅ Zaten `MainCategory` enum var
- ✅ Zaten `selectedCategory` var
- `notifyListeners()` çağrıldığında theme de güncellenecek (ThemeProvider ile senkronize)

### 2.2. ThemeProvider Oluşturma
**Dosya:** `mobile/lib/providers/theme_provider.dart` (YENİ)
```dart
class ThemeProvider extends ChangeNotifier {
  MainCategory _currentCategory = MainCategory.restaurant;
  
  MainCategory get currentCategory => _currentCategory;
  ThemeData get currentTheme => AppTheme.getThemeForVendorType(_currentCategory);
  ColorScheme get currentColors => AppTheme.getColorsForVendorType(_currentCategory);
  
  void setCategory(MainCategory category) {
    _currentCategory = category;
    notifyListeners();
  }
}
```

### 2.3. Provider Entegrasyonu
**Dosya:** `mobile/lib/main.dart`
- `ThemeProvider` ekle
- `BottomNavProvider` ile senkronize et (listener ekle)

---

## 📦 Faz 3: API Service Güncellemeleri

### 3.1. VendorType Parametresi Ekleme
**Dosya:** `mobile/lib/services/api_service.dart`

**Güncellenecek Metodlar:**
1. ✅ `getVendors()` - Zaten `vendorType` parametresi var mı kontrol et
2. `getCategories()` - `vendorType` parametresi ekle
3. `getPopularProducts()` - `vendorType` parametresi ekle
4. `getBanners()` - `vendorType` parametresi ekle (backend'de filtreleme gerekebilir)
5. `searchProducts()` - `vendorType` parametresi ekle
6. `searchVendors()` - `vendorType` parametresi ekle

**Örnek:**
```dart
Future<List<Category>> getCategories({
  String? language,
  int? vendorType, // 1 = Restaurant, 2 = Market
}) async {
  final queryParams = <String, dynamic>{};
  if (language != null) queryParams['language'] = language;
  if (vendorType != null) queryParams['vendorType'] = vendorType;
  
  // API call...
}
```

### 3.2. Backend API Kontrolü
**Kontrol Edilecek Endpoint'ler:**
- ✅ `/api/vendors` - VendorType filtreleme var mı?
- ✅ `/api/categories` - VendorType filtreleme var mı?
- ✅ `/api/products` - VendorType filtreleme var mı?
- `/api/banners` - VendorType filtreleme var mı? (Yoksa ekle)
- ✅ `/api/products/search` - VendorType filtreleme var mı?
- ✅ `/api/vendors/search` - VendorType filtreleme var mı?

---

## 📦 Faz 4: HomeScreen Güncellemeleri

### 4.1. VendorType State Entegrasyonu
**Dosya:** `mobile/lib/screens/customer/home_screen.dart`
- `BottomNavProvider` dinle
- `selectedCategory` değiştiğinde verileri yeniden yükle
- `_loadData()` metodu oluştur - VendorType'a göre veri çek

**Güncellenecek Future'lar:**
```dart
late Future<List<Vendor>> _vendorsFuture;
late Future<List<Product>> _popularProductsFuture;
late Future<List<Map<String, dynamic>>> _categoriesFuture;
List<PromotionalBanner> _banners = [];
```

**Yeni Metod:**
```dart
void _loadData() {
  final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
  final vendorType = bottomNav.selectedCategory == MainCategory.restaurant ? 1 : 2;
  
  setState(() {
    _vendorsFuture = _apiService.getVendors(vendorType: vendorType);
    _popularProductsFuture = _apiService.getPopularProducts(
      limit: 8,
      vendorType: vendorType,
    );
    _categoriesFuture = _apiService.getCategories(
      language: locale,
      vendorType: vendorType,
    );
  });
  _loadBanners(vendorType: vendorType);
}
```

### 4.2. Renk Güncellemeleri
**Dosya:** `mobile/lib/screens/customer/home_screen.dart`
- `AppTheme.primaryOrange` yerine `Theme.of(context).colorScheme.primary` kullan
- Tüm hardcoded renkleri theme'den al
- `RefreshIndicator` rengini dinamik yap

**Örnek:**
```dart
// Eski
color: AppTheme.primaryOrange,

// Yeni
color: Theme.of(context).colorScheme.primary,
```

---

## 📦 Faz 5: Categories Screen Güncellemeleri

### 5.1. VendorType Filtreleme
**Dosya:** `mobile/lib/screens/customer/category/categories_screen.dart`
- `BottomNavProvider` dinle
- `getCategories()` çağrısına `vendorType` parametresi ekle
- `selectedCategory` değiştiğinde verileri yeniden yükle

### 5.2. Renk Güncellemeleri
- Hardcoded renkleri theme'den al
- `AppTheme.primaryOrange` → `Theme.of(context).colorScheme.primary`

---

## 📦 Faz 6: Products Screen Güncellemeleri

### 6.1. CategoryProductsScreen
**Dosya:** `mobile/lib/screens/customer/category/category_products_screen.dart`
- `BottomNavProvider` dinle
- `searchProducts()` çağrısına `vendorType` parametresi ekle
- Category'nin `VendorType`'ını kontrol et (backend'den gelen category zaten filtrelenmiş olmalı)

### 6.2. PopularProductListScreen
**Dosya:** `mobile/lib/screens/customer/product/popular_product_list_screen.dart`
- `BottomNavProvider` dinle
- `getPopularProducts()` çağrısına `vendorType` parametresi ekle

### 6.3. Renk Güncellemeleri
- Tüm ekranlarda hardcoded renkleri theme'den al

---

## 📦 Faz 7: Campaigns Screen Güncellemeleri

### 7.1. VendorType Filtreleme
**Dosya:** `mobile/lib/screens/customer/campaigns/campaigns_screen.dart`
- `BottomNavProvider` dinle
- `getBanners()` çağrısına `vendorType` parametresi ekle (backend'de filtreleme gerekebilir)
- Backend'de banner'lar için VendorType desteği var mı kontrol et

### 7.2. Renk Güncellemeleri
- Hardcoded renkleri theme'den al

---

## 📦 Faz 8: Vendors Screen Güncellemeleri

### 8.1. VendorListScreen
**Dosya:** `mobile/lib/screens/customer/vendor/vendor_list_screen.dart`
- ✅ Zaten `getVendors(vendorType: vendorType)` kullanıyor olabilir
- `BottomNavProvider` dinle
- `selectedCategory` değiştiğinde verileri yeniden yükle

### 8.2. VendorDetailScreen
**Dosya:** `mobile/lib/screens/customer/vendor/vendor_detail_screen.dart`
- Vendor'ın `Type`'ını kontrol et
- Eğer farklı VendorType ise uyarı göster veya filtrele

### 8.3. Renk Güncellemeleri
- Hardcoded renkleri theme'den al

---

## 📦 Faz 9: Search Screen Güncellemeleri

### 9.1. VendorType Filtreleme
**Dosya:** `mobile/lib/screens/customer/search_screen.dart`
- `BottomNavProvider` dinle
- `searchProducts()` ve `searchVendors()` çağrılarına `vendorType` parametresi ekle
- Arama sonuçları seçili VendorType'a göre filtrelenecek

### 9.2. Renk Güncellemeleri
- Hardcoded renkleri theme'den al

---

## 📦 Faz 10: Diğer Ekranlar

### 10.1. ProductDetailScreen
**Dosya:** `mobile/lib/screens/customer/product/product_detail_screen.dart`
- Product'ın vendor'ının `Type`'ını kontrol et
- Similar products'ı aynı VendorType'tan getir (zaten category bazlı)

### 10.2. CartScreen
**Dosya:** `mobile/lib/screens/customer/cart_screen.dart`
- Renk güncellemeleri

### 10.3. Order Screens
**Dosyalar:** Tüm order ekranları
- Renk güncellemeleri

### 10.4. Profile Screens
**Dosyalar:** Tüm profile ekranları
- Renk güncellemeleri

---

## 📦 Faz 11: Widget Güncellemeleri

### 11.1. Common Widgets
**Dosyalar:**
- `mobile/lib/widgets/common/*.dart`
- `mobile/lib/screens/customer/widgets/*.dart`

**Güncellemeler:**
- `AppTheme.primaryOrange` → `Theme.of(context).colorScheme.primary`
- `AppTheme.darkOrange` → `Theme.of(context).colorScheme.primary.withOpacity(0.8)`
- `AppTheme.lightOrange` → `Theme.of(context).colorScheme.primary.withOpacity(0.6)`

### 11.2. ProductCard
**Dosya:** `mobile/lib/screens/customer/widgets/product_card.dart`
- Renk güncellemeleri

### 11.3. CategoryCard
**Dosya:** `mobile/lib/screens/customer/widgets/category_card.dart` (varsa)
- Renk güncellemeleri

---

## 📦 Faz 12: Backend Kontrolleri

### 12.1. Banners Endpoint
**Dosya:** `src/Talabi.Api/Controllers/PromotionalBannersController.cs`
- VendorType filtreleme ekle (eğer yoksa)
- Banner'ların VendorType'ı var mı kontrol et

### 12.2. Diğer Endpoint'ler
- Tüm endpoint'lerde VendorType filtreleme çalışıyor mu kontrol et
- Test et

---

## 📦 Faz 13: Testing & Validation

### 13.1. Functional Testing
- [ ] Restaurant seçildiğinde kırmızı renkler görünüyor mu?
- [ ] Market seçildiğinde yeşil renkler görünüyor mu?
- [ ] Restaurant seçildiğinde sadece restaurant verileri geliyor mu?
- [ ] Market seçildiğinde sadece market verileri geliyor mu?
- [ ] Kategori değiştiğinde veriler yeniden yükleniyor mu?
- [ ] Theme değişimi smooth mu?

### 13.2. UI Testing
- [ ] Tüm ekranlarda renkler doğru mu?
- [ ] Dark mode'da renkler doğru mu?
- [ ] Animasyonlar smooth mu?
- [ ] Loading states doğru renklerle mi?

### 13.3. Performance Testing
- [ ] Kategori değiştiğinde performans sorunu var mı?
- [ ] Memory leak var mı?
- [ ] API çağrıları optimize mi?

---

## 📋 İş Listesi (Todo)

### ✅ Tamamlanan

#### Backend (Önceki Çalışmalar)
- [x] VendorType enum backend'de oluşturuldu
- [x] Vendor ve Category entity'lerine Type alanları eklendi
- [x] Migration uygulandı
- [x] BottomNavProvider'da MainCategory enum ve selectedCategory var
- [x] Vendor registration'da VendorType seçimi var

#### Faz 1: Dinamik Theme System ✅
- [x] **Faz 1.1:** ThemeProvider güncellendi - BottomNavProvider ile senkronizasyon
  - `setCategory()` metodu eklendi
  - `currentCategory` property eklendi
  - `lightTheme` ve `darkTheme` getter'ları VendorType'a göre dinamik hale getirildi
- [x] **Faz 1.2:** AppTheme'e getThemeForVendorType() ve getColorsForVendorType() metodları eklendi
  - Restaurant (kırmızı) ve Market (yeşil) renk paletleri tanımlandı
  - `getPrimaryColorForVendorType()`, `getDarkColorForVendorType()`, `getLightColorForVendorType()` metodları eklendi
- [x] **Faz 1.3:** MaterialApp'e dinamik theme entegrasyonu yapıldı
  - `Consumer3<LocalizationProvider, ThemeProvider, BottomNavProvider>` eklendi
  - `BottomNavProvider` lazy yüklenmeyecek şekilde güncellendi

#### Faz 3: API Service Güncellemeleri ✅
- [x] **Faz 3.1:** API Service'e vendorType parametreleri eklendi
  - [x] `getVendors({int? vendorType})` ✅
  - [x] `getCategories({String? language, int? vendorType})` ✅
  - [x] `getPopularProducts({int limit, int? vendorType})` ✅
  - [x] `getBanners({String? language, int? vendorType})` ✅
- [x] **Faz 3.1:** DTO'lara vendorType eklendi
  - [x] `ProductSearchRequestDto.vendorType` ✅
  - [x] `VendorSearchRequestDto.vendorType` ✅

#### Faz 4: HomeScreen Güncellemeleri (Kısmen Tamamlandı)
- [x] **Faz 4.1:** HomeScreen'e VendorType state entegrasyonu ✅
  - [x] `_loadData()` metodu eklendi - VendorType'a göre veri yükleme ✅
  - [x] `_loadBanners()` metoduna vendorType parametresi eklendi ✅
  - [x] `Consumer<BottomNavProvider>` eklendi - kategori değişikliğini dinliyor ✅
  - [x] `initState()` içinde `_loadData()` çağrılıyor ✅
  - [x] `RefreshIndicator`'da `_loadData()` çağrılıyor ✅
- [ ] **Faz 4.2:** HomeScreen renk güncellemeleri (Kısmen - 22 yerde AppTheme.primaryOrange kullanılıyor)
  - [x] RefreshIndicator'da `colorScheme.primary` kullanılıyor ✅
  - [ ] Diğer yerlerde `AppTheme.primaryOrange` → `colorScheme.primary` değiştirilmeli (22 yer)

### 🔄 Yapılacaklar (Öncelik Sırasına Göre)

#### Kritik (Faz 1-2)
- [x] **Faz 1.1:** ThemeProvider oluştur ✅
- [x] **Faz 1.2:** AppTheme'e getThemeForVendorType() ekle ✅
- [x] **Faz 1.3:** MaterialApp'e ThemeProvider entegre et ✅
- [ ] **Faz 2.1:** BottomNavProvider ile ThemeProvider senkronizasyonu test et

#### Yüksek Öncelik (Faz 3-4)
- [x] **Faz 3.1:** API Service'e vendorType parametreleri ekle ✅
- [ ] **Faz 3.2:** Backend API'lerini kontrol et (banners dahil)
- [x] **Faz 4.1:** HomeScreen'e VendorType state entegrasyonu ✅
- [ ] **Faz 4.2:** HomeScreen renk güncellemeleri (AppTheme.primaryOrange → colorScheme.primary)

#### Orta Öncelik (Faz 5-8)
- [ ] **Faz 5:** Categories Screen güncellemeleri
- [ ] **Faz 6:** Products Screen güncellemeleri
- [ ] **Faz 7:** Campaigns Screen güncellemeleri
- [ ] **Faz 8:** Vendors Screen güncellemeleri

#### Düşük Öncelik (Faz 9-11)
- [ ] **Faz 9:** Search Screen güncellemeleri
- [ ] **Faz 10:** Diğer ekranlar (ProductDetail, Cart, Order, Profile)
- [ ] **Faz 11:** Widget güncellemeleri

#### Son Kontroller (Faz 12-13)
- [ ] **Faz 12:** Backend kontrolleri (banners endpoint)
- [ ] **Faz 13:** Testing & Validation

---

## 🎨 Renk Paleti Detayları

### Restaurant (Mevcut - Kırmızı)
```dart
primary: Color(0xFFCE181B)      // primaryOrange
dark: Color(0xFFB71518)           // darkOrange
light: Color(0xFFEF5350)          // lightOrange
shade50: Color(0xFFFFEBEE)        // primaryOrangeShade50
```

### Market (Yeni - Yeşil)
```dart
primary: Color(0xFF4CAF50)        // success
dark: Color(0xFF388E3C)           // successDark
light: Color(0xFF81C784)          // successLight
shade50: Color(0xFFE8F5E9)        // Yeni ekle
```

---

## 📝 Notlar

1. **UI Yapısı:** Tüm UI yapısı aynı kalacak, sadece renkler değişecek
2. **API Filtreleme:** Tüm API çağrılarına `vendorType` parametresi eklenecek
3. **State Management:** `BottomNavProvider` ve `ThemeProvider` senkronize çalışacak
4. **Performance:** Kategori değiştiğinde gereksiz API çağrıları yapılmamalı
5. **Backward Compatibility:** Eğer `vendorType` gönderilmezse, backend default olarak Restaurant döndürmeli

---

## 🚀 Başlangıç Adımları

1. **Faz 1'i başlat:** ThemeProvider ve AppTheme güncellemeleri
2. **Test et:** Renk değişimi çalışıyor mu?
3. **Faz 3'e geç:** API Service güncellemeleri
4. **Faz 4'e geç:** HomeScreen güncellemeleri
5. **Sırayla devam et:** Diğer fazlar

---

**Toplam Tahmini Süre:** 2-3 gün
**Kritik Fazlar:** Faz 1-4 (1 gün)
**Orta/Düşük Öncelik:** Faz 5-11 (1-2 gün)
**Testing:** Faz 12-13 (Yarım gün)


# Kod Standartları İyileştirme Planı

## 📊 Mevcut Durum
- **Kod Standartlarına Uygunluk**: %85
- **Hedef**: %95+

## 🎯 Öncelikli Aksiyonlar

---

### 2. Deprecated API'lerin Güncellenmesi (Orta Öncelik) ✅ **Tamamlandı**

#### Sorun
- ~~`withOpacity()` deprecated → `withValues()` kullanılmalı~~ → ✅ **Çözüldü**
- ~~`MaterialStateProperty` → `WidgetStateProperty`~~ → ✅ **Kontrol edildi, kullanım yok**
- ~~`MaterialState` → `WidgetState`~~ → ✅ **Kontrol edildi, kullanım yok**

#### Çözüm Adımları

**2.1. withOpacity() → withValues()** ✅ **Tamamlandı**

```dart
// Önce
color.withOpacity(0.3)

// Sonra
color.withValues(alpha: 0.3)
```

**Düzeltilen dosyalar** (20 kullanım, 9 dosya):
- ✅ `lib/screens/shared/splash_screen.dart` (1)
- ✅ `lib/screens/vendor/settings_screen.dart` (1)
- ✅ `lib/screens/customer/widgets/product_card.dart` (4)
- ✅ `lib/screens/customer/campaigns/campaigns_screen.dart` (4)
- ✅ `lib/screens/customer/campaigns/campaign_detail_screen.dart` (2)
- ✅ `lib/screens/customer/category/categories_screen.dart` (4)
- ✅ `lib/widgets/cached_network_image_widget.dart` (1)
- ✅ `lib/screens/customer/widgets/category_selection_bottom_sheet.dart` (2)
- ✅ `lib/screens/shared/onboarding/onboarding_screen.dart` (1)

**2.2. MaterialStateProperty → WidgetStateProperty** ✅ **Kontrol edildi**

Kod tabanında `MaterialStateProperty` kullanımı bulunamadı. ✅

**2.3. MaterialState → WidgetState** ✅ **Kontrol edildi**

Kod tabanında `MaterialState` kullanımı bulunamadı. ✅

**İlerleme**: ✅ **%100 tamamlandı** (20 withOpacity → 0)
**Tamamlanma Tarihi**: Tüm deprecated API'ler güncellendi
**Etki**: +3% kod kalitesi

---

### 3. Gereksiz Importların Temizlenmesi (Düşük Öncelik)

#### Sorun
- Kullanılmayan importlar kod kalitesini düşürür
- Build süresini etkiler

#### Çözüm

**3.1. Otomatik temizlik**

```bash
# Dart analyzer ile kontrol
flutter analyze

# Gereksiz importları bul
dart fix --apply
```

**3.2. Manuel kontrol**

Her dosyada import'ları kontrol et:
- Kullanılmayan importları kaldır
- `always_use_package_imports` kuralına uy

**Tahmini Süre**: 0.5 gün
**Etki**: +1% kod kalitesi

---

### 4. TODO Yorumlarının Temizlenmesi (Orta Öncelik)

#### Sorun
- Kodda TODO yorumları var
- Bu yorumlar gelecekteki işleri işaret ediyor ama unutulabilir

#### Çözüm

**4.1. TODO'ları listeleyin**

```bash
grep -r "TODO\|FIXME\|XXX\|HACK" lib/
```

**4.2. Her TODO için karar verin**
- **Hemen düzeltilebilir**: Düzelt
- **Gelecekte yapılacak**: Issue aç veya dokümante et
- **Gereksiz**: Kaldır

**4.3. Öncelikli TODO'lar**
- `lib/screens/vendor/products_screen.dart`: "Todo: Remove this import OAA"
- `lib/screens/vendor/edit_profile_screen.dart`: "Todo: remove this import OAA"
- `lib/screens/vendor/register_screen.dart`: "Todo: Email verification screen OAA"

**Tahmini Süre**: 0.5 gün
**Etki**: +1% kod kalitesi

---

### 5. Test Coverage Artırma (Yüksek Öncelik)

#### Sorun
- Test coverage düşük veya yok
- Kod güvenilirliği için testler kritik

#### Çözüm Adımları

**5.1. Test yapısı oluştur**

```
test/
├── unit/
│   ├── models/
│   ├── providers/
│   └── services/
├── widget/
│   └── screens/
└── integration/
```

**5.2. Öncelikli testler**

**Unit Tests:**
- `lib/models/` - Tüm model sınıfları
- `lib/providers/auth_provider.dart`
- `lib/services/api_service.dart`
- `lib/services/cache_service.dart`

**Widget Tests:**
- `lib/screens/customer/auth/login_screen.dart`
- `lib/widgets/` - Tüm widget'lar

**5.3. Test coverage hedefi**

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.0
  coverage: ^1.6.3
```

**5.4. Coverage raporu**

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Hedef**: %70+ test coverage
**Tahmini Süre**: 1 hafta
**Etki**: +5% kod kalitesi

---

### 6. Code Documentation (Orta Öncelik)

#### Sorun
- Public API'ler için dokümantasyon eksik
- `public_member_api_docs` kuralı şu an kapalı

#### Çözüm

**6.1. Dokümantasyon standartları**

```dart
/// Service sınıfı için API isteklerini yönetir.
///
/// Singleton pattern kullanır ve tüm HTTP isteklerini
/// merkezi bir yerden yönetir.
///
/// Örnek kullanım:
/// ```dart
/// final apiService = ApiService();
/// final vendors = await apiService.getVendors();
/// ```
class ApiService {
  /// Base URL for API requests
  static const String baseUrl = 'https://talabi.runasp.net/api';
  
  /// Login işlemi yapar
  ///
  /// [email] ve [password] ile giriş yapar ve token döndürür.
  ///
  /// Throws [DioException] if request fails.
  Future<Map<String, String>> login(String email, String password) async {
    // ...
  }
}
```

**6.2. Öncelikli dosyalar**
- `lib/services/` - Tüm servisler
- `lib/providers/` - Tüm provider'lar
- `lib/models/` - Public model'ler

**Tahmini Süre**: 2-3 gün
**Etki**: +2% kod kalitesi

---

### 7. CI/CD Pipeline Kurulumu (Yüksek Öncelik)

#### Sorun
- Otomatik test ve analiz yok
- Kod kalitesi kontrolü manuel

#### Çözüm

**7.1. GitHub Actions Workflow**

`.github/workflows/flutter_ci.yml`:

```yaml
name: Flutter CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

**7.2. Pre-commit hooks**

`.git/hooks/pre-commit`:

```bash
#!/bin/sh
flutter analyze
flutter test
flutter format --set-exit-if-changed .
```

**Tahmini Süre**: 1 gün
**Etki**: +3% kod kalitesi (sürekli iyileştirme)

---

### 8. Performance Optimizasyonları (Orta Öncelik)

#### Sorun
- Potansiyel performans sorunları
- Büyük widget tree'ler

#### Çözüm

**8.1. Widget optimizasyonu**

```dart
// Önce
Widget build(BuildContext context) {
  return Column(
    children: [
      // 100+ widget
    ],
  );
}

// Sonra - const widget'lar kullan
Widget build(BuildContext context) {
  return const Column(
    children: [
      // const widget'lar
    ],
  );
}
```

**8.2. ListView.builder kullanımı**

```dart
// Önce
ListView(children: items.map(...).toList())

// Sonra
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

**8.3. Image caching**

`cached_network_image` zaten kullanılıyor ✅

**Tahmini Süre**: 2 gün
**Etki**: +2% kod kalitesi

---

## 📅 Uygulama Takvimi

### Hafta 1: Kritik Düzeltmeler
- [ ] Logger servisi oluşturma ve print değişiklikleri
- [x] Deprecated API'lerin güncellenmesi (withOpacity → withValues, 20 kullanım düzeltildi)
- [ ] Gereksiz importların temizlenmesi

### Hafta 2: Test ve Dokümantasyon
- [ ] Unit testler yazılması
- [ ] Widget testler yazılması
- [ ] Public API dokümantasyonu

### Hafta 3: CI/CD ve Optimizasyon
- [ ] CI/CD pipeline kurulumu
- [ ] Performance optimizasyonları
- [ ] Code review ve final kontroller

---

## 📊 Beklenen İyileştirmeler

| Aksiyon | Mevcut | Hedef | Artış |
|---------|--------|-------|-------|
| Print kullanımı | 573 satır | 0 satır | +5% |
| Deprecated API | 20+ | 0 ✅ | +3% |
| Test Coverage | ~0% | 70%+ | +5% |
| Dokümantasyon | %30 | %90 | +2% |
| CI/CD | Yok | Var | +3% |
| **TOPLAM** | **%85** | **%99** | **+14%** |

---

## ✅ Kontrol Listesi

### Kod Kalitesi
- [x] Logger servisi oluşturuldu
- [x] pubspec.yaml'a logger eklendi
- [x] Öncelikli dosyalardaki print() kullanımları değiştirildi (api_service, auth_provider, cart_provider, notification_service, dashboard_screen)
- [x] Tüm print() kullanımları değiştirildi (573 → 0 print)
- [x] Deprecated API'ler güncellendi (withOpacity → withValues, 20 kullanım)
- [ ] Gereksiz importlar temizlendi
- [ ] TODO yorumları temizlendi veya issue'ya dönüştürüldü

### Test
- [ ] Unit testler yazıldı (%70+ coverage)
- [ ] Widget testler yazıldı
- [ ] Integration testler yazıldı
- [ ] Test coverage raporu oluşturuldu

### Dokümantasyon
- [ ] Public API'ler dokümante edildi
- [ ] README güncellendi
- [ ] Kod içi yorumlar eklendi

### CI/CD
- [ ] GitHub Actions workflow kuruldu
- [ ] Pre-commit hooks eklendi
- [ ] Code coverage entegrasyonu yapıldı

### Performance
- [ ] Const widget'lar kullanıldı
- [ ] ListView.builder kullanıldı
- [ ] Image caching optimize edildi

---

## 🔧 Yardımcı Komutlar

### Kod Analizi
```bash
# Tüm analizleri çalıştır
flutter analyze

# Format kontrolü
flutter format --set-exit-if-changed .

# Linter hatalarını göster
flutter analyze --no-fatal-infos
```

### Test
```bash
# Tüm testleri çalıştır
flutter test

# Coverage ile test
flutter test --coverage

# Coverage raporu oluştur
genhtml coverage/lcov.info -o coverage/html
```

### Temizlik
```bash
# Build cache temizle
flutter clean

# Pub cache temizle
flutter pub cache repair

# Gereksiz dosyaları temizle
flutter pub get
```

---

## 📚 Referanslar

- [Flutter Style Guide](https://docs.flutter.dev/development/ui/widgets-intro)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Logger Package](https://pub.dev/packages/logger)
- [Material 3 Migration](https://docs.flutter.dev/release/breaking-changes/material-3)

---

## 🎯 Sonuç

Bu planı takip ederek kod standartlarına uygunluğu **%85'ten %99'a** çıkarabilirsiniz. Öncelikli olarak **Logger servisi** ve **Test coverage** üzerinde çalışmanız önerilir.

**Tahmini Toplam Süre**: 3 hafta
**Beklenen İyileştirme**: +14% kod kalitesi


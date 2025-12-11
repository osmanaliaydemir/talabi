# Talâbî Mobile Application

Flutter tabanlı mobil uygulama - Talâbî platformu için müşteri, satıcı ve kurye uygulamaları.

## 📱 Özellikler

- **Multi-role Support**: Müşteri, Satıcı ve Kurye rolleri için ayrı arayüzler
- **Localization**: Türkçe, İngilizce ve Arapça dil desteği
- **Offline Support**: Çevrimdışı çalışma ve senkronizasyon
- **Real-time Updates**: SignalR ile gerçek zamanlı bildirimler
- **Location Services**: Konum takibi ve harita entegrasyonu
- **Social Authentication**: Google, Apple ve Facebook ile giriş
- **Firebase Integration**: Analytics, Crashlytics ve Push Notifications

## 🏗️ Proje Yapısı

```
lib/
├── config/          # Tema ve konfigürasyon
├── l10n/            # Lokalizasyon dosyaları
├── models/          # Veri modelleri
├── providers/       # State management (Provider)
├── routers/         # Route yönetimi
├── screens/         # Ekranlar (customer, vendor, courier, shared)
├── services/        # API, cache, notification servisleri
├── utils/           # Yardımcı fonksiyonlar
└── widgets/         # Yeniden kullanılabilir widget'lar
```

## 🚀 Kurulum

1. Flutter SDK'yı yükleyin (3.9.2+)
2. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```
3. Lokalizasyon dosyalarını oluşturun:
   ```bash
   flutter gen-l10n
   ```
4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## 📦 Bağımlılıklar

Ana bağımlılıklar:
- `provider` - State management
- `dio` - HTTP client
- `hive` - Local database
- `google_maps_flutter` - Harita entegrasyonu
- `firebase_core`, `firebase_auth`, `firebase_messaging` - Firebase servisleri
- `signalr_core` - Real-time communication

## 🔧 Geliştirme

### Kod Standartları

- `flutter analyze` ile kod analizi yapın
- `flutter format .` ile kod formatını düzeltin
- Linter kurallarına uyun (`analysis_options.yaml`)

### Önemli Notlar

- Production'da `print` yerine `debugPrint` kullanın
- Deprecated API'leri kullanmaktan kaçının
- Tüm public API'ler için dokümantasyon ekleyin

## 📄 Lisans

Bu proje özel bir projedir.

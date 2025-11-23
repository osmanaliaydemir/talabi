# Talabi

Talabi, Flutter ile geliştirilmiş mobil uygulama ve .NET 9.0 ile geliştirilmiş backend API'sinden oluşan bir e-ticaret platformudur.

## 📱 Proje Yapısı

```
talabi/
├── mobile/          # Flutter mobil uygulaması
├── src/             # .NET backend API
│   ├── Talabi.Api/           # API katmanı
│   ├── Talabi.Core/          # Core katmanı (Entities, DTOs, Services)
│   └── Talabi.Infrastructure/ # Infrastructure katmanı (Data, Migrations)
└── Talabi.sln       # Visual Studio solution dosyası
```

## 🚀 Teknolojiler

### Mobile (Flutter)
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **HTTP Client**: Dio
- **Local Storage**: Shared Preferences
- **Maps**: Google Maps Flutter
- **Location**: Geolocator, Geocoding
- **Localization**: Flutter Localizations (Türkçe, İngilizce, Arapça)

### Backend (.NET)
- **Framework**: .NET 9.0
- **ORM**: Entity Framework Core
- **Authentication**: JWT Bearer
- **API**: ASP.NET Core Web API

## 📋 Gereksinimler

### Mobile Geliştirme
- Flutter SDK 3.9.2 veya üzeri
- Dart SDK
- Android Studio / Xcode (platform-specific geliştirme için)
- Android SDK / iOS SDK

### Backend Geliştirme
- .NET 9.0 SDK
- SQL Server (veya Entity Framework Core destekleyen veritabanı)
- Visual Studio 2022 veya VS Code (önerilen)

## 🔧 Kurulum

### Mobile Uygulaması

1. Proje dizinine gidin:
```bash
cd mobile
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

### Backend API

1. `src/Talabi.Api/appsettings.json` dosyasını oluşturun ve veritabanı bağlantı bilgilerinizi ekleyin:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  },
  "JwtSettings": {
    "Secret": "your-jwt-secret-key",
    "Issuer": "TalabiApi",
    "Audience": "TalabiApp",
    "ExpirationInMinutes": 1440
  },
  "GoogleMaps": {
    "ApiKey": "your-google-maps-api-key"
  }
}
```

2. Migration'ları uygulayın:
```bash
cd src/Talabi.Api
dotnet ef database update
```

3. API'yi çalıştırın:
```bash
dotnet run
```

## 📝 Notlar

- `appsettings.json` dosyası hassas bilgiler içerdiği için `.gitignore`'a eklenmiştir. Lütfen kendi `appsettings.json` dosyanızı oluşturun.
- Google Maps API key'i için kendi API anahtarınızı kullanmanız gerekmektedir.
- JWT secret key'i güvenli bir şekilde oluşturulmalı ve saklanmalıdır.

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Branch'inizi push edin (`git push origin feature/AmazingFeature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje özel bir projedir.


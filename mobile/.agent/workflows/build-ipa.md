---
description: Talabi Projesi için iOS IPA Dosyası Hazırlama Rehberi
---

# iOS IPA Hazırlama Adımları

Bu rehber, uygulamanın yeni bir versiyonunu App Store veya TestFlight'a yüklemek için nasıl IPA dosyası hazırlayacağınızı açıklar.

## 1. Versiyon Hazırlığı

`pubspec.yaml` dosyasındaki `version` numarasını artırdığınızdan emin olun.
Örn: `1.0.0+11` (Burada `11` build numarasıdır ve her yüklemede artmalıdır).

## 2. Temizlik (Önerilen)

Eski build dosyalarından kurtulmak için terminalde şu komutu çalıştırın:

```bash
flutter clean
flutter pub get
```

## 3. IPA Build Komutu

Terminalde şu komutu çalıştırarak süreci başlatın:

```bash
flutter build ipa --release
```

## 4. Sonuçları Kontrol Etme

İşlem tamamlandığında IPA dosyasını ve Xcode arşivini şu dizinde bulabilirsiniz:

- **Xcode Arşivi:** `build/ios/archive/Runner.xcarchive`
- **IPA Dosyası:** `build/ios/ipa/*.ipa`

## 5. App Store'a Yükleme

Oluşturulan `.ipa` dosyasını **Apple Transporter** uygulaması ile veya Xcode'un içindeki **Organizer** aracılığıyla App Store Connect'e yükleyebilirsiniz.

// turbo

### Otomatik Build Başlat

Eğer şimdi yeni versiyonla build başlatmak isterseniz:

```bash
flutter build ipa --release
```

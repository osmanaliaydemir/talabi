# iOS Yapılacaklar Listesi

Bu dosya, iOS uygulamasının düzgün çalışması için gerekli tüm yapılandırmaları içerir.

## 🔴 Kritik Sorunlar (Uygulama Çalışmaz)

### 1. GoogleService-Info.plist Dosyası Eksik
**Dosya:** `ios/Runner/GoogleService-Info.plist`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🔴 Kritik  
**Açıklama:** Firebase başlatılamaz, uygulama crash olur veya Firebase servisleri çalışmaz.

**Yapılacaklar:**
1. Firebase Console'a gidin (https://console.firebase.google.com)
2. Projenizi seçin
3. iOS uygulaması ekleyin (eğer yoksa)
   - Bundle ID: `com.talabi.mobile`
4. `GoogleService-Info.plist` dosyasını indirin
5. Dosyayı `mobile/ios/Runner/` klasörüne kopyalayın
6. Xcode'da projeyi açın ve dosyanın "Runner" target'ına eklendiğinden emin olun

**Kontrol:**
```bash
ls -la mobile/ios/Runner/GoogleService-Info.plist
```

---

### 2. Kamera İzni Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🔴 Kritik  
**Açıklama:** `image_picker` paketi kamera kullanımı için izin gerektirir. İzin olmadan kamera açılmaz.

**Yapılacaklar:**
`Info.plist` dosyasına şu anahtarı ekleyin:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos for delivery proof and profile pictures</string>
```

**Kullanıldığı Yerler:**
- `lib/screens/courier/delivery_proof_screen.dart` - Teslimat kanıtı fotoğrafı
- `lib/screens/vendor/edit_profile_screen.dart` - Profil fotoğrafı
- `lib/screens/customer/profile/profile_screen.dart` - Profil fotoğrafı

---

### 3. Fotoğraf Kütüphanesi İzni Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🔴 Kritik  
**Açıklama:** `image_picker` paketi fotoğraf kütüphanesi erişimi için izin gerektirir.

**Yapılacaklar:**
`Info.plist` dosyasına şu anahtarı ekleyin:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images for delivery proof and profile pictures</string>
```

---

## 🟠 Önemli Sorunlar (Özellikler Çalışmaz)

### 4. Push Notifications İzni Açıklaması Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** iOS 10+ için bildirim izni açıklaması gereklidir. Olmadan push notifications çalışmaz.

**Yapılacaklar:**
`Info.plist` dosyasına şu anahtarı ekleyin:
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We need to send you notifications about your orders and deliveries</string>
```

---

### 5. Facebook URL Scheme Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı (Placeholder: fbYOUR_APP_ID - Facebook App ID ile değiştirin)  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Facebook Login için URL scheme yapılandırması gereklidir.

**Yapılacaklar:**
1. Facebook Developer Console'dan App ID'nizi alın
2. `Info.plist` dosyasına şu yapılandırmayı ekleyin:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_APP_ID</string>
        </array>
    </dict>
</array>
```
`YOUR_APP_ID` yerine Facebook App ID'nizi yazın.

**Not:** Facebook App ID'yi `pubspec.yaml` veya environment variable'dan da alabilirsiniz.

---

### 6. LSApplicationQueriesSchemes Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** iOS 9+ için Facebook ve Google Sign In'in çalışması için gerekli.

**Yapılacaklar:**
`Info.plist` dosyasına şu anahtarı ekleyin:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
    <string>googlechrome</string>
    <string>googlechromes</string>
</array>
```

---

### 7. Background Modes Eksik
**Dosya:** `ios/Runner/Info.plist`  
**Durum:** ✅ Tamamlandı (Info.plist'te eklendi, Xcode Capabilities'de de etkinleştirilmeli)  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Arka planda konum takibi ve push notifications için gerekli.

**Yapılacaklar:**
`Info.plist` dosyasına şu anahtarı ekleyin:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>remote-notification</string>
</array>
```

**Ayrıca Xcode'da:**
1. Runner projesini seçin
2. "Signing & Capabilities" sekmesine gidin
3. "+ Capability" butonuna tıklayın
4. "Background Modes" ekleyin
5. "Location updates" ve "Remote notifications" seçeneklerini işaretleyin

---

### 8. Firebase Messaging Delegate Eksik
**Dosya:** `ios/Runner/AppDelegate.swift`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Push notifications'ın çalışması için Firebase Messaging delegate metodları gereklidir.

**Yapılacaklar:**
`AppDelegate.swift` dosyasını şu şekilde güncelleyin:

```swift
import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase'i başlat (GoogleService-Info.plist varsa)
    FirebaseApp.configure()
    
    // Push notifications için
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    // Firebase Messaging delegate
    Messaging.messaging().delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // APNS token'ı Firebase'e gönder
  override func application(_ application: UIApplication,
                           didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // Push notification hatası
  override func application(_ application: UIApplication,
                           didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
}

// Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
```

---

### 9. Google Sign In URL Handling Eksik
**Dosya:** `ios/Runner/AppDelegate.swift`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Google Sign In'in çalışması için URL handling gereklidir.

**Yapılacaklar:**
`AppDelegate.swift` dosyasına şu metodu ekleyin:

```swift
override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
  // Google Sign In için
  if GIDSignIn.sharedInstance.handle(url) {
    return true
  }
  
  // Facebook Login için
  if ApplicationDelegate.shared.application(app, open: url, options: options) {
    return true
  }
  
  return super.application(app, open: url, options: options)
}
```

**Not:** `GIDSignIn` ve `ApplicationDelegate` import'larını eklemeyi unutmayın.

---

### 10. Facebook URL Handling Eksik
**Dosya:** `ios/Runner/AppDelegate.swift`  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Facebook Login'in çalışması için URL handling gereklidir.

**Yapılacaklar:**
Yukarıdaki Google Sign In URL handling ile birlikte eklenmiştir. Ayrıca `AppDelegate.swift` dosyasının başına şu import'u ekleyin:

```swift
import FBSDKCoreKit
```

---

### 11. Xcode Capabilities - Background Modes
**Dosya:** Xcode Project Settings  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Xcode'da Background Modes capability'sini etkinleştirmek gereklidir.

**Yapılacaklar:**
1. Xcode'da `ios/Runner.xcworkspace` dosyasını açın
2. Sol panelde "Runner" projesini seçin
3. "Signing & Capabilities" sekmesine gidin
4. "+ Capability" butonuna tıklayın
5. "Background Modes" seçin
6. "Location updates" ve "Remote notifications" seçeneklerini işaretleyin

**📖 Detaylı Rehber:** `XCODE_CAPABILITIES_REHBERI.md` dosyasına bakın

---

### 12. Xcode Capabilities - Push Notifications
**Dosya:** Xcode Project Settings  
**Durum:** ✅ Tamamlandı  
**Öncelik:** 🟠 Önemli  
**Açıklama:** Push notifications'ın çalışması için Xcode'da capability etkinleştirmek gereklidir.

**Yapılacaklar:**
1. Xcode'da `ios/Runner.xcworkspace` dosyasını açın
2. Sol panelde "Runner" projesini seçin
3. "Signing & Capabilities" sekmesine gidin
4. "+ Capability" butonuna tıklayın
5. "Push Notifications" seçin

**📖 Detaylı Rehber:** `XCODE_CAPABILITIES_REHBERI.md` dosyasına bakın

---

## ✅ Tamamlanan İşler

- ✅ Konum izinleri eklendi (NSLocationWhenInUseUsageDescription, NSLocationAlwaysAndWhenInUseUsageDescription)
- ✅ Bundle ID doğru yapılandırıldı (com.talabi.mobile)
- ✅ Podfile yapılandırması tamamlandı
- ✅ Deployment target ayarlandı (iOS 14.0)
- ✅ Firebase non-modular header sorunları çözüldü
- ✅ Kamera izni eklendi (NSCameraUsageDescription)
- ✅ Fotoğraf kütüphanesi izni eklendi (NSPhotoLibraryUsageDescription)
- ✅ Push notifications izni açıklaması eklendi (NSUserNotificationsUsageDescription)
- ✅ Facebook URL scheme eklendi (CFBundleURLTypes - App ID ile güncellenmeli)
- ✅ LSApplicationQueriesSchemes eklendi
- ✅ Background Modes eklendi (UIBackgroundModes - Xcode Capabilities'de de etkinleştirildi)
- ✅ Xcode Capabilities - Background Modes eklendi (Location updates, Remote notifications)
- ✅ Xcode Capabilities - Push Notifications eklendi
- ✅ Firebase Messaging delegate eklendi (AppDelegate.swift)
- ✅ Google Sign In URL handling eklendi (AppDelegate.swift)
- ✅ Facebook URL handling eklendi (AppDelegate.swift)
- ✅ GoogleService-Info.plist eklendi

---

## 📋 Öncelik Sırası

1. **GoogleService-Info.plist** - En kritik, Firebase olmadan uygulama çalışmaz
2. **Kamera ve Fotoğraf İzinleri** - image_picker için kritik
3. **Push Notifications İzni** - Bildirimler için önemli
4. **AppDelegate.swift Güncellemeleri** - Firebase Messaging ve Social Login için
5. **Info.plist URL Schemes** - Social Login için
6. **Xcode Capabilities** - Background modes ve Push notifications için

---

## 🔍 Kontrol Komutları

Tüm yapılandırmaları kontrol etmek için:

```bash
# GoogleService-Info.plist kontrolü
ls -la mobile/ios/Runner/GoogleService-Info.plist

# Info.plist içeriğini kontrol et
cat mobile/ios/Runner/Info.plist | grep -E "NSCameraUsageDescription|NSPhotoLibraryUsageDescription|NSUserNotificationsUsageDescription|CFBundleURLTypes|LSApplicationQueriesSchemes|UIBackgroundModes"

# AppDelegate.swift kontrolü
grep -E "Firebase|Messaging|UNUserNotificationCenter|GIDSignIn|ApplicationDelegate" mobile/ios/Runner/AppDelegate.swift
```

---

## 📝 Notlar

- Tüm değişikliklerden sonra `pod install` çalıştırın
- Xcode'da projeyi temizleyin: `Product > Clean Build Folder` (Cmd+Shift+K)
- Değişikliklerden sonra uygulamayı yeniden build edin
- Facebook App ID'yi environment variable veya config dosyasından alabilirsiniz
- Google Sign In için `REVERSED_CLIENT_ID` Info.plist'te olmalı (GoogleService-Info.plist'ten otomatik eklenir)

---

## 🆘 Sorun Giderme

### Firebase başlatılamıyor
- GoogleService-Info.plist dosyasının doğru konumda olduğundan emin olun
- Xcode'da dosyanın "Runner" target'ına eklendiğini kontrol edin
- Bundle ID'nin Firebase Console'daki ile eşleştiğinden emin olun

### Push notifications çalışmıyor
- APNs sertifikalarının Firebase Console'da yapılandırıldığından emin olun
- Xcode'da Push Notifications capability'sinin etkin olduğunu kontrol edin
- AppDelegate.swift'te delegate metodlarının doğru eklendiğinden emin olun

### Social Login çalışmıyor
- URL schemes'lerin Info.plist'te doğru yapılandırıldığından emin olun
- Facebook App ID'nin doğru olduğundan emin olun
- Google Sign In için REVERSED_CLIENT_ID'nin Info.plist'te olduğundan emin olun

---

**Son Güncelleme:** 2024-12-19  
**Durum:** ✅ TÜM İŞLER TAMAMLANDI! (12/12)

**📖 Xcode Capabilities için detaylı rehber:** `XCODE_CAPABILITIES_REHBERI.md` dosyasına bakın

---

## 🎉 TEBRİKLER! Tüm iOS Yapılandırmaları Tamamlandı!

✅ **12/12 iş tamamlandı:**
- ✅ GoogleService-Info.plist eklendi
- ✅ Tüm Info.plist izinleri eklendi
- ✅ AppDelegate.swift güncellemeleri yapıldı
- ✅ Xcode Capabilities etkinleştirildi

**Sonraki Adımlar:**
1. Projeyi build edin: `flutter build ios` veya Xcode'dan build
2. Uygulamayı test edin
3. Facebook App ID'yi `Info.plist`'te güncelleyin (şu an `fbYOUR_APP_ID` placeholder var)


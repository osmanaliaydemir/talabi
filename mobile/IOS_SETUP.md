# iOS Kurulum Rehberi

Bu rehber, Talâbî Flutter projesini iOS'ta çalıştırmak için gerekli adımları içerir.

## 📋 Önkoşullar

1. **Xcode** yüklü olmalı (App Store'dan indirebilirsiniz)
   - Minimum versiyon: Xcode 14.0+
   - Xcode Command Line Tools yüklü olmalı
   - Kontrol için: `xcode-select --version`

2. **CocoaPods** yüklü olmalı
   - Kontrol için: `pod --version`
   - Yüklü değilse: `sudo gem install cocoapods`
   - Güncelleme için: `sudo gem install cocoapods --pre`

3. **Flutter SDK** yüklü ve yapılandırılmış olmalı
   - Kontrol için: `flutter doctor`
   - iOS için gerekli tüm bileşenlerin yüklü olduğundan emin olun

## 🚀 Kurulum Adımları

### Adım 1: macOS Terminal Uygulamasını Açın

**ÖNEMLİ:** Xcode'un kendi terminali yoktur! Komutları çalıştırmak için macOS'un Terminal uygulamasını kullanmanız gerekir.

**Terminal'i açmak için:**
- `Cmd + Space` tuşlarına basın (Spotlight açılır)
- "Terminal" yazın ve Enter'a basın
- Veya Finder > Applications > Utilities > Terminal

### Adım 2: Flutter Bağımlılıklarını Yükleyin

Terminal'de proje kök dizinine gidin ve şu komutu çalıştırın:

```bash
cd ~/Desktop/projects/talabi/mobile
flutter pub get
```

**Not:** Eğer proje farklı bir konumdaysa, o konuma göre `cd` komutunu düzenleyin.

Bu komut, `pubspec.yaml` dosyasındaki tüm Flutter paketlerini indirir.

### Adım 3: iOS Bağımlılıklarını Yükleyin (CocoaPods)

iOS klasörüne gidin ve CocoaPods bağımlılıklarını yükleyin:

```bash
cd ios
pod install
```

**Not:** İlk kez çalıştırıyorsanız veya `Podfile` yoksa, Flutter otomatik olarak oluşturacaktır.

**Önemli:** Eğer hata alırsanız:
- `pod repo update` komutunu çalıştırın
- `pod deintegrate` ve sonra tekrar `pod install` deneyin
- Xcode'u kapatıp tekrar açın

### Adım 4: Xcode'da Projeyi Açın

**ÖNEMLİ:** `.xcodeproj` değil, `.xcworkspace` dosyasını açmalısınız!

```bash
open ios/Runner.xcworkspace
```

veya Finder'dan:
- `mobile/ios/Runner.xcworkspace` dosyasına çift tıklayın

### Adım 5: Xcode Yapılandırması

1. **Signing & Capabilities Ayarları:**
   - Sol panelde "Runner" projesini seçin
   - "Signing & Capabilities" sekmesine gidin
   - "Automatically manage signing" kutusunu işaretleyin
   - "Team" dropdown'ından Apple Developer hesabınızı seçin
   - Eğer hesabınız yoksa, Xcode size bir hesap oluşturma seçeneği sunacaktır (ücretsiz)

2. **Bundle Identifier Kontrolü:**
   - "Bundle Identifier" benzersiz olmalı
   - Örnek: `com.yourcompany.talabi` formatında olmalı

3. **Minimum iOS Versiyonu:**
   - "Deployment Info" bölümünden minimum iOS versiyonunu kontrol edin
   - Genellikle iOS 12.0 veya üzeri olmalı

### Adım 6: Gerçek iOS Cihazında Çalıştırma

#### 6.1: Cihazı Bağlama ve Güven

1. **iPhone/iPad'inizi USB ile Mac'inize bağlayın**
   - Orijinal Apple USB kablosunu kullanın
   - Cihazın kilidini açın

2. **Cihazda "Bu bilgisayara güven" mesajını onaylayın**
   - iPhone/iPad'de bir popup çıkacak
   - "Güven" butonuna tıklayın
   - Şifrenizi girmeniz gerekebilir

3. **Cihazın bağlı olduğunu kontrol edin**
   - Xcode'da üst kısımdaki cihaz seçici menüsünde cihazınızı görmelisiniz
   - Eğer görmüyorsanız, Xcode'u yeniden başlatın

#### 6.2: Developer Mode'u Etkinleştirme (iOS 16+)

**ÖNEMLİ:** iOS 16 veya üzeri sürümlerde Developer Mode'u etkinleştirmeniz gerekir!

**Developer Mode seçeneği görünmüyorsa:**

1. **iOS sürümünüzü kontrol edin:**
   - Ayarlar → Genel → Hakkında → Yazılım Sürümü
   - **iOS 15 ve altı:** Developer Mode gerekmez, direkt devam edebilirsiniz
   - **iOS 16 ve üzeri:** Developer Mode gerekli

2. **Developer Mode seçeneğini görünür yapmak için:**
   - Önce Xcode'da cihazınızı seçip bir kez build deneyin
   - Xcode ile cihaz arasında bağlantı kurulduğunda Developer Mode seçeneği görünür hale gelir
   - Veya Terminal'den: `flutter run` komutunu çalıştırın, hata alsanız bile Developer Mode seçeneği görünür hale gelir

3. **Developer Mode'u etkinleştirme (iOS 16+):**
   - Ayarlar (Settings) → Gizlilik ve Güvenlik (Privacy & Security)
   - Aşağı kaydırın ve "Developer Mode" seçeneğini bulun
   - Developer Mode'u **AÇIK** yapın
   - Cihaz yeniden başlatılacak (restart)

4. **Cihaz yeniden başladıktan sonra:**
   - Developer Mode'u etkinleştirmek isteyip istemediğiniz sorulacak
   - "Turn On" butonuna tıklayın
   - Şifrenizi girmeniz gerekebilir
   - Tekrar restart olacak

**Not:** 
- iOS 15 ve altı sürümlerde Developer Mode gerekmez, direkt uygulamayı çalıştırabilirsiniz
- Developer Mode seçeneği bazen Xcode ile cihaz arasında ilk bağlantı kurulduğunda görünür hale gelir

#### 6.3: Xcode'da Cihazı Seçme

1. **Xcode'da üst kısımdaki cihaz seçici menüsüne tıklayın**
   - Menüde "Any iOS Device" yerine cihazınızın adını görmelisiniz
   - Örnek: "Osman's iPhone" veya "iPhone 14 Pro"

2. **Cihazınızı seçin**
   - Listeden bağlı cihazınızı seçin
   - Eğer cihaz görünmüyorsa:
     - Cihazın kilidini açın
     - USB kablosunu çıkarıp tekrar takın
     - Xcode'u yeniden başlatın

#### 6.4: Signing & Capabilities Ayarları (Cihaz için)

1. **Xcode'da sol panelde "Runner" projesini seçin**

2. **"Signing & Capabilities" sekmesine gidin**

3. **"Automatically manage signing" kutusunu işaretleyin**

4. **"Team" dropdown'ından Apple ID'nizi seçin**
   - Eğer Apple ID yoksa, "Add Account..." butonuna tıklayın
   - Apple ID ile giriş yapın (ücretsiz Apple Developer hesabı yeterli)

5. **Bundle Identifier'ı benzersiz yapın**
   - Varsayılan: `com.example.mobile`
   - Bunu benzersiz bir değerle değiştirin
   - Örnek: `com.yourname.talabi` veya `com.yourcompany.talabi`
   - **ÖNEMLİ:** Her cihaz için farklı bir Bundle ID kullanabilirsiniz

6. **Provisioning Profile otomatik oluşturulacak**
   - Xcode otomatik olarak bir provisioning profile oluşturacak
   - "Signing certificate" bilgisini kontrol edin
   - Hata varsa, Team'i tekrar seçin

#### 6.5: İlk Kez Çalıştırma - Cihazda Güven

İlk kez cihazınıza uygulama yüklerken:

1. **Xcode'dan uygulamayı çalıştırın** (▶️ butonu veya Cmd+R)

2. **Cihazınızda bir uyarı çıkacak:**
   - "Untrusted Developer" mesajı görünebilir
   - Ayarlar → Genel → VPN ve Cihaz Yönetimi (veya "Device Management")
   - Developer App bölümünde Apple ID'nizi bulun
   - Apple ID'nize tıklayın ve "Trust" butonuna basın
   - "Trust" onayını verin

3. **Uygulamayı tekrar çalıştırın**
   - Artık uygulama cihazınızda açılacaktır

**Simülatör Kullanımı (Alternatif):**
- Xcode'un üst kısmındaki cihaz seçici menüsünden bir iOS simülatörü seçin
- İstediğiniz iPhone/iPad modelini seçin
- Simülatör için Developer Mode gerekmez

### Adım 7: Projeyi Gerçek Cihazda Çalıştırın

#### 7.1: Xcode'dan Çalıştırma (Önerilen)

1. **Xcode'da üst kısımdan cihazınızı seçtiğinizden emin olun**
   - Cihaz seçici menüsünde cihazınızın adı görünmeli

2. **Sol üst köşedeki ▶️ (Play) butonuna tıklayın**
   - Veya `Cmd + R` tuş kombinasyonunu kullanın

3. **İlk build biraz zaman alabilir (5-10 dakika)**
   - Xcode alt kısmındaki progress bar'ı takip edin
   - Hata varsa, alt kısımdaki console'da görünecektir

4. **Uygulama cihazınıza yüklenecek ve otomatik açılacak**

#### 7.2: Terminal'den Çalıştırma (Alternatif)

**Terminal'de (macOS Terminal uygulamasında):**

```bash
cd ~/Desktop/projects/talabi/mobile
flutter devices  # Bağlı cihazları listeler
```

Çıktıda cihazınızı göreceksiniz, örnek:
```
iPhone (mobile) • 00008030-001A... • ios • iOS 17.0
```

Sonra cihazınızı seçerek çalıştırın:
```bash
flutter run -d <device-id>
```

veya direkt çalıştırın (Flutter otomatik seçer):
```bash
flutter run
```

**Not:** Terminal penceresi Xcode'dan ayrı bir uygulamadır. Xcode açıkken Terminal'i de açık tutabilirsiniz.

#### 7.3: Hot Reload (Sıcak Yenileme)

Uygulama çalışırken kod değişikliklerini anında görmek için:

- **Terminal'de:** `r` tuşuna basın (hot reload)
- **Terminal'de:** `R` tuşuna basın (hot restart - tam yeniden başlatma)
- **Xcode'da:** Uygulamayı durdurup tekrar çalıştırın

## 🔧 Olası Sorunlar ve Çözümleri

### Sorun 1: "No Podfile found"
**Çözüm:**
```bash
cd mobile/ios
pod init
pod install
```

### Sorun 2: CocoaPods bağımlılık hataları
**Çözüm:**
```bash
cd mobile/ios
pod deintegrate
pod cache clean --all
pod install --repo-update
```

### Sorun 3: Signing hatası
**Çözüm:**
- Xcode'da Signing & Capabilities'te doğru Team seçildiğinden emin olun
- Bundle Identifier'ın benzersiz olduğunu kontrol edin
- Apple Developer hesabınızın aktif olduğundan emin olun
- "Automatically manage signing" seçeneğinin işaretli olduğundan emin olun
- Xcode'u kapatıp açın ve tekrar deneyin

### Sorun 3.1: "Untrusted Developer" hatası
**Çözüm:**
1. iPhone/iPad'de: Ayarlar → Genel → VPN ve Cihaz Yönetimi
2. Developer App bölümünde Apple ID'nizi bulun
3. Apple ID'nize tıklayın ve "Trust" butonuna basın
4. Uygulamayı tekrar çalıştırın

### Sorun 3.2: "Developer Mode" hatası veya seçeneği görünmüyor (iOS 16+)
**Çözüm:**

**Developer Mode seçeneği görünmüyorsa:**
1. iOS sürümünüzü kontrol edin (Ayarlar → Genel → Hakkında)
   - iOS 15 ve altı: Developer Mode gerekmez, bu adımı atlayın
   - iOS 16+: Developer Mode gerekli

2. Developer Mode seçeneğini görünür yapmak için:
   - Xcode'da cihazınızı seçip bir kez build deneyin (hata alsanız bile)
   - Veya Terminal'den: `cd ~/Desktop/projects/talabi/mobile && flutter run` komutunu çalıştırın
   - Xcode ile cihaz arasında bağlantı kurulduğunda Developer Mode seçeneği görünür hale gelir

3. Developer Mode'u etkinleştirme:
   - iPhone/iPad'de: Ayarlar → Gizlilik ve Güvenlik → Developer Mode
   - Developer Mode'u AÇIK yapın
   - Cihazı yeniden başlatın
   - Developer Mode'u etkinleştirmek isteyip istemediğiniz sorulduğunda "Turn On" deyin
   - Tekrar restart olacak, sonra uygulamayı çalıştırın

### Sorun 3.3: Cihaz görünmüyor
**Çözüm:**
- USB kablosunu çıkarıp tekrar takın
- Cihazın kilidini açın
- Cihazda "Bu bilgisayara güven" mesajını onaylayın
- Xcode'u kapatıp açın
- Mac'i yeniden başlatın (gerekirse)
- Farklı bir USB portu deneyin
- Orijinal Apple kablosu kullandığınızdan emin olun

### Sorun 4: "Command PhaseScriptExecution failed"
**Çözüm:**
```bash
cd mobile
flutter clean
flutter pub get
cd ios
pod install
```

### Sorun 5: Firebase yapılandırma hatası
**Çözüm:**
- `mobile/ios/Runner/GoogleService-Info.plist` dosyasının mevcut olduğundan emin olun
- Firebase Console'dan doğru iOS uygulaması için indirdiğiniz dosyayı kullandığınızdan emin olun

## 📱 Firebase Yapılandırması

Proje Firebase kullanıyor, bu yüzden:

1. Firebase Console'a gidin
2. iOS uygulamanızı oluşturun (eğer yoksa)
3. `GoogleService-Info.plist` dosyasını indirin
4. Dosyayı `mobile/ios/Runner/` klasörüne kopyalayın
5. Xcode'da projeyi yeniden açın

## 🎯 Hızlı Başlangıç Komutları

**ÖNEMLİ:** Bu komutları macOS Terminal uygulamasında çalıştırın (Xcode'da değil)!

Tüm adımları tek seferde yapmak için:

```bash
cd ~/Desktop/projects/talabi/mobile
flutter pub get
cd ios
pod install
cd ..
flutter run
```

**Terminal'i açmak:**
- `Cmd + Space` → "Terminal" yazın → Enter
- Veya Finder > Applications > Utilities > Terminal

## 📝 Notlar

- İlk build işlemi biraz zaman alabilir (5-10 dakika)
- Xcode'u her açtığınızda projeyi temizlemek için: `Product > Clean Build Folder` (Cmd+Shift+K)
- Hot reload için Flutter'ın development mode'da çalıştığından emin olun
- Production build için: `flutter build ios --release`

## 🆘 Yardım

Sorun yaşarsanız:
1. `flutter doctor -v` komutunu çalıştırın ve çıktıyı kontrol edin
2. Xcode Console'da hata mesajlarını kontrol edin
3. Flutter ve CocoaPods'u güncel tutun


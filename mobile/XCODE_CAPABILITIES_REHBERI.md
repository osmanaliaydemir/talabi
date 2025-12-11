# Xcode Capabilities Kurulum Rehberi

Bu rehber, iOS uygulaması için gerekli Xcode Capabilities'lerin nasıl etkinleştirileceğini açıklar.

## 📋 Gereksinimler

- Xcode yüklü olmalı
- `ios/Runner.xcworkspace` dosyası mevcut olmalı
- Apple Developer hesabı (ücretsiz hesap yeterli)

---

## 🎯 Yapılacak İşlemler

### 1. Background Modes Capability

**Amaç:** Arka planda konum takibi ve push notifications için gerekli.

**Adımlar:**

1. **Xcode'u açın**
   ```bash
   open ios/Runner.xcworkspace
   ```
   ⚠️ **ÖNEMLİ:** `.xcodeproj` değil, `.xcworkspace` dosyasını açın!

2. **Sol panelde "Runner" projesini seçin**
   - Sol üst köşedeki proje navigator'da (dosya ağacı) en üstteki "Runner" mavi ikonuna tıklayın
   - Bu, proje ayarlarını açacaktır

3. **"Signing & Capabilities" sekmesine gidin**
   - Ortadaki üst menüden "Signing & Capabilities" sekmesini seçin
   - Varsayılan olarak "General" sekmesi açık olabilir

4. **"+ Capability" butonuna tıklayın**
   - Sol üst köşede, "Signing & Capabilities" başlığının altında
   - "+ Capability" butonunu bulun ve tıklayın

5. **"Background Modes" seçin**
   - Açılan listeden "Background Modes" seçeneğini bulun
   - Üzerine tıklayın

6. **Seçenekleri işaretleyin**
   - "Background Modes" capability eklendikten sonra, altında seçenekler görünecek
   - Şu seçenekleri işaretleyin:
     - ✅ **Location updates** (Konum güncellemeleri için)
     - ✅ **Remote notifications** (Push notifications için)

**Görsel İpuçları:**
- "Background Modes" eklendikten sonra, capability listesinde görünecek
- Her capability'nin yanında bir "X" butonu var (kaldırmak için)
- Seçenekler checkbox'lar olarak görünecek

---

### 2. Push Notifications Capability

**Amaç:** Push notifications'ın çalışması için gerekli.

**Adımlar:**

1. **Aynı "Signing & Capabilities" sekmesinde kalın**
   - Hala "Runner" projesi seçili ve "Signing & Capabilities" sekmesinde olmalısınız

2. **Tekrar "+ Capability" butonuna tıklayın**
   - Sol üst köşedeki "+ Capability" butonuna tekrar tıklayın

3. **"Push Notifications" seçin**
   - Açılan listeden "Push Notifications" seçeneğini bulun
   - Üzerine tıklayın

4. **Otomatik olarak eklenecek**
   - "Push Notifications" capability eklendikten sonra, herhangi bir ek seçenek yok
   - Sadece capability'nin eklendiğini göreceksiniz

**Not:** Push Notifications capability'si eklendikten sonra, Xcode otomatik olarak gerekli ayarları yapacaktır.

---

## ✅ Kontrol

Capabilities'lerin doğru eklendiğini kontrol etmek için:

1. **"Signing & Capabilities" sekmesinde**
   - "Background Modes" capability'sini görmelisiniz
   - "Push Notifications" capability'sini görmelisiniz

2. **"Background Modes" altında**
   - ✅ Location updates işaretli olmalı
   - ✅ Remote notifications işaretli olmalı

---

## 🔍 Sorun Giderme

### Capability eklenmiyor
- Xcode'u yeniden başlatın
- Projeyi temizleyin: `Product > Clean Build Folder` (Cmd+Shift+K)
- `.xcworkspace` dosyasını açtığınızdan emin olun (`.xcodeproj` değil)

### "Signing & Capabilities" sekmesi görünmüyor
- Sol panelde "Runner" projesini (mavi ikon) seçtiğinizden emin olun
- "Runner" klasörünü değil, proje ikonunu seçin

### Capability seçenekleri görünmüyor
- Capability'yi ekledikten sonra, altında seçenekler otomatik görünür
- Eğer görünmüyorsa, capability'yi kaldırıp tekrar ekleyin

---

## 📝 Notlar

- Capabilities'ler proje seviyesinde ayarlanır
- Her capability, `Info.plist` dosyasına otomatik olarak gerekli ayarları ekler
- Capabilities'ler Apple Developer Portal'da da görünecektir (App Store'a yüklerken)

---

## 🎉 Tamamlandı!

Capabilities'leri ekledikten sonra:
1. Projeyi kaydedin (Cmd+S)
2. Xcode'u kapatabilirsiniz (isteğe bağlı)
3. Flutter build komutunu çalıştırabilirsiniz

**Sonraki Adım:** `ios_todo.md` dosyasındaki ilgili maddeleri ✅ olarak işaretleyin.


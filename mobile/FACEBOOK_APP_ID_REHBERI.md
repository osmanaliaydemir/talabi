# Facebook App ID Alma Rehberi

Bu rehber, Facebook Login için gerekli App ID'yi nasıl alacağınızı açıklar.

## 📋 Gereksinimler

- Facebook hesabı
- Facebook Developer hesabı (ücretsiz)

---

## 🚀 Adım Adım Rehber

### Adım 1: Facebook Developer Console'a Giriş

1. **Facebook Developer Console'u açın**
   - Tarayıcınızda şu adrese gidin: https://developers.facebook.com/
   - Facebook hesabınızla giriş yapın

2. **Developer hesabı oluşturun (eğer yoksa)**
   - İlk kez giriş yapıyorsanız, "Get Started" butonuna tıklayın
   - Gerekli bilgileri doldurun (ad, soyad, e-posta)
   - Telefon numaranızı doğrulayın
   - Developer hesabı oluşturulacak (ücretsiz)

---

### Adım 2: Yeni Uygulama Oluşturma

1. **"My Apps" menüsüne gidin**
   - Sağ üst köşede "My Apps" butonuna tıklayın
   - Veya direkt: https://developers.facebook.com/apps/

2. **"Create App" butonuna tıklayın**
   - Sayfanın sağ üst köşesinde yeşil "Create App" butonunu bulun

3. **Uygulama türünü seçin**
   - Açılan pencerede "Consumer" veya "Business" seçeneğini seçin
   - "Next" butonuna tıklayın

4. **Uygulama bilgilerini doldurun**
   - **App Display Name:** Uygulamanızın adı (örn: "Talabi")
   - **App Contact Email:** İletişim e-postanız
   - **Business Account (Opsiyonel):** İşletme hesabı seçebilirsiniz
   - "Create App" butonuna tıklayın

5. **Güvenlik kontrolü**
   - CAPTCHA'yı tamamlayın
   - Uygulama oluşturulacak

---

### Adım 3: App ID'yi Bulma

1. **Uygulama Dashboard'una gidin**
   - Oluşturduğunuz uygulamanın adına tıklayın
   - Dashboard açılacak

2. **App ID'yi kopyalayın**
   - Dashboard'un sol üst köşesinde "App ID" ve "App Secret" görünecek
   - **App ID** değerini kopyalayın (örnek: `1234567890123456`)
   - ⚠️ **App Secret'i de not edin** (daha sonra backend için gerekebilir)

---

### Adım 4: iOS Platform Ekleme

1. **Settings menüsüne gidin**
   - Sol menüden "Settings" > "Basic" seçeneğine tıklayın

2. **Platform ekleyin**
   - Sayfanın alt kısmında "+ Add Platform" butonuna tıklayın
   - Açılan listeden "iOS" seçeneğini seçin

3. **Bundle ID'yi girin**
   - **Bundle ID:** `com.talabi.mobile`
   - "Save Changes" butonuna tıklayın

---

### Adım 5: Facebook Login Özelliğini Etkinleştirme

1. **Products menüsüne gidin**
   - Sol menüden "Products" seçeneğine tıklayın
   - Veya Dashboard'da "Add Product" butonuna tıklayın

2. **Facebook Login ekleyin**
   - Ürün listesinden "Facebook Login" seçeneğini bulun
   - "Set Up" butonuna tıklayın

3. **iOS ayarlarını yapın**
   - "Settings" > "Facebook Login" > "Settings" sekmesine gidin
   - **Valid OAuth Redirect URIs** bölümüne şunu ekleyin:
     ```
     fb{APP_ID}://authorize
     ```
     Örnek: `fb1234567890123456://authorize`
   - "Save Changes" butonuna tıklayın

---

### Adım 6: Info.plist'e App ID Ekleme

1. **App ID'yi Info.plist'e ekleyin**
   - `mobile/ios/Runner/Info.plist` dosyasını açın
   - `fbYOUR_APP_ID` yerine gerçek App ID'nizi yazın:
   
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>fb1234567890123456</string>  <!-- App ID'nizi buraya yazın -->
           </array>
       </dict>
   </array>
   ```

2. **Örnek:**
   - Eğer App ID'niz `1234567890123456` ise:
   ```xml
   <string>fb1234567890123456</string>
   ```

---

## ✅ Kontrol Listesi

- [ ] Facebook Developer hesabı oluşturuldu
- [ ] Yeni uygulama oluşturuldu
- [ ] App ID kopyalandı
- [ ] iOS platform eklendi (Bundle ID: `com.talabi.mobile`)
- [ ] Facebook Login özelliği etkinleştirildi
- [ ] OAuth Redirect URI eklendi
- [ ] Info.plist'te App ID güncellendi

---

## 🔍 App ID Formatı

Facebook App ID genellikle **15-16 haneli bir sayıdır**:
- Örnek: `1234567890123456`
- Info.plist'te `fb` prefix'i ile kullanılır: `fb1234567890123456`

---

## 📝 Notlar

- **App Secret:** Backend'de kullanılacak, güvenli tutun
- **App Review:** Facebook Login'i production'da kullanmak için App Review gerekebilir
- **Test Kullanıcıları:** Geliştirme aşamasında test kullanıcıları ekleyebilirsiniz
- **Privacy Policy:** Production'da kullanmak için Privacy Policy URL'i gerekebilir

---

## 🆘 Sorun Giderme

### App ID bulamıyorum
- Dashboard'un sol üst köşesinde "App ID" yazısını arayın
- Settings > Basic sayfasına gidin, orada görünecektir

### Facebook Login çalışmıyor
- Bundle ID'nin doğru olduğundan emin olun (`com.talabi.mobile`)
- Info.plist'te `fb` prefix'inin olduğundan emin olun
- OAuth Redirect URI'nin doğru olduğundan emin olun
- Uygulamayı yeniden başlatın

### "App Not Setup" hatası
- Facebook Login özelliğinin etkinleştirildiğinden emin olun
- iOS platform'unun eklendiğinden emin olun
- Bundle ID'nin doğru olduğundan emin olun

---

## 🔗 Faydalı Linkler

- **Facebook Developer Console:** https://developers.facebook.com/
- **Facebook Login Dokümantasyonu:** https://developers.facebook.com/docs/facebook-login/
- **iOS Setup Guide:** https://developers.facebook.com/docs/facebook-login/ios

---

**Son Güncelleme:** 2024-12-19


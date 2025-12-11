# Talabi API Penetrasyon Testleri Dokümantasyonu

## 📋 İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Proje Yapısı](#proje-yapısı)
3. [Test Kategorileri](#test-kategorileri)
4. [Kurulum ve Çalıştırma](#kurulum-ve-çalıştırma)
5. [Tespit Edilen Güvenlik Açıkları](#tespit-edilen-güvenlik-açıkları)
6. [Test Senaryoları Detayları](#test-senaryoları-detayları)
7. [Öneriler ve Düzeltmeler](#öneriler-ve-düzeltmeler)
8. [Sürekli Entegrasyon](#sürekli-entegrasyon)

---

## 🎯 Genel Bakış

Bu proje, Talabi API uygulamasının güvenlik açıklarını tespit etmek için kapsamlı penetrasyon testleri içerir. Testler, OWASP Top 10 ve yaygın web uygulaması güvenlik açıklarını kapsar.

### Amaç
- API güvenlik açıklarını tespit etmek
- Güvenlik kontrollerinin etkinliğini doğrulamak
- Production'a geçmeden önce güvenlik risklerini belirlemek
- Güvenlik standartlarına uyumu sağlamak

### Kapsam
- Authentication ve Authorization
- Input Validation ve Sanitization
- File Upload Güvenliği
- SQL Injection ve XSS Korumaları
- Rate Limiting
- Information Disclosure
- IDOR (Insecure Direct Object Reference)

---

## 📁 Proje Yapısı

```
Talabi.Api.Tests.Penetration/
├── AuthenticationTests.cs          # Kimlik doğrulama testleri
├── FileUploadTests.cs             # Dosya yükleme güvenlik testleri
├── InjectionTests.cs              # SQL Injection, XSS testleri
├── IdorTests.cs                   # IDOR testleri
├── RateLimitingTests.cs           # Rate limiting testleri
├── InformationDisclosureTests.cs   # Bilgi açığa çıkması testleri
├── Program.cs                     # Test helper dosyası
├── Talabi.Api.Tests.Penetration.csproj
├── README.md
└── DOKUMANTASYON.md               # Bu dosya
```

---

## 🧪 Test Kategorileri

### 1. AuthenticationTests

**Amaç:** Kimlik doğrulama ve yetkilendirme mekanizmalarını test eder.

**Test Senaryoları:**
- ✅ Geçersiz kimlik bilgileriyle giriş denemeleri
- ✅ Kullanıcı varlığının açığa çıkmaması kontrolü
- ✅ Zayıf şifre kontrolleri
- ✅ JWT token manipülasyonu
- ✅ Refresh token güvenliği
- ✅ External login (Google, Apple, Facebook) güvenlik açıkları
- ✅ Email doğrulama brute force saldırıları
- ✅ Şifre sıfırlama güvenliği

**Kritik Bulgular:**
- ✅ **External Login Token Doğrulaması Eklendi**: Google, Apple, Facebook token'ları artık `ExternalAuthTokenVerifier` servisi ile doğrulanıyor. (✅ TAMAMLANDI)
- ✅ **Email Doğrulama Brute Force Koruması Eklendi**: `VerificationCodeSecurityService` ile attempt tracking, rate limiting ve lockout mekanizması eklendi. (✅ TAMAMLANDI)
- ✅ **Kullanıcı Varlığı Bilgisi Korunuyor**: Login ve forgot password endpoint'lerinde kullanıcı varlığı açığa çıkmıyor (güvenli).
- ✅ **JWT Token Validation Aktif**: Token doğrulama mekanizması çalışıyor, manipüle edilmiş token'lar reddediliyor.

---

### 2. FileUploadTests

**Amaç:** Dosya yükleme endpoint'lerinin güvenliğini test eder.

**Test Senaryoları:**
- ✅ Yetkisiz dosya yükleme denemeleri
- ✅ Executable dosya yükleme (`.exe`, `.dll`, `.bat`)
- ✅ Aşırı büyük dosya yükleme (100MB+)
- ✅ Path traversal saldırıları (`../../../etc/passwd`)
- ✅ Script dosyası yükleme (`.html`, `.js`, `.php`)
- ✅ Çift uzantı saldırıları (`image.jpg.exe`)

**Kritik Bulgular:**
- ✅ **Dosya tipi kontrolü eklendi**: `FileUploadSecurityService` ile whitelist kontrolü yapılıyor (jpg, jpeg, png, gif, webp). (✅ TAMAMLANDI)
- ✅ **Dosya boyutu kontrolü eklendi**: Maksimum 5MB limiti uygulanıyor. (✅ TAMAMLANDI)
- ✅ **Dosya içeriği kontrolü eklendi**: Magic bytes kontrolü ile dosya içeriği doğrulanıyor. (✅ TAMAMLANDI)
- ✅ **Path traversal koruması eklendi**: Dosya adı sanitization ile path traversal saldırıları engelleniyor. (✅ TAMAMLANDI)

**Uygulanan Düzeltmeler:**
```csharp
// FileUploadSecurityService ile tüm kontroller eklendi
- Dosya tipi whitelist kontrolü
- Dosya boyutu limiti (5MB)
- Magic bytes kontrolü
- Path traversal koruması
- Çift uzantı saldırısı koruması
```

---

### 3. InjectionTests

**Amaç:** SQL Injection, XSS ve diğer injection saldırılarını test eder.

**Test Senaryoları:**
- ✅ SQL Injection saldırıları
  - `' OR '1'='1`
  - `'; DROP TABLE Users; --`
  - `' UNION SELECT * FROM Users --`
- ✅ XSS (Cross-Site Scripting) saldırıları
  - `<script>alert('XSS')</script>`
  - `<img src=x onerror=alert('XSS')>`
  - `javascript:alert('XSS')`
- ✅ Command Injection saldırıları
- ✅ Path Traversal saldırıları
- ✅ NoSQL Injection saldırıları

**Kritik Bulgular:**
- ✅ Entity Framework parametreli sorgular kullanılıyor (SQL Injection korumalı)
- ✅ Input sanitization filter aktif
- ✅ **XSS Payload Sanitization Geliştirildi**: `InputSanitizationActionFilter` güncellendi - string argument'leri ve query parametreleri artık otomatik olarak sanitize ediliyor. (✅ TAMAMLANDI)

---

### 4. IdorTests

**Amaç:** Insecure Direct Object Reference açıklarını test eder.

**Test Senaryoları:**
- ✅ Başka kullanıcının order'ına erişim denemeleri
- ✅ Yetkisiz order durumu güncelleme
- ✅ Başka kullanıcının order'ını iptal etme
- ✅ Başka kullanıcının profil bilgilerine erişim

**Kritik Bulgular:**
- ✅ Order endpoint'lerinde kullanıcı kontrolü yapılıyor
- ✅ **Authorization Kontrolleri Eklendi**: `GetOrder`, `GetOrderDetail`, `UpdateOrderStatus` ve `CancelOrder` endpoint'lerinde eksiksiz authorization kontrolleri eklendi. (✅ TAMAMLANDI)
- ✅ **OrderService Authorization**: `CancelOrderAsync` ve `UpdateOrderStatusAsync` metodlarında authorization kontrolleri eklendi. (✅ TAMAMLANDI)

**Uygulanan Düzeltmeler:**
```csharp
// OrdersController - GetOrder ve GetOrderDetail
// Authorization: User must be authenticated
if (string.IsNullOrWhiteSpace(userId))
{
    return Unauthorized();
}
// Only allow access to orders that belong to the authenticated user
var order = await query.FirstOrDefaultAsync(o => o.Id == id && o.CustomerId == userId);

// OrderService - CancelOrderAsync
// Authorization: Only the customer who owns the order can cancel it
if (order.CustomerId != userId)
{
    throw new UnauthorizedAccessException();
}

// OrderService - UpdateOrderStatusAsync
// Authorization: Vendor owner, assigned courier, or customer can update
var isVendorOwner = order.Vendor != null && order.Vendor.OwnerId == userId;
var isAssignedCourier = await _unitOfWork.OrderCouriers.Query()
    .AnyAsync(oc => oc.OrderId == orderId && oc.Courier.UserId == userId && oc.IsActive);
if (!isVendorOwner && !isAssignedCourier && !isCustomer)
{
    throw new UnauthorizedAccessException();
}
```

---

### 5. RateLimitingTests

**Amaç:** Rate limiting mekanizmasının etkinliğini test eder.

**Test Senaryoları:**
- ✅ Login brute force saldırıları (100+ istek)
- ✅ Kayıt endpoint'ine çoklu istek
- ✅ Arama endpoint'ine hızlı istekler
- ✅ Farklı IP adreslerinden bypass denemeleri

**Kritik Bulgular:**
- ⚠️ Rate limiting 60 request/dakika (çok yüksek)
- ⚠️ Endpoint bazlı rate limiting yok
- ⚠️ IP bazlı rate limiting aktif ama bypass edilebilir

**Önerilen Düzeltmeler:**
```csharp
// Daha düşük limitler ve endpoint bazlı rate limiting
new RateLimitRule
{
    Endpoint = "/api/auth/login",
    Period = "1m",
    Limit = 5  // Login için daha düşük limit
},
new RateLimitRule
{
    Endpoint = "/api/auth/register",
    Period = "1h",
    Limit = 3  // Kayıt için çok düşük limit
}
```

---

### 6. InformationDisclosureTests

**Amaç:** Hassas bilgilerin açığa çıkmasını test eder.

**Test Senaryoları:**
- ✅ Stack trace açığa çıkması
- ✅ Database hata mesajları
- ✅ Server bilgisi header'ları
- ✅ Health check endpoint'lerinde hassas bilgiler
- ✅ OpenAPI endpoint erişilebilirliği
- ✅ Hangfire dashboard erişim kontrolü
- ✅ Dosya yolu açığa çıkması

**Kritik Bulgular:**
- ✅ ExceptionHandlingMiddleware aktif
- ✅ **OpenAPI Endpoint Production'da Kapalı**: OpenAPI endpoint'i (`/openapi/v1.json`) sadece Development ortamında aktif, Production'da kapalı. (✅ TAMAMLANDI)
- ✅ **Hangfire Dashboard Authentication Eklendi**: `HangfireAuthorizationFilter` ile sadece Admin rolüne sahip kullanıcılar Hangfire Dashboard'a erişebilir. (✅ TAMAMLANDI)
- ✅ **CORS Production Yapılandırması Eklendi**: Environment bazlı CORS yapılandırması eklendi. Local, Test ve Production için ayrı URL'ler appsettings.json'dan okunuyor. (✅ TAMAMLANDI)
- ✅ **Health Check Endpoint'lerinde Hassas Bilgiler Gizlendi**: Production'da exception mesajları, stack trace'ler ve detaylı hata bilgileri gizleniyor. Sadece status bilgisi döndürülüyor. (✅ TAMAMLANDI)

---

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- .NET 9.0 SDK
- Visual Studio 2022 veya VS Code
- Talabi.Api projesi çalışır durumda olmalı

### Kurulum

```bash
# Projeyi klonlayın
cd src/Talabi.Api.Tests.Penetration

# NuGet paketlerini geri yükleyin
dotnet restore

# Projeyi derleyin
dotnet build
```

### Test Çalıştırma

```bash
# Tüm testleri çalıştır
dotnet test

# Belirli bir test kategorisini çalıştır
dotnet test --filter "FullyQualifiedName~AuthenticationTests"

# Detaylı çıktı ile
dotnet test --logger "console;verbosity=detailed"

# Code coverage ile
dotnet test /p:CollectCoverage=true
```

### Test Sonuçları

Test sonuçları şu formatta görüntülenir:
- ✅ **Başarılı:** Güvenlik kontrolü çalışıyor
- ❌ **Başarısız:** Güvenlik açığı tespit edildi
- ⚠️ **Uyarı:** Potansiyel güvenlik riski

---

## 🔍 Tespit Edilen Güvenlik Açıkları

### 🔴 Kritik Öncelik

#### 1. External Login Token Doğrulaması ✅ TAMAMLANDI
**Lokasyon:** `AuthController.ExternalLogin`
**Açıklama:** External login endpoint'inde Google, Apple, Facebook token'ları doğrulanmıyor.
**Risk:** Sahte token'larla yetkisiz giriş yapılabilir.
**Durum:** ✅ **TAMAMLANDI** - `ExternalAuthTokenVerifier` servisi oluşturuldu ve entegre edildi.
**Uygulanan Düzeltme:**
- `IExternalAuthTokenVerifier` interface ve `ExternalAuthTokenVerifier` implementasyonu eklendi
- Google token doğrulama (OAuth2 API)
- Apple token doğrulama (JWT validation)
- Facebook token doğrulama (Graph API)
- Token expiration ve email doğrulama kontrolleri eklendi

#### 2. File Upload Güvenlik Kontrolleri ✅ TAMAMLANDI
**Lokasyon:** `UploadController.Upload`
**Açıklama:** Dosya tipi, boyutu ve içeriği kontrol edilmiyor.
**Risk:** Zararlı dosyalar yüklenebilir, sunucu ele geçirilebilir.
**Durum:** ✅ **TAMAMLANDI** - `FileUploadSecurityService` oluşturuldu ve entegre edildi.
**Uygulanan Düzeltme:**
- ✅ Dosya tipi whitelist'i (jpg, jpeg, png, gif, webp)
- ✅ Dosya boyutu limiti (5MB)
- ✅ Magic bytes kontrolü
- ✅ Dosya adı sanitization
- ✅ Path traversal koruması
- ✅ Çift uzantı saldırısı koruması

#### 3. Hassas Bilgiler appsettings.json'da ✅ KISMEN TAMAMLANDI
**Lokasyon:** `appsettings.json`
**Açıklama:** Connection string, JWT secret, API key'ler açık metin.
**Risk:** Kod deposuna sızıntı durumunda tüm sistem ele geçirilebilir.
**Durum:** ✅ **KISMEN TAMAMLANDI** - Hassas bilgiler kaldırıldı, placeholder'lar eklendi.
**Uygulanan Düzeltme:**
- ✅ Hassas bilgiler appsettings.json'dan kaldırıldı
- ✅ Placeholder değerler eklendi ("USE_USER_SECRETS_OR_ENVIRONMENT_VARIABLES")
- ⚠️ User Secrets entegrasyonu yapılmalı (Development)
- ⚠️ Azure Key Vault entegrasyonu yapılmalı (Production)

### 🟠 Yüksek Öncelik

#### 4. CORS Development'ta Tüm Origin'lere Açık
**Lokasyon:** `Program.cs` (satır 175-177)
**Açıklama:** Development modunda tüm origin'lere izin veriliyor.
**Risk:** CSRF saldırılarına açık.
**Düzeltme:** Production'da sadece gerekli origin'lere izin ver.

#### 5. Rate Limiting Yüksek
**Lokasyon:** `Program.cs` (satır 137)
**Açıklama:** 60 request/dakika çok yüksek.
**Risk:** Brute force saldırılarına karşı yetersiz.
**Düzeltme:** Endpoint bazlı düşük limitler.

#### 6. ConfirmEmail Endpoint'inde Token Validation Yok
**Lokasyon:** `AuthController.ConfirmEmail`
**Açıklama:** Token validation yapılmıyor.
**Risk:** Geçersiz token'larla email doğrulama yapılabilir.

### 🟡 Orta Öncelik

#### 7. CSP'de unsafe-inline ve unsafe-eval
**Lokasyon:** `SecurityHeadersMiddleware.cs`
**Açıklama:** Content Security Policy'de güvenlik açıkları var.
**Risk:** XSS saldırılarına karşı koruma zayıf.

#### 8. Hangfire Dashboard Erişim Kontrolü
**Lokasyon:** `Program.cs` (satır 362)
**Açıklama:** Dashboard herkese açık olabilir.
**Risk:** Arka plan job'ları görüntülenebilir, manipüle edilebilir.

---

## 📝 Test Senaryoları Detayları

### Authentication Test Senaryoları

| Test Adı | Açıklama | Beklenen Sonuç |
|----------|----------|----------------|
| `Login_WithInvalidCredentials_ShouldNotRevealUserExistence` | Geçersiz kimlik bilgileriyle giriş | Kullanıcı varlığı açığa çıkmamalı |
| `Register_WithWeakPassword_ShouldBeRejected` | Zayıf şifre ile kayıt | Kayıt reddedilmeli |
| `RefreshToken_WithExpiredToken_ShouldBeRejected` | Süresi dolmuş token ile yenileme | İstek reddedilmeli |
| `ExternalLogin_WithoutTokenVerification_ShouldBeVulnerable` | Token doğrulaması olmadan external login | Güvenlik açığı tespit edilmeli |

### File Upload Test Senaryoları

| Test Adı | Açıklama | Beklenen Sonuç |
|----------|----------|----------------|
| `Upload_WithExecutableFile_ShouldBeRejected` | `.exe` dosyası yükleme | Reddedilmeli |
| `Upload_WithOversizedFile_ShouldBeRejected` | 100MB+ dosya yükleme | Reddedilmeli |
| `Upload_WithPathTraversalFilename_ShouldBeSanitized` | `../../../etc/passwd` dosya adı | Sanitize edilmeli |

### Injection Test Senaryoları

| Test Adı | Açıklama | Beklenen Sonuç |
|----------|----------|----------------|
| `Search_WithSqlInjection_ShouldNotExecute` | SQL injection payload'ı | SQL çalışmamalı |
| `Register_WithXssPayload_ShouldBeSanitized` | XSS payload'ı | Sanitize edilmeli |

---

## 💡 Öneriler ve Düzeltmeler

### Acil Düzeltmeler (Kritik)

1. **External Login Token Doğrulaması** ✅ **TAMAMLANDI**
   - ✅ Google, Apple, Facebook API'leri ile token doğrulama
   - ✅ Token expiration kontrolü
   - ✅ Token signature kontrolü
   - **Dosyalar:** `IExternalAuthTokenVerifier.cs`, `ExternalAuthTokenVerifier.cs`
   - **Entegrasyon:** `AuthController.ExternalLogin` güncellendi

2. **File Upload Güvenliği** ✅ **TAMAMLANDI**
   - ✅ Dosya tipi whitelist kontrolü
   - ✅ Dosya boyutu limiti (5MB)
   - ✅ Magic bytes kontrolü
   - ✅ Path traversal koruması
   - ✅ Çift uzantı saldırısı koruması
   - **Dosyalar:** `IFileUploadSecurityService.cs`, `FileUploadSecurityService.cs`
   - **Entegrasyon:** `UploadController.Upload` güncellendi

3. **Secrets Management** ✅ **KISMEN TAMAMLANDI**
   - ✅ appsettings.json'dan hassas bilgileri kaldırıldı
   - ✅ Placeholder değerler eklendi
   - ⚠️ User Secrets entegrasyonu yapılmalı (Development)
   - ⚠️ Azure Key Vault entegrasyonu yapılmalı (Production)

### Önemli Düzeltmeler (Yüksek)

4. **Rate Limiting İyileştirmesi**
   ```csharp
   options.GeneralRules = new List<RateLimitRule>
   {
       new RateLimitRule { Endpoint = "/api/auth/login", Period = "1m", Limit = 5 },
       new RateLimitRule { Endpoint = "/api/auth/register", Period = "1h", Limit = 3 },
       new RateLimitRule { Endpoint = "*", Period = "1m", Limit = 60 }
   };
   ```

5. **CORS Yapılandırması**
   ```csharp
   // Production'da sadece gerekli origin'ler
   if (!builder.Environment.IsDevelopment())
   {
       policy.WithOrigins("https://talabi.com", "https://www.talabi.com");
   }
   ```

6. **Hangfire Dashboard Güvenliği**
   ```csharp
   app.UseHangfireDashboard("/hangfire", new DashboardOptions
   {
       Authorization = new[] { new HangfireAuthorizationFilter() }
   });
   ```

### İyileştirmeler (Orta)

7. **CSP Güçlendirme**
   ```csharp
   context.Response.Headers.Append("Content-Security-Policy", 
       "default-src 'self'; " +
       "script-src 'self'; " +  // unsafe-inline ve unsafe-eval kaldırıldı
       "style-src 'self' 'unsafe-inline'; " +
       "img-src 'self' data: https:;");
   ```

8. **Error Handling İyileştirmesi**
   - Production'da detaylı hata mesajları gizlenmeli
   - Loglama ayrıntılı yapılmalı
   - Stack trace'ler log'a yazılmalı, response'a değil

---

## 🔄 Sürekli Entegrasyon

### GitHub Actions Örneği

```yaml
name: Penetration Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  penetration-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '9.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore
    
    - name: Run penetration tests
      run: dotnet test --no-build --verbosity normal
      continue-on-error: true
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: '**/TestResults/**/*'
```

### Test Raporu

Test sonuçları şu formatta raporlanmalı:
- Test kategorisi
- Tespit edilen açıklar
- Öncelik seviyesi
- Önerilen düzeltmeler
- Risk skoru

---

## 📚 Referanslar

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Microsoft Security Development Lifecycle](https://www.microsoft.com/en-us/securityengineering/sdl/)
- [ASP.NET Core Security Best Practices](https://docs.microsoft.com/en-us/aspnet/core/security/)

---

## 📞 İletişim

Güvenlik açıkları için: security@talabi.com

**Son Güncelleme:** 2024
**Versiyon:** 1.8.0

---

## ✅ Tamamlanan Düzeltmeler

### Kritik Öncelik - Tamamlananlar

1. ✅ **External Login Token Doğrulaması** - `ExternalAuthTokenVerifier` servisi ile Google, Apple, Facebook token doğrulama eklendi
2. ✅ **File Upload Güvenlik Kontrolleri** - `FileUploadSecurityService` ile dosya tipi, boyutu, içerik ve path traversal kontrolleri eklendi
3. ✅ **Hassas Bilgiler Kaldırıldı** - appsettings.json'dan hassas bilgiler kaldırıldı, placeholder'lar eklendi
4. ✅ **Email Doğrulama Brute Force Koruması** - `VerificationCodeSecurityService` ile attempt tracking, lockout ve rate limiting eklendi
5. ✅ **XSS Payload Sanitization İyileştirildi** - `InputSanitizationActionFilter` güncellendi, string argument'leri ve query parametreleri otomatik sanitize ediliyor
6. ✅ **IDOR Authorization Kontrolleri Eklendi** - OrdersController ve OrderService'te eksiksiz authorization kontrolleri eklendi, kullanıcılar sadece kendi kaynaklarına erişebilir
7. ✅ **Hangfire Dashboard Authentication Eklendi** - `HangfireAuthorizationFilter` ile sadece Admin rolüne sahip kullanıcılar Hangfire Dashboard'a erişebilir
8. ✅ **CORS Production Yapılandırması Eklendi** - Environment bazlı CORS yapılandırması eklendi. Local, Test ve Production için ayrı URL'ler appsettings.json'dan okunuyor
9. ✅ **Health Check Endpoint'lerinde Hassas Bilgiler Gizlendi** - Production'da exception mesajları, stack trace'ler ve detaylı hata bilgileri gizleniyor. Sadece status bilgisi döndürülüyor
10. ✅ **OpenAPI Endpoint Production'da Kapalı** - OpenAPI endpoint'i (`/openapi/v1.json`) sadece Development ortamında aktif, Production'da kapalı

**Email Doğrulama Güvenlik Özellikleri:**
- ✅ Maximum 5 başarısız deneme sonrası 15 dakika lockout
- ✅ Endpoint bazlı rate limiting (5 deneme/dakika verify-email-code, 3 resend/saat)
- ✅ Attempt tracking ile brute force koruması
- ✅ Kalan deneme hakkı bilgisi kullanıcıya gösteriliyor
- ✅ Başarılı doğrulama sonrası tracking temizleniyor

### Bekleyen Düzeltmeler

- ⚠️ User Secrets entegrasyonu (Development)
- ⚠️ Azure Key Vault entegrasyonu (Production)
- ⚠️ Rate Limiting iyileştirmesi (diğer endpoint'ler için)
- ⚠️ CORS Production yapılandırması


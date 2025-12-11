# Talabi API Penetrasyon Testleri

Bu proje, Talabi API uygulaması için kapsamlı penetrasyon testleri içerir.

## Test Kategorileri

### 1. AuthenticationTests
- Geçersiz kimlik bilgileriyle giriş denemeleri
- Zayıf şifre kontrolleri
- JWT token manipülasyonu
- External login güvenlik açıkları
- Email doğrulama brute force saldırıları

### 2. FileUploadTests
- Yetkisiz dosya yükleme denemeleri
- Executable dosya yükleme
- Aşırı büyük dosya yükleme
- Path traversal saldırıları
- Script dosyası yükleme
- Çift uzantı saldırıları

### 3. InjectionTests
- SQL Injection saldırıları
- XSS (Cross-Site Scripting) saldırıları
- Command Injection saldırıları
- Path Traversal saldırıları
- NoSQL Injection saldırıları

### 4. IdorTests
- Insecure Direct Object Reference açıkları
- Başka kullanıcının verilerine erişim denemeleri
- Yetkisiz order güncelleme
- Yetkisiz profil erişimi

### 5. RateLimitingTests
- Brute force saldırıları
- Rate limiting bypass denemeleri
- Çoklu IP adresi testleri

### 6. InformationDisclosureTests
- Stack trace açığa çıkması
- Database hata mesajları
- Server bilgisi açığa çıkması
- Health check hassas bilgi açığa çıkması
- Dosya yolu açığa çıkması

## Tespit Edilen Güvenlik Açıkları

### Kritik
1. **External Login Token Doğrulaması Yok**: External login endpoint'inde token doğrulaması yapılmıyor. Production'da token doğrulaması eklenmelidir.

2. **File Upload Güvenlik Kontrolleri Eksik**: 
   - Dosya tipi kontrolü yok
   - Dosya boyutu kontrolü yok
   - Dosya içeriği kontrolü yok

3. **Hassas Bilgiler appsettings.json'da**: Connection string, JWT secret, API key'ler ve email credentials açık metin olarak saklanıyor.

### Yüksek
4. **CORS Development'ta Tüm Origin'lere Açık**: Development modunda tüm origin'lere izin veriliyor.

5. **Rate Limiting Yüksek**: 60 request/dakika çok yüksek, brute force saldırılarına karşı yetersiz olabilir.

6. **ConfirmEmail Endpoint'inde Token Validation Yok**: Email confirmation endpoint'inde token validation yapılmıyor.

### Orta
7. **CSP'de unsafe-inline ve unsafe-eval**: Content Security Policy'de güvenlik açıkları var.

8. **Hangfire Dashboard Erişim Kontrolü**: Hangfire dashboard'un erişim kontrolü kontrol edilmeli.

## Test Çalıştırma

```bash
dotnet test
```

Belirli bir test kategorisini çalıştırmak için:

```bash
dotnet test --filter "FullyQualifiedName~AuthenticationTests"
```

## Öneriler

1. **External Login**: Token doğrulaması ekleyin (Google, Apple, Facebook API'leri ile)
2. **File Upload**: 
   - Dosya tipi whitelist'i oluşturun
   - Dosya boyutu limiti ekleyin
   - Dosya içeriği kontrolü (magic bytes) ekleyin
3. **Secrets Management**: User Secrets veya Azure Key Vault kullanın
4. **Rate Limiting**: Daha düşük limitler ve endpoint bazlı rate limiting ekleyin
5. **CORS**: Production'da sadece gerekli origin'lere izin verin
6. **Error Handling**: Detaylı hata mesajlarını production'da gizleyin
7. **Security Headers**: CSP'yi güçlendirin, unsafe-inline ve unsafe-eval'ı kaldırın


# 🔥 Firebase Push Notification Kurulum Rehberi

Bu dokümantasyon, Talabi projesinde Firebase Cloud Messaging (FCM) push notification sisteminin nasıl yapılandırılacağını açıklar.

## 📋 Gereksinimler

- Firebase projesi (Firebase Console'dan oluşturulmuş)
- Firebase Admin SDK servis hesabı (service account) JSON dosyası
- .NET 8.0 SDK
- Firebase Cloud Messaging aktif edilmiş

## 🚀 Kurulum Adımları

### 1. Firebase Console'dan Servis Hesabı Anahtarı İndirin

1. [Firebase Console](https://console.firebase.google.com/) → Projenizi seçin
2. **⚙️ Project Settings** (Sol üstteki dişli ikonu) tıklayın
3. **Service Accounts** sekmesine gidin
4. **Generate new private key** butonuna tıklayın
5. İndirilen JSON dosyasını kaydedin (örn: `talabi-firebase-adminsdk.json`)

### 2. Credential Dosyasını Yapılandırın

Üç farklı yöntemle Firebase credentials'ı yapılandırabilirsiniz:

#### ✅ Yöntem 1: appsettings.json (ÖNERİLEN)

`appsettings.json` dosyasında zaten yapılandırılmış:

```json
{
  "Firebase": {
    "CredentialPath": "firebase-adminsdk.json"
  }
}
```

**Dosya konumları:**
- **Relative path:** `firebase-adminsdk.json` → Uygulama klasöründe aranır
- **Absolute path:** `C:\\path\\to\\firebase-adminsdk.json` → Tam yol

**Development için:**
```bash
# JSON dosyasını şu konuma koyun:
talabi/src/Talabi.Api/firebase-adminsdk.json

# veya bin klasörüne:
talabi/src/Talabi.Api/bin/Debug/net8.0/firebase-adminsdk.json
```

**Production için:**
```json
{
  "Firebase": {
    "CredentialPath": "/app/secrets/firebase-adminsdk.json"
  }
}
```

#### ✅ Yöntem 2: Environment Variable

```bash
# Windows PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\talabi-firebase-adminsdk.json"

# Windows CMD
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\talabi-firebase-adminsdk.json

# Linux/Mac
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/talabi-firebase-adminsdk.json"

# Docker
docker run -e GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-adminsdk.json ...
```

**Kalıcı olarak ayarlamak için (Windows):**
1. Sistem → Gelişmiş sistem ayarları → Ortam Değişkenleri
2. Kullanıcı değişkenleri altında "Yeni" butonuna tıklayın
3. Değişken adı: `GOOGLE_APPLICATION_CREDENTIALS`
4. Değişken değeri: `C:\path\to\talabi-firebase-adminsdk.json`

#### ✅ Yöntem 3: Default Konumlar

Uygulama otomatik olarak şu konumlara bakar:

1. `{AppDirectory}/firebase-adminsdk.json`
2. `{AppDirectory}/credentials/firebase-adminsdk.json`
3. `{CurrentDirectory}/firebase-adminsdk.json`

### 3. Öncelik Sırası

Sistem credentials'ı şu sırayla arar:

1. **Environment Variable** (`GOOGLE_APPLICATION_CREDENTIALS`)
2. **appsettings.json** (`Firebase:CredentialPath`)
3. **Default konumlar**
4. **Google Cloud Default Credentials** (sadece GCP'de çalışırsa)

## 🔒 Güvenlik - ÇOK ÖNEMLİ!

### ⚠️ ASLA YAPMAYIN:
- ❌ Firebase credential dosyasını Git'e commit etmeyin
- ❌ Credential dosyasını public repository'lere yüklemeyin
- ❌ Credential'ları kod içine hardcode etmeyin

### ✅ YAPMANIZ GEREKENLER:
- ✅ `.gitignore` dosyasında `firebase-adminsdk*.json` zaten var
- ✅ Production'da environment variable veya secret manager kullanın
- ✅ Credential dosyalarını güvenli yerlerde tutun

## 🐳 Docker Deployment

### Dockerfile Örneği:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Talabi.Api/Talabi.Api.csproj", "src/Talabi.Api/"]
RUN dotnet restore "src/Talabi.Api/Talabi.Api.csproj"
COPY . .
WORKDIR "/src/src/Talabi.Api"
RUN dotnet build "Talabi.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Talabi.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Firebase credential dosyasını kopyala (build sırasında eklenecek)
COPY firebase-adminsdk.json /app/firebase-adminsdk.json
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-adminsdk.json

ENTRYPOINT ["dotnet", "Talabi.Api.dll"]
```

### Docker Compose Örneği:

```yaml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "5000:80"
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/app/firebase-adminsdk.json
    volumes:
      - ./firebase-adminsdk.json:/app/firebase-adminsdk.json:ro
```

## ☁️ Azure App Service Deployment

### Azure Portal'dan:

1. App Service → Configuration → Application settings
2. New application setting:
   - **Name:** `GOOGLE_APPLICATION_CREDENTIALS`
   - **Value:** `/home/site/wwwroot/firebase-adminsdk.json`

3. Advanced Tools (Kudu) → Debug console:
```bash
cd /home/site/wwwroot
# FTP veya Kudu ile firebase-adminsdk.json dosyasını yükleyin
```

### Azure DevOps Pipeline'dan:

```yaml
- task: FileTransform@1
  inputs:
    folderPath: '$(System.DefaultWorkingDirectory)'
    fileType: 'json'
    targetFiles: '**/appsettings.json'
    
- task: AzureWebApp@1
  inputs:
    azureSubscription: 'Your-Azure-Subscription'
    appName: 'talabi-api'
    package: '$(System.DefaultWorkingDirectory)/**/*.zip'
```

## 🧪 Test Etme

### Uygulama Loglarını Kontrol Edin:

Başarılı initialization:
```
✅ Firebase initialized from APPSETTINGS.JSON: /app/firebase-adminsdk.json
```

Başarısız initialization:
```
❌ Firebase initialization failed: Could not load file or assembly...
💡 Please configure Firebase credentials in one of these ways:
   1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable
   2. Configure Firebase:CredentialPath in appsettings.json
   3. Place firebase-adminsdk.json in application directory
```

### API Test:

```bash
# Device token kaydet
curl -X POST https://your-api.com/api/notifications/register \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "FCM_DEVICE_TOKEN",
    "deviceType": "Android"
  }'
```

## 📱 Mobile App (Flutter) Tarafı

Mobile uygulamada da Firebase yapılandırması gereklidir:

1. `google-services.json` (Android) → `mobile/android/app/`
2. `GoogleService-Info.plist` (iOS) → `mobile/ios/Runner/`

## 🔍 Sorun Giderme

### Hata: "Could not load file or assembly 'Google.Apis.Auth'"

```bash
dotnet add package Google.Apis.Auth
```

### Hata: "The Application Default Credentials are not available"

- Credential dosyası yolunu kontrol edin
- Dosya izinlerini kontrol edin (read permission)
- Environment variable'ın doğru set edildiğini kontrol edin

### Hata: "Requested entity was not found"

- Firebase Console'da Cloud Messaging'in aktif olduğunu kontrol edin
- Servis hesabının doğru projeden olduğunu kontrol edin

### Debug Mode

Detaylı loglama için `appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Talabi.Infrastructure.Services.FirebaseNotificationService": "Debug"
    }
  }
}
```

## 📚 Ek Kaynaklar

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Google Cloud Authentication](https://cloud.google.com/docs/authentication/getting-started)

## 🆘 Destek

Sorun yaşarsanız:
1. Logları kontrol edin
2. `.gitignore` dosyasında credential'ların ignore edildiğini doğrulayın
3. Credential dosyasının geçerli JSON formatında olduğunu doğrulayın

---

**Son Güncelleme:** 2024
**Versiyon:** 1.0

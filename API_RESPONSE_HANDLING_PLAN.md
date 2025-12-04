# API Response & Error Handling Strategy

Bu doküman, Talabi projesi için standartlaştırılmış API yanıt yapısını ve hem backend hem de frontend (mobil) tarafında hata yönetim stratejisini belirler.

## 1. Hedeflenen Standart Yanıt Yapısı (Standard Response Structure)

API'den dönen tüm yanıtların (başarılı veya hatalı) belirli bir standartta olması, frontend tarafında yönetimi kolaylaştırır.

### Başarılı Yanıt (Success)
HTTP 200/201
```json
{
  "success": true,
  "data": { ... }, // İstenen veri
  "message": "İşlem başarılı" // Opsiyonel
}
```

### Hatalı Yanıt (Error)
HTTP 4xx/5xx
```json
{
  "success": false,
  "message": "Kullanıcıya gösterilecek hata mesajı",
  "errorCode": "SPECIFIC_ERROR_CODE", // Örn: "STOCK_INSUFFICIENT", "EMAIL_ALREADY_EXISTS"
  "errors": ["Validation error 1", "Validation error 2"] // Validasyon detayları varsa
}
```

---

## 2. Durum Kodları Matrisi ve Aksiyon Planı (Status Code Matrix)

Aşağıdaki tablo, her bir HTTP durum kodu için backend'in ne yapması gerektiğini ve mobil uygulamanın buna nasıl tepki vermesi gerektiğini tanımlar.

| HTTP Status | Anlamı | Backend Aksiyonu | Mobile (Flutter) Aksiyonu |
| :--- | :--- | :--- | :--- |
| **200 OK** | Başarılı | İstenen veriyi `data` içinde dön. | UI'ı güncelle, loading'i kapat. |
| **201 Created** | Oluşturuldu | Oluşan kaynağı dön. | Başarı mesajı (Toast) göster, önceki ekrana dön veya listeyi yenile. |
| **204 No Content** | İçerik Yok | Body boş dön. | UI'dan ilgili öğeyi kaldır (Silme işlemi sonrası). |
| **400 Bad Request** | Geçersiz İstek | Validasyon hatalarını `errors` listesinde dön. | Form alanlarının altında hataları göster veya Toast mesajı ile uyar. |
| **401 Unauthorized** | Yetkisiz | "Token geçersiz/yok" hatası dön. | **Interceptor:** Refresh Token dene. Başarısızsa kullanıcıyı **Login** ekranına at. |
| **403 Forbidden** | Yasaklı | "Yetkiniz yok" mesajı dön. | "Erişim Reddedildi" uyarısı göster veya kullanıcıyı yetkili olduğu sayfaya yönlendir. |
| **404 Not Found** | Bulunamadı | "Kayıt bulunamadı" mesajı dön. | Boş durum (Empty State) göster veya listeyi yenile (silinmiş bir şeye bakıyorsa). |
| **409 Conflict** | Çakışma | "Veri değişti" veya "Zaten var" mesajı dön. | **Interceptor:** İşlemi otomatik tekrarla (Retry) veya kullanıcıdan sayfayı yenilemesini iste. |
| **429 Too Many Requests** | Çok Fazla İstek | "Lütfen bekleyin" mesajı dön. | Butonu pasife al, geri sayım göster veya "Biraz yavaşlayın" uyarısı ver. |
| **500 Server Error** | Sunucu Hatası | Hatayı logla, kullanıcıya genel bir mesaj dön. | "Bir sorun oluştu, lütfen daha sonra tekrar deneyin" genel hata ekranı/modali göster. |

---

## 3. Uygulama Planı (Implementation Plan)

Bu yapıyı kurmak için aşağıdaki adımları izleyeceğiz:

### Faz 1: Backend (ASP.NET Core) Düzenlemeleri
1.  **Response Wrapper**: Tüm dönüş tiplerini kapsayacak generic bir `ApiResponse<T>` sınıfı oluşturulacak.
2.  **Global Exception Handler Middleware**:
    *   `try-catch` bloklarını controllerlardan temizlemek için merkezi bir hata yakalayıcı middleware yazılacak.
    *   `DbUpdateConcurrencyException` -> 409 Conflict
    *   `UnauthorizedAccessException` -> 401 Unauthorized
    *   `KeyNotFoundException` -> 404 Not Found
    *   Diğer tüm hatalar -> 500 Internal Server Error (Loglanarak)
3.  **FluentValidation Entegrasyonu**: Validasyon hatalarının otomatik olarak 400 Bad Request ve standart formatta dönmesi sağlanacak.

### Faz 2: Mobile (Flutter) Entegrasyonu - Detaylı İş Planı

Backend yapısı değiştiğinde (örn: `{ data: ..., success: true }` formatına geçildiğinde), mobil uygulamanın kırılmaması için **Response Model** ve **Network Katmanı**'nın güncellenmesi şarttır. Ayrıca her bir HTTP durum kodu için UI tarafında bir karşılık (State) oluşturulmalıdır.

#### 1. Dart Response Modelinin Oluşturulması
Backend'den gelecek standart yapıya uygun bir `BaseResponse` modeli oluşturulmalı.

```dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errorCode: json['errorCode'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
}
```

#### 2. Network Katmanı (Dio) Güncellemesi
Mevcut API servisleri, direkt model dönmek yerine bu `ApiResponse` yapısını parse edecek şekilde güncellenmeli.

*   **Eski:** `return User.fromJson(response.data);`
*   **Yeni:**
    ```dart
    final apiResponse = ApiResponse.fromJson(response.data, (json) => User.fromJson(json));
    if (!apiResponse.success) {
      throw ApiException(message: apiResponse.message, code: apiResponse.errorCode);
    }
    return apiResponse.data!;
    ```

#### 3. Global Hata Yönetimi (Interceptor)
`Dio` Interceptor'ı içinde her durum kodu için merkezi bir aksiyon belirlenmeli. Bu, her sayfada tekrar tekrar `try-catch` yazmayı engeller.

```dart
class AppInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.response?.statusCode) {
      case 400:
        // Validasyon hatası: UI'a mesajı ilet
        // Örn: "Şifre en az 6 karakter olmalı"
        break;
      case 401:
        // Token süresi dolmuş:
        // 1. Refresh Token dene
        // 2. Başarısızsa -> Login ekranına yönlendir (NavigationService ile)
        break;
      case 403:
        // Yetkisiz işlem: Kullanıcıya uyarı göster
        break;
      case 404:
        // Bulunamadı: Özel bir exception fırlat
        break;
      case 409:
        // Çakışma (Concurrency):
        // Otomatik retry mekanizmasını tetikle
        break;
      case 500:
      default:
        // Sunucu hatası: Genel hata ekranı/dialog göster
        // "Bir sorun oluştu, lütfen daha sonra tekrar deneyin."
        break;
    }
    super.onError(err, handler);
  }
}
```

#### 4. UI State Management (ViewModel/Cubit)
Her ekranın (veya widget'ın) 4 temel durumu (State) olmalı. Bu durumlar backend yanıtlarına göre şekillenir.

*   **Initial**: Sayfa ilk açıldığında.
*   **Loading**: İstek atıldığında (Spinner gösterilir).
*   **Success**: `200 OK` geldiğinde (Data gösterilir).
*   **Error**: `4xx/5xx` geldiğinde (Hata mesajı/ikonu gösterilir).

**Örnek Kullanım:**
```dart
// ViewModel içinde
try {
  emit(State.loading());
  final data = await repository.getData();
  emit(State.success(data));
} catch (e) {
  // Interceptor'dan gelen işlenmiş hata mesajını göster
  emit(State.error(e.message));
}
```

#### 5. Mobil İçin Aksiyon Listesi
1.  [ ] **BaseResponse Class**: `lib/core/models/api_response.dart` oluştur.
2.  [ ] **Interceptor Güncellemesi**: `lib/core/network/dio_client.dart` içindeki interceptor'ı yukarıdaki switch-case yapısına göre düzenle.
3.  [ ] **Service Refactoring**: Tüm `ApiService` metodlarını `ApiResponse` wrapper'ını handle edecek şekilde güncelle.
4.  [ ] **Navigation Service**: Context olmadan yönlendirme yapabilmek için `GlobalKey<NavigatorState>` kullanan bir servis kur (401 -> Login yönlendirmesi için).
5.  **UI Feedback**:
    *   400 Hataları için `InputDecorator` veya `SnackBar`.
    *   500 Hataları için `ErrorDialog`.
    *   401 Hataları için sessizce Login'e atma.


# 🔜 KAPSAMLI KALAN GÖREVLER (TODO)

## 📅 Son Güncelleme: 21 Aralık 2024, 04:26

> Tüm artifact'lerden (task.md, implementation_plan.md, test_expansion_plan.md) toplanan kalan görevlerin tam listesi

---

## ✅ Bugün Tamamlananlar (21 Aralık 2024)

### Performans ve Analiz

- [x] **Performans Testi Kurulumu** - `test/integration/performance_test.dart` ve driver hazır
- [x] **Açılış Performansı Analizi** - Bootstrap, SplashScreen incelendi, mimari uygun bulundu
- [x] **Test Durumu Analizi** - 42 widget test başarılı, 1 E2E test kırık olarak tespit edildi

### Planlama

- [x] **E2E Auth Tests Plan** - 3 kullanıcı türü için plan oluşturuldu ve onaylandı
- [x] **Test Expansion Plan** - Güncel durumla senkronize edildi

---

## 🔴 YÜ KSEK ÖNCELİK - Hemen Yapılması Gerekenler

### 1. E2E Kullanıcı Authentication Testleri (3 Rol)

**Durum:** Plan hazır, implementasyon gerekli

**Yaklaşım:** UI-based değil, direkt AuthProvider metod çağrıları ile integration test

#### 1.1 Customer Authentication Test

**Dosya:** `test/integration/auth_customer_integration_test.dart`

- [ ] Customer register flow testi
  - Mock API yanıtı hazırla
  - `authProvider.register()` çağır
  - Token, email, role doğrula
- [ ] Customer login flow testi
  - Mock API yanıtı hazırla
  - `authProvider.login()` çağır
  - Authentication state doğrula
- [ ] Logout testi
  - `authProvider.logout()` çağır
  - State temizlendiğini doğrula
- [ ] Test dosyası oluştur ve çalıştır

**Tahmini Süre:** 45-60 dakika

#### 1.2 Vendor Authentication Test

**Dosya:** `test/integration/auth_vendor_integration_test.dart`

- [ ] Vendor register flow testi
  - Mock vendor-specific response
  - `authProvider.register()` çağır
  - Role='Vendor' doğrula
- [ ] Vendor login flow testi
  - Profile completion check
  - Delivery zones check
  - Role doğrulama
- [ ] Logout testi
- [ ] Test dosyası oluştur ve çalıştır

**Tahmini Süre:** 45-60 dakika

#### 1.3 Courier Authentication Test  

**Dosya:** `test/integration/auth_courier_integration_test.dart`

- [ ] Courier register flow testi
  - Mock courier response
  - Role='Courier' doğrula
- [ ] Courier login flow testi
  - CourierDashboard navigation test
- [ ] Logout testi
- [ ] Test dosyası oluştur ve çalıştır

**Tahmini Süre:** 45-60 dakika

**Toplam Tahmini:** 2-3 saat

**Referans Dosyalar:**

- Plan: `/Users/osmanaliaydemir/.gemini/antigravity/brain/.../e2e_auth_tests_plan.md`
- Başlanmış (silinmeli): `/Users/osmanaliaydemir/Documents/talabi/mobile/test/integration/auth_customer_e2e_test.dart`

---

### 2. Order Flow E2E Test Düzeltme

**Durum:** ⚠️ Test yazılmış ancak KIRIK

**Sorun:**

```
OrderSuccessScreen widget'ı bulunamıyor
Muhtemel neden: Navigation timing veya route yapısı değişikliği
```

**Yapılacaklar:**

- [ ] Test'i çalıştır ve hata loglarını incele
- [ ] `OrderSuccessScreen` navigation kodunu kontrol et
  - Route adını doğrula
  - Navigation metodunu kontrol et (push/pushReplacement)
- [ ] Test'te daha fazla `pumpAndSettle` ekle
- [ ] Order creation sonrası bekleme süresi ekle
- [ ] Widget tree dump'ı al ve analiz et
- [ ] Düzeltilmiş testi tekrar çalıştır

**Tahmini Süre:** 30-45 dakika

**Dosya:** `/Users/osmanaliaydemir/Documents/talabi/mobile/test/integration/order_flow_test.dart`

---

## 🟡 ORTA ÖNCELİK - İyileştirmeler

### 3. Memory Leak Kontrolü

**Kapsam:** Provider ve Controller dispose metodları

**Kontrol Edilecek Dosyalar:**

- [ ] `/Users/osmanaliaydemir/Documents/talabi/mobile/lib/features/auth/presentation/providers/auth_provider.dart`
  - [ ] Stream controller'ların dispose edilmesi
  - [ ] Listener'ların temizlenmesi
  
- [ ] `/Users/osmanaliaydemir/Documents/talabi/mobile/lib/features/cart/presentation/providers/cart_provider.dart`
  - [ ] Timer'ların iptal edilmesi
  - [ ] Async işlemlerin cleanup'ı

- [ ] Tüm screen'lerdeki AnimationController'lar
  - [ ] `dispose()` çağrılarını doğrula
  - [ ] `super.dispose()` çağrılarını kontrol et

**Yaklaşım:**

1. Her dosyayı aç
2. Dispose metodunu kontrol et
3. Stream, Timer, AnimationController varlığını ara
4. Dispose edilmediğini gör, düzelt
5. Lint warning'leri kontrol et

**Tahmini Süre:** 30-45 dakika

---

### 4. Test Dosyası Temizliği

**Yapılacaklar:**

- [ ] `test/integration/auth_customer_e2e_test.dart` dosyasını sil
  - Yarım kaldı ve çalışmıyor
  - Yeni integration testler yazılacak
- [ ] Kullanılmayan mock dosyalarını kontrol et
- [ ] Test klasörlerini düzenle

**Tahmini Süre:** 10 dakika

---

## 🔵 DÜŞÜK ÖNCELİK - Dokümantasyon

### 5. DevTools Kullanım Rehberi

**Durum:** Henüz yazılmadı

**İçerik:**

- [ ] Memory Profiler kullanımı
  - Heap snapshot alma
  - Memory leak tespit etme
  - Object allocation izleme
  
- [ ] Performance Tab kullanımı
  - Timeline kaydetme
  - Frame rendering analizi
  - CPU profiling

- [ ] Network Inspector kullanımı
  - API çağrılarını izleme
  - Response time analizi
  - Network hataları debug

- [ ] Widget Inspector kullanımı
  - Widget tree navigation
  - Layout sorunlarını debug etme
  - Rebuild performans analizi

**Oluşturulacak Dosya:**
`/Users/osmanaliaydemir/.gemini/antigravity/brain/.../devtools_guide.md`

**Tahmini Süre:** 1-1.5 saat

**Format:** Ekran görüntüleri ile step-by-step rehber

---

## 📊 ÖZET İSTATİSTİKLER

### Mevcut Test Durumu

- ✅ **42 Widget Test** - Tümü başarılı
- ✅ **2 Unit Test** (CartProvider, AuthProvider) - Başarılı
- ✅ **1 Performance Test** - Kuruldu, çalışıyor
- ⚠️ **1 E2E Test (Order Flow)** - Kırık, düzeltilmeli
- ❌ **3 E2E Auth Test** - Henüz yazılmadı

### Tahmini Toplam Süre Gereksinimi

| Öncelik | Görev | Süre |
|---------|-------|------|
| 🔴 Yüksek | E2E Auth Tests (3 rol) | 2-3 saat |
| 🔴 Yüksek | Order Flow düzeltme | 30-45 dk |
| 🟡 Orta | Memory Leak kontrolü | 30-45 dk |
| 🟡 Orta | Test cleanup | 10 dk |
| 🔵 Düşük | DevTools rehberi | 1-1.5 saat |
| **TOPLAM** | | **4.5-6 saat** |

---

## 🎯 ÖNERİLEN ÇALIŞMA SIRASI

### Senaryo 1: Testlere Odaklan (3-4 saat)

1. ✨ E2E Customer Auth Test (1 saat)
2. ✨ E2E Vendor Auth Test (1 saat)
3. ✨ E2E Courier Auth Test (1 saat)
4. 🔧 Order Flow düzeltme (45 dk)
5. 🧹 Cleanup (10 dk)

### Senaryo 2: Test + Performans (4-5 saat)

1. ✨ Tüm E2E Auth Tests (3 saat)
2. 🔧 Order Flow düzeltme (45 dk)
3. 💾 Memory Leak kontrolü (45 dk)
4. 🧹 Cleanup (10 dk)

### Senaryo 3: Full Package (6+ saat)

1. Senaryo 2'nin tümü (5 saat)
2. 📚 DevTools Rehberi (1.5 saat)

---

## 📁 ÖNEMLİ DOSYA REFERANSLARI

### Artifact'ler

- **Ana Task:** `/Users/osmanaliaydemir/.gemini/antigravity/brain/.../task.md`
- **Implementation Plan:** `.../implementation_plan.md`
- **Test Expansion:** `.../test_expansion_plan.md`
- **E2E Auth Plan:** `.../e2e_auth_tests_plan.md`
- **Walkthrough:** `.../walkthrough.md`

### Test Dosyaları

- **Performance:** `/Users/osmanaliaydemir/Documents/talabi/mobile/test/integration/performance_test.dart`
- **Order Flow (KIRIK):** `.../test/integration/order_flow_test.dart`
- **Auth Customer (SİLİNMELİ):** `.../test/integration/auth_customer_e2e_test.dart`

### Provider'lar (Memory Leak Kontrolü için)

- **AuthProvider:** `.../lib/features/auth/presentation/providers/auth_provider.dart`
- **CartProvider:** `.../lib/features/cart/presentation/providers/cart_provider.dart`

---

## 🚀 BİR SONRAKİ ADIM

**Hemen başlamak için:**

```bash
cd /Users/osmanaliaydemir/Documents/talabi/mobile

# 1. Yarım kalan dosyayı sil
rm test/integration/auth_customer_e2e_test.dart

# 2. İlk testi oluştur
# Dosya: test/integration/auth_customer_integration_test.dart
# (Basit, direkt AuthProvider metodlarını çağıran format)

# 3. Testi çalıştır
flutter test test/integration/auth_customer_integration_test.dart
```

**Sonraki oturum için hazırlık:**

- [ ] Bu TODO dosyasını oku
- [ ] E2E Auth Plan'ı (`e2e_auth_tests_plan.md`) gözden geçir
- [ ] Order Flow test'i çalıştır ve hata loglarını yakala
- [ ] Hangi senaryoyla (1, 2, veya 3) devam edeceğine karar ver

---

## 💡 NOTLAR

- E2E testleri için UI yerine direkt provider metod çağrısı kullan (daha hızlı, kararlı)
- Order flow testi debug için widget tree dump almayı unutma
- Memory leak kontrolünde DevTools Memory tab'ı kullanabilirsin (manuel)
- Test cleanup sonrası `flutter test` ile tüm testleri çalıştır

İyi Çalışmalar! 🎯

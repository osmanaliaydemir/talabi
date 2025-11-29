# 🎨 Talabi - Font Kullanımı

## Google Fonts Entegrasyonu

Uygulamamızda **Google Fonts** kullanıyoruz. Ana fontumuz: **Poppins**

### ✅ Kurulum Tamamlandı

```yaml
dependencies:
  google_fonts: ^6.2.1
```

---

## 📝 Kullanım Örnekleri

### 1️⃣ **Otomatik Theme ile (ÖNERİLEN)**

Tüm uygulama genelinde otomatik olarak Poppins fontu kullanılır:

```dart
Text(
  'Hoş Geldiniz!',
  // Font otomatik olarak Poppins
)
```

### 2️⃣ **Manuel Stil ile**

```dart
import 'package:google_fonts/google_fonts.dart';

Text(
  'Hoş Geldiniz!',
  style: GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.orange,
  ),
)
```

### 3️⃣ **Farklı Fontlar**

```dart
// Poppins (Ana Font)
GoogleFonts.poppins(fontSize: 16)

// Inter (Alternatif)
GoogleFonts.inter(fontSize: 16)

// Montserrat (Alternatif)
GoogleFonts.montserrat(fontSize: 16)

// Roboto (Material Design)
GoogleFonts.roboto(fontSize: 16)

// Nunito (Friendly)
GoogleFonts.nunito(fontSize: 16)
```

---

## 🎨 Font Ağırlıkları (Font Weights)

```dart
GoogleFonts.poppins(
  fontWeight: FontWeight.w100,  // Thin
  fontWeight: FontWeight.w200,  // ExtraLight
  fontWeight: FontWeight.w300,  // Light
  fontWeight: FontWeight.w400,  // Regular (normal)
  fontWeight: FontWeight.w500,  // Medium
  fontWeight: FontWeight.w600,  // SemiBold
  fontWeight: FontWeight.w700,  // Bold (bold)
  fontWeight: FontWeight.w800,  // ExtraBold
  fontWeight: FontWeight.w900,  // Black
)
```

---

## 📐 Standart Font Boyutları

```dart
// Başlıklar
displayLarge:   32px (Bold)       // Büyük sayfa başlıkları
displayMedium:  28px (Bold)       // Orta sayfa başlıkları
displaySmall:   24px (SemiBold)   // Küçük sayfa başlıkları

// Alt Başlıklar
headlineLarge:  22px (SemiBold)   // Bölüm başlıkları
headlineMedium: 20px (SemiBold)   // Alt bölüm başlıkları
headlineSmall:  18px (SemiBold)   // Küçük başlıklar

// Gövde Metinleri
bodyLarge:      16px (Regular)    // Ana metin
bodyMedium:     14px (Regular)    // Orta metin
bodySmall:      12px (Regular)    // Küçük metin

// Button/Label
labelLarge:     16px (SemiBold)   // Büyük butonlar
labelMedium:    14px (Medium)     // Orta butonlar
labelSmall:     12px (Medium)     // Küçük butonlar
```

---

## 🎯 Kullanım Örnekleri

### Sayfa Başlığı
```dart
Text(
  'Hoş Geldiniz!',
  style: Theme.of(context).textTheme.displayMedium,
  // veya
  style: GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  ),
)
```

### Açıklama Metni
```dart
Text(
  'Sipariş vermek için giriş yapın',
  style: Theme.of(context).textTheme.bodyMedium,
  // veya
  style: GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.grey[600],
  ),
)
```

### Buton Metni
```dart
ElevatedButton(
  onPressed: () {},
  child: Text(
    'Giriş Yap',
    style: Theme.of(context).textTheme.labelLarge,
    // veya
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

---

## 🌐 Çoklu Dil Desteği

Google Fonts **Türkçe**, **İngilizce**, **Arapça** karakterleri destekler:

```dart
// Türkçe
Text('Şifremi Unuttum', style: GoogleFonts.poppins())

// English
Text('Forgot Password', style: GoogleFonts.poppins())

// العربية (RTL otomatik)
Text('نسيت كلمة المرور', style: GoogleFonts.poppins())
```

---

## ⚡ Performans

### İlk İndirme
- Font ilk kullanımda **otomatik indirilir**
- Sonraki kullanımlarda **cache**'den yüklenir

### Cache Temizleme (Gerekirse)
```bash
flutter pub cache repair
```

---

## 🔧 Font Değiştirme

Farklı bir font kullanmak isterseniz:

### Option 1: Tüm Uygulamayı Değiştir
```dart
// lib/providers/theme_provider.dart
textTheme: GoogleFonts.interTextTheme(),  // Poppins yerine Inter
```

### Option 2: Sadece Belirli Ekranlarda
```dart
Text(
  'Special Text',
  style: GoogleFonts.montserrat(fontSize: 16),
)
```

---

## 📚 Daha Fazla Font

1000+ Google Font: https://fonts.google.com/

Popüler seçenekler:
- **Poppins** ✅ (Kullanılıyor)
- **Roboto** - Material Design
- **Inter** - Modern
- **Montserrat** - Şık
- **Nunito** - Friendly
- **Lato** - Professional
- **Open Sans** - Clean
- **Raleway** - Elegant

---

## 🚀 Avantajlar

✅ **1000+ font** seçeneği  
✅ **Kolay kullanım** (tek satır)  
✅ **Otomatik indirme**  
✅ **Cache sistemi**  
✅ **Tüm diller** desteklenir  
✅ **Font dosyası yönetimi yok**  
✅ **Ücretsiz**  

---

## 📝 Notlar

- Fontlar **ilk açılışta** internet ile indirilir
- Sonraki kullanımlar **offline** çalışır
- **APK boyutunu** artırmaz (dinamik yükleme)
- Theme'den otomatik uygulanır

---

**Geliştirici:** Talabi Team  
**Font:** Poppins (Google Fonts)  
**Tarih:** 2024

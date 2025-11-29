# 🎨 Talabi - Theme & Style Guide

## 📚 İçindekiler
1. [Renk Kullanımı](#renk-kullanımı)
2. [Typography (Fontlar)](#typography)
3. [Spacing & Boyutlar](#spacing-boyutlar)
4. [Widget Örnekleri](#widget-örnekleri)
5. [Best Practices](#best-practices)

---

## 🎨 Renk Kullanımı

### ❌ YANLIŞ (Kullanma!)
```dart
// Her sayfada farklı renk tanımları
Container(
  color: Colors.orange.shade400,  // ❌
)

Text(
  'Başlık',
  style: TextStyle(color: Colors.grey[600]),  // ❌
)
```

### ✅ DOĞRU (Kullan!)
```dart
import 'package:mobile/config/app_theme.dart';

// Statik renk sabitleri
Container(
  color: AppTheme.primaryOrange,  // ✅
)

// Theme'den renk
Container(
  color: Theme.of(context).colorScheme.primary,  // ✅
)

Text(
  'Başlık',
  style: TextStyle(color: AppTheme.textSecondary),  // ✅
)
```

---

## 🎨 Renk Kategorileri

### 1️⃣ **Ana Renkler**
```dart
AppTheme.primaryOrange     // #FF9800 - Ana turuncu
AppTheme.darkOrange        // #F57C00 - Koyu turuncu
AppTheme.lightOrange       // #FFB74D - Açık turuncu
AppTheme.deepOrange        // #F4511E - Derin turuncu
```

**Kullanım:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryOrange,
  ),
  child: Text('Giriş Yap'),
)
```

### 2️⃣ **Durum Renkleri**
```dart
AppTheme.success       // #4CAF50 - Yeşil (Başarı)
AppTheme.error         // #F44336 - Kırmızı (Hata)
AppTheme.warning       // #FFC107 - Sarı (Uyarı)
AppTheme.info          // #2196F3 - Mavi (Bilgi)
```

**Kullanım:**
```dart
// Başarı mesajı
SnackBar(
  backgroundColor: AppTheme.success,
  content: Text('İşlem başarılı!'),
)

// Hata mesajı
Container(
  decoration: BoxDecoration(
    color: AppTheme.errorLight,
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
  ),
  child: Text('Bir hata oluştu'),
)
```

### 3️⃣ **Sipariş Durumu Renkleri**
```dart
AppTheme.statusPending      // Sarı - Beklemede
AppTheme.statusProcessing   // Mavi - İşleniyor
AppTheme.statusShipping     // Mor - Kargoda
AppTheme.statusDelivered    // Yeşil - Teslim Edildi
AppTheme.statusCancelled    // Kırmızı - İptal Edildi
```

**Kullanım:**
```dart
// Sipariş durumu badge
Container(
  padding: EdgeInsets.symmetric(
    horizontal: AppTheme.spacingSmall,
    vertical: AppTheme.spacingXSmall,
  ),
  decoration: BoxDecoration(
    color: AppTheme.getStatusColor(order.status),
    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
  ),
  child: Text(
    order.status,
    style: AppTheme.poppins(
      fontSize: 12,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### 4️⃣ **Metin Renkleri**
```dart
AppTheme.textPrimary       // #212121 - Ana metin
AppTheme.textSecondary     // #757575 - İkincil metin
AppTheme.textHint          // #BDBDBD - Placeholder
AppTheme.textDisabled      // #9E9E9E - Disabled
AppTheme.textOnPrimary     // Beyaz - Turuncu üzerinde
```

**Kullanım:**
```dart
// Başlık
Text(
  'Hoş Geldiniz',
  style: AppTheme.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  ),
)

// Açıklama
Text(
  'Sipariş vermek için giriş yapın',
  style: AppTheme.poppins(
    fontSize: 14,
    color: AppTheme.textSecondary,
  ),
)
```

### 5️⃣ **Arka Plan Renkleri**
```dart
AppTheme.backgroundColor   // #F5F5F5 - Ana arka plan
AppTheme.cardColor         // Beyaz - Kartlar
AppTheme.surfaceColor      // Beyaz - Yüzeyler
AppTheme.dividerColor      // #E0E0E0 - Ayırıcı çizgiler
```

---

## 📝 Typography (Fontlar)

### Varsayılan (Theme'den)
```dart
// Büyük başlık
Text(
  'Hoş Geldiniz!',
  style: Theme.of(context).textTheme.displayMedium,
)

// Normal metin
Text(
  'Açıklama metni',
  style: Theme.of(context).textTheme.bodyMedium,
)
```

### Özel Font Stilleri
```dart
// Poppins (Ana font)
Text(
  'Özel Başlık',
  style: AppTheme.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryOrange,
  ),
)

// Inter (Alternatif)
Text(
  'Alternatif Font',
  style: AppTheme.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  ),
)

// Montserrat (Alternatif)
Text(
  'Şık Başlık',
  style: AppTheme.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
)
```

---

## 📏 Spacing & Boyutlar

### Spacing (Boşluklar)
```dart
AppTheme.spacingXSmall    // 4px
AppTheme.spacingSmall     // 8px
AppTheme.spacingMedium    // 16px
AppTheme.spacingLarge     // 24px
AppTheme.spacingXLarge    // 32px
```

**Kullanım:**
```dart
// Yatay boşluk
Padding(
  padding: EdgeInsets.all(AppTheme.spacingMedium),
  child: Text('İçerik'),
)

// Elemanlar arası boşluk
Column(
  children: [
    Text('Başlık'),
    SizedBox(height: AppTheme.spacingMedium),
    Text('Açıklama'),
    AppTheme.verticalSpace(1.5),  // 24px (16 * 1.5)
    Text('Detay'),
  ],
)
```

### Border Radius (Köşe Yuvarlaklıkları)
```dart
AppTheme.radiusSmall      // 8px
AppTheme.radiusMedium     // 12px
AppTheme.radiusLarge      // 16px
AppTheme.radiusXLarge     // 24px
```

**Kullanım:**
```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.cardColor,
    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
  ),
  child: Text('Kart'),
)
```

### Icon Boyutları
```dart
AppTheme.iconSizeSmall     // 16px
AppTheme.iconSizeMedium    // 24px
AppTheme.iconSizeLarge     // 32px
AppTheme.iconSizeXLarge    // 48px
```

**Kullanım:**
```dart
Icon(
  Icons.shopping_cart,
  size: AppTheme.iconSizeMedium,
  color: AppTheme.primaryOrange,
)
```

### Button Yükseklikleri
```dart
AppTheme.buttonHeightSmall    // 40px
AppTheme.buttonHeightMedium   // 48px
AppTheme.buttonHeightLarge    // 56px
```

### Elevation (Gölge Seviyeleri)
```dart
AppTheme.elevationNone      // 0
AppTheme.elevationLow       // 2
AppTheme.elevationMedium    // 4
AppTheme.elevationHigh      // 8
```

---

## 🔧 Widget Örnekleri

### 1️⃣ **Kart (Card)**
```dart
// Yöntem 1: BoxDecoration kullan
Container(
  decoration: AppTheme.cardDecoration(),
  padding: EdgeInsets.all(AppTheme.spacingMedium),
  child: Text('Kart İçeriği'),
)

// Yöntem 2: Gölge olmadan
Container(
  decoration: AppTheme.cardDecoration(withShadow: false),
  child: Text('Gölgesiz Kart'),
)

// Yöntem 3: Özel renk
Container(
  decoration: AppTheme.cardDecoration(
    color: AppTheme.lightOrange,
    radius: AppTheme.radiusLarge,
  ),
  child: Text('Turuncu Kart'),
)
```

### 2️⃣ **Input Field (Text Field)**
```dart
TextField(
  decoration: AppTheme.inputDecoration(
    hint: 'E-posta adresiniz',
    label: 'E-posta',
    prefixIcon: Icon(Icons.email),
  ),
)

// Veya manuel
TextField(
  decoration: InputDecoration(
    hintText: 'Şifre',
    prefixIcon: Icon(Icons.lock),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide.none,
    ),
  ),
)
```

### 3️⃣ **Buton (Button)**
```dart
// Primary Button
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryOrange,
    minimumSize: Size(double.infinity, AppTheme.buttonHeightMedium),
  ),
  child: Text('Giriş Yap'),
)

// Secondary Button
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryOrange,
    side: BorderSide(color: AppTheme.primaryOrange, width: 2),
    minimumSize: Size(double.infinity, AppTheme.buttonHeightMedium),
  ),
  child: Text('İptal'),
)
```

### 4️⃣ **Divider (Ayırıcı)**
```dart
// Basit
AppTheme.divider()

// Özel
AppTheme.divider(
  thickness: 2,
  color: AppTheme.primaryOrange,
)
```

### 5️⃣ **Spacing (Boşluk)**
```dart
Column(
  children: [
    Text('Başlık'),
    AppTheme.verticalSpace(1),     // 16px
    Text('Açıklama'),
    AppTheme.verticalSpace(2),     // 32px
    ElevatedButton(...),
  ],
)

Row(
  children: [
    Icon(Icons.star),
    AppTheme.horizontalSpace(0.5), // 8px
    Text('4.5'),
  ],
)
```

---

## 🏆 Best Practices (En İyi Uygulamalar)

### ✅ DO (YAP)
1. **Her zaman AppTheme kullan**
   ```dart
   color: AppTheme.primaryOrange  ✅
   ```

2. **Theme.of(context) kullan**
   ```dart
   style: Theme.of(context).textTheme.headlineMedium  ✅
   ```

3. **Sabit boyutlar kullan**
   ```dart
   padding: EdgeInsets.all(AppTheme.spacingMedium)  ✅
   ```

4. **Anlamlı isimler kullan**
   ```dart
   AppTheme.statusDelivered  ✅ (Net ve anlaşılır)
   ```

### ❌ DON'T (YAPMA)
1. **Hardcoded renkler kullanma**
   ```dart
   color: Color(0xFFFF9800)  ❌
   color: Colors.orange      ❌
   ```

2. **Hardcoded boyutlar kullanma**
   ```dart
   padding: EdgeInsets.all(16)  ❌
   fontSize: 14                 ❌
   ```

3. **Farklı renk tonları kullanma**
   ```dart
   Colors.orange.shade400  ❌
   Colors.orange.shade600  ❌
   ```

---

## 🎯 Örnek: Tam Ekran

```dart
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Örnek Ekran'),
        // backgroundColor ve textStyle otomatik (theme'den)
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Hoş Geldiniz!',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            
            AppTheme.verticalSpace(0.5),
            
            // Açıklama
            Text(
              'Sipariş vermek için giriş yapın',
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            
            AppTheme.verticalSpace(2),
            
            // Kart
            Container(
              decoration: AppTheme.cardDecoration(),
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                children: [
                  TextField(
                    decoration: AppTheme.inputDecoration(
                      hint: 'E-posta',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  
                  AppTheme.verticalSpace(1),
                  
                  TextField(
                    decoration: AppTheme.inputDecoration(
                      hint: 'Şifre',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            
            AppTheme.verticalSpace(2),
            
            // Buton
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(
                  double.infinity,
                  AppTheme.buttonHeightMedium,
                ),
              ),
              child: Text('Giriş Yap'),
            ),
            
            AppTheme.verticalSpace(1),
            
            // İkincil Buton
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: Size(
                  double.infinity,
                  AppTheme.buttonHeightMedium,
                ),
              ),
              child: Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔄 Değişiklik Yaparken

1. **Renk değiştirmek:**
   ```dart
   // app_theme.dart içinde
   static const Color primaryOrange = Color(0xFFFF9800);
   // Tüm uygulama otomatik güncellenir! 🎉
   ```

2. **Spacing değiştirmek:**
   ```dart
   // app_theme.dart içinde
   static const double spacingMedium = 20.0;  // 16'dan 20'ye
   // Tüm padding/margin'ler güncellenir! 🎉
   ```

3. **Font değiştirmek:**
   ```dart
   // theme_provider.dart içinde
   textTheme: GoogleFonts.interTextTheme()  // Poppins yerine Inter
   // Tüm metinler güncellenir! 🎉
   ```

---

## 📱 Dark Mode Desteği

Theme sistemi dark mode için hazır:
```dart
// theme_provider.dart içinde zaten var
ThemeData get darkTheme { ... }

// Kullanımda değişiklik yok, otomatik çalışır!
```

---

**Geliştirici:** Talabi Team  
**Son Güncelleme:** 2024  
**Versiyon:** 1.0

# App Store Reddi Çözüm Kılavuzu

Bu belge, Apple'ın 2.3.3, 2.5.4 ve 5.1.1 numaralı ret nedenlerini çözmek için yapılan teknik değişiklikleri ve sizin App Store Connect üzerinde yapmanız gereken işlemleri içerir.

## Yapılan Değişiklikler (Otomatik)

### Info.plist Güncellemesi (5.1.1 & 2.5.4)
`Info.plist` dosyasındaki izin metinleri, Apple'ın istediği detay seviyesine ve kullanım amacına göre güncellendi.
- **Konum İzni:** Artık sadece Kuryeler (Couriers) için arka planda konuma ihtiyaç duyulduğu açıkça belirtiliyor. Müşteriler için bu özelliğin kullanılmadığı vurgulandı.
- **Kamera ve Galeri:** Teslimat kanıtı ve profil resmi yükleme amaçları netleştirildi.

## Sizin Yapmanız Gerekenler (App Store Connect)

Teknik düzenlemeler yapıldı ancak onayın kesinleşmesi için aşağıdaki adımları **App Store Connect** panelinde uygulamanız gerekmektedir.

### 1. Ekran Görüntüleri ve Metadata (2.3.3 Performance)
- **Ekran Görüntüleri:** Uygulamanızın sadece giriş ekranını değil, *içerideki* ana fonksiyonlarını (Listeler, Harita, Profil vb.) gösteren ekran görüntülerini yükleyin.
- **Boyutlar:**
    - **iPhone 6.7" Display:** iPhone 15 Pro Max / 14 Pro Max boyutlarında olmalı.
    - **iPhone 5.5" Display:** iPhone 8 Plus boyutlarında olmalı.

### 2. Demo Hesap Bilgisi (2.1 Performance)
Apple inceleme ekibi, Kurye modunu ve arka plan konum takibini test edemezse reddeder.
- **Review Notes** kısmına çalışan bir **Kurye (Courier)** kullanıcı adı ve şifresi ekleyin.
- Mümkünse bir de **Müşteri (Customer)** demo hesabı ekleyin.

### 3. İnceleme Notları (App Review Notes)
Aşağıdaki metni (veya benzerini) "Notes" kısmına yapıştırın. Bu, inceleyen kişiye durumu açıklar:

> "This app contains two modes: Customer and Courier.
>
> 1. **Background Location & Audio:** The 'Background Location' mode is ONLY active when a user logs in as a 'Courier' and goes 'Online' to accept orders. It is critical for customers to track their food delivery in real-time. Regular 'Customer' users imply standard 'While In Use' location to find restaurants.
> 2. **Demo Account:** Please use the provided 'Courier' demo credentials to verify the background location feature.
>
> We have updated the Info.plist Usage Descriptions to explicitly state these purposes."

### 4. Yazılım Gereksinimleri (2.5.4 Performance)
`Info.plist` içinde `UIBackgroundModes` anahtarı altında `location` ve `remote-notification` tanımlı. Apple artık bu modların neden gerektiğini yukarıdaki açıklama ve Info.plist metinleri sayesinde anlayacaktır. Sizin ekstra bir şey yapmanıza gerek yok, sadece notu eklemeyi unutmayın.

## Sonraki Adım
Uygulamanızı tekrar arşivleyin (Archive) ve App Store Connect'e gönderin.

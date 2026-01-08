// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get myWallet => 'Cüzdanım';

  @override
  String get viewBalanceAndHistory => 'Bakiye ve işlem geçmişimi görüntüle';

  @override
  String get currentBalance => 'Mevcut Bakiye';

  @override
  String get topUpBalance => 'Bakiye Yükle';

  @override
  String get transactionHistory => 'İşlem Geçmişi';

  @override
  String get noTransactionsYet => 'Henüz işlem bulunmuyor.';

  @override
  String get topUp => 'Bakiye Yükle';

  @override
  String get amountToTopUp => 'Yüklenecek Tutar';

  @override
  String get makePayment => 'Ödeme Yap';

  @override
  String get topUpSuccessful => 'Yükleme başarılı!';

  @override
  String get withdraw => 'Para Çek';

  @override
  String get withdrawBalance => 'Para Çekme';

  @override
  String get iban => 'IBAN';

  @override
  String get withdrawSuccessful => 'Para çekme talebi başarıyla oluşturuldu';

  @override
  String get insufficientBalance => 'Yetersiz bakiye';

  @override
  String get enterValidIban => 'Lütfen geçerli bir IBAN girin';

  @override
  String get bestSeller => 'Çok Satan';

  @override
  String upsellMessage(String amount) {
    return '$amount daha ekle, indirimi kap!';
  }

  @override
  String get campaignApplied => 'Kampanya Uygulandı';

  @override
  String get free => 'Ücretsiz';

  @override
  String get appTitle => 'Talabi';

  @override
  String get welcome => 'Hoş Geldiniz';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get currency => 'Para Birimi';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get arabic => 'Arapça';

  @override
  String get turkishLira => 'Türk Lirası';

  @override
  String get tether => 'Tether';

  @override
  String get save => 'Kaydet';

  @override
  String get productResmi => 'Ürün resmi';

  @override
  String get yildiz => 'yıldız';

  @override
  String get favorilereEkle => 'Favorilere ekle';

  @override
  String get favorilerdenCikar => 'Favorilerden çıkar';

  @override
  String get menu => 'Menü';

  @override
  String get fiyat => 'Fiyat';

  @override
  String get adediAzalt => 'Adedi azalt';

  @override
  String get miktar => 'Miktar';

  @override
  String get adediArtir => 'Adedi artır';

  @override
  String get sepeteEkle => 'Sepete ekle';

  @override
  String get share => 'Paylaş';

  @override
  String get back => 'Geri dön';

  @override
  String get degerlendirme => 'değerlendirme';

  @override
  String get totalAmount => 'Toplam tutar';

  @override
  String degerlendirmeSayisi(Object count) {
    return '$count değerlendirme';
  }

  @override
  String get yourOrderFeedback => 'Sipariş Değerlendirmen';

  @override
  String orderNumberWithId(String id) {
    return '$id numaralı sipariş';
  }

  @override
  String get pendingApproval => 'Onay Bekliyor';

  @override
  String get approved => 'Onaylandı';

  @override
  String get errorOccurred => 'Bir hata oluştu';

  @override
  String get logoutConfirmation =>
      'Oturumu kapatmak istediğinize emin misiniz?';

  @override
  String get beTheFirstToReview => 'İlk yorumu sen yap';

  @override
  String get writeAReview => 'Yorum yap';

  @override
  String get mustOrderToReview =>
      'Yorum yapabilmek için üründen sipariş etmiş olmanız gerekmektedir.';

  @override
  String get reviewCreatedSuccessfully => 'Değerlendirme başarıyla oluşturuldu';

  @override
  String get send => 'Gönder';

  @override
  String characterLimitInfo(int min, int max, int current) {
    return 'Karakter sınırı: $min-$max (Şu an: $current)';
  }

  @override
  String get myReviews => 'Değerlendirmelerim';

  @override
  String get myReviewsDescription => 'Yaptığınız tüm yorumları görün';

  @override
  String commentTooShort(int min) {
    return 'Yorum çok kısa (en az $min karakter)';
  }

  @override
  String get cancel => 'İptal';

  @override
  String get products => 'Ürünler';

  @override
  String get vendors => 'Satıcılar';

  @override
  String get cart => 'Sepet';

  @override
  String get orders => 'Siparişler';

  @override
  String get notificationAll => 'Tümü';

  @override
  String get notificationOrders => 'Siparişler';

  @override
  String get notificationReviews => 'Yorumlar';

  @override
  String get notificationSystem => 'Sistem';

  @override
  String get favorites => 'Favoriler';

  @override
  String get addresses => 'Adresler';

  @override
  String get search => 'Ara';

  @override
  String get price => 'Fiyat';

  @override
  String get addToCart => 'Sepete Ekle';

  @override
  String get total => 'Toplam';

  @override
  String get totalPrice => 'Toplam Fiyat';

  @override
  String get checkout => 'Ödeme';

  @override
  String get checkoutSubtitle => 'Güvenli Ödeme';

  @override
  String get orderInformation => 'Sipariş Bilgileri';

  @override
  String get orderHistory => 'Sipariş Geçmişi';

  @override
  String get orderDetail => 'Sipariş Detayı';

  @override
  String get deliveryTracking => 'Teslimat Takibi';

  @override
  String get selectLanguage => 'Dil Seç';

  @override
  String get selectCurrency => 'Para Birimi Seç';

  @override
  String get selectCurrencyDescription => 'Para birimi seçimi';

  @override
  String get regionalSettings => 'Bölgesel Ayarlar';

  @override
  String get dateFormat => 'Tarih Formatı';

  @override
  String get timeFormat => 'Saat Formatı';

  @override
  String get timeZone => 'Saat Dilimi';

  @override
  String get hour24 => '24 Saat';

  @override
  String get hour12 => '12 Saat';

  @override
  String get discover => 'Keşfet';

  @override
  String get myFavorites => 'Favorilerim';

  @override
  String get myCart => 'Sepetim';

  @override
  String get myOrders => 'Siparişlerim';

  @override
  String get myAccount => 'Hesabım';

  @override
  String get myProfile => 'Profilim';

  @override
  String get user => 'Kullanıcı';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get editProfileDescription =>
      'İşletme adı, adres ve iletişim bilgilerini düzenle';

  @override
  String get editCourierProfileDescription =>
      'Ad, telefon, araç bilgisi ve çalışma saatlerini düzenle';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get myAddresses => 'Adreslerim';

  @override
  String get favoriteProducts => 'Favori Ürünler';

  @override
  String get popularProducts => 'Popüler Ürünler';

  @override
  String get popularVendors => 'Popüler İşletmeler';

  @override
  String get viewAll => 'Tümünü Gör';

  @override
  String get productDetail => 'Ürün Detayı';

  @override
  String get description => 'Açıklama';

  @override
  String get vendor => 'Satıcı';

  @override
  String get category => 'Kategori';

  @override
  String get addToFavorites => 'Favorilere Ekle';

  @override
  String get removeFromFavorites => 'Favorilerden Çıkar';

  @override
  String get inStock => 'Stokta Var';

  @override
  String get outOfStock => 'Stokta Yok';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signUp => 'Kayıt Ol';

  @override
  String get welcomeBack => 'Hoş Geldiniz!';

  @override
  String get loginDescription =>
      'Sipariş vermek ve verdiğiniz siparişleri anlık olarak takip etmek için giriş yapın';

  @override
  String get emailAddress => 'E-posta Adresi';

  @override
  String get password => 'Şifre';

  @override
  String get rememberMe => 'Beni hatırla?';

  @override
  String get recoveryPassword => 'Şifremi Unuttum';

  @override
  String get logIn => 'Giriş Yap';

  @override
  String get orContinueWith => 'Veya devam et';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get facebook => 'Facebook';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu? ';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get registerDescription => 'Talabi\'ye başlamak için kayıt olun';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? ';

  @override
  String get emailRequired => 'E-posta gerekli';

  @override
  String get validEmail => 'Geçerli bir e-posta girin';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get passwordMinLength => 'Şifre en az 6 karakter olmalı';

  @override
  String get fullNameRequired => 'Ad soyad gerekli';

  @override
  String get loginFailed => 'Giriş başarısız';

  @override
  String get registerFailed => 'Kayıt başarısız';

  @override
  String get membershipAgreement => 'Üyelik Sözleşmesi';

  @override
  String get iReadAndAccept => 'Okudum ve kabul ediyorum';

  @override
  String get pleaseAcceptAgreement => 'Lütfen üyelik sözleşmesini kabul edin';

  @override
  String get kvkkAgreement => 'KVKK Aydınlatma Metni\'ni okudum';

  @override
  String get marketingPermission =>
      'Kampanya, indirim ve duyurulardan haberdar olmak istiyorum';

  @override
  String get pleaseAcceptKvkk => 'Lütfen KVKK metnini onaylayın';

  @override
  String get iAcceptDistanceSalesAgreement =>
      'Mesafeli Satış Sözleşmesi\'ni okudum ve kabul ediyorum';

  @override
  String get pleaseAcceptDistanceSales =>
      'Lütfen Mesafeli Satış Sözleşmesi\'ni onaylayın';

  @override
  String get passwordReset => 'Şifre Sıfırlama';

  @override
  String get forgetPassword => 'Şifremi Unuttum';

  @override
  String get forgetPasswordDescription =>
      'Şifrenizi sıfırlamak için e-posta adresinizi girin';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get passwordResetEmailSent =>
      'Şifre sıfırlama e-postası e-posta adresinize gönderildi';

  @override
  String get passwordResetFailed => 'Şifre sıfırlama e-postası gönderilemedi';

  @override
  String get emailVerification => 'E-posta Doğrulama';

  @override
  String get checkYourEmail => 'E-postanızı Kontrol Edin';

  @override
  String get emailVerificationDescription =>
      'E-posta adresinize bir doğrulama bağlantısı gönderdik. Lütfen gelen kutunuzu kontrol edin ve hesabınızı doğrulamak için bağlantıya tıklayın.';

  @override
  String get iHaveVerified => 'Doğruladım';

  @override
  String get resendEmail => 'E-postayı Tekrar Gönder';

  @override
  String get resendFeatureComingSoon =>
      'Tekrar gönderme özelliği yakında gelecek';

  @override
  String get verificationEmailResent => 'Doğrulama e-postası tekrar gönderildi';

  @override
  String get pleaseVerifyEmail => 'Lütfen e-posta adresinizi doğrulayın.';

  @override
  String get offlineMode => 'Çevrimdışı Mod';

  @override
  String get offlineModeDescription => 'Bazı özellikler sınırlı olabilir';

  @override
  String get accessibilityTitle => 'Erişilebilirlik ve Görünüm';

  @override
  String get accessibilityDescription =>
      'Daha rahat okunabilirlik için tema, kontrast ve yazı boyutunu özelleştir';

  @override
  String get displaySettings => 'Görünüm';

  @override
  String get darkMode => 'Karanlık Mod';

  @override
  String get darkModeDescription =>
      'Düşük ışık ortamları için koyu temayı kullan';

  @override
  String get highContrast => 'Yüksek Kontrast';

  @override
  String get highContrastDescription =>
      'Daha iyi görünürlük için kontrastı artır';

  @override
  String get textSize => 'Metin Boyutu';

  @override
  String get textSizeDescription =>
      'Okunabilirliği artırmak için yazı boyutunu ayarla';

  @override
  String get textSizePreview => 'Önizleme Metni';

  @override
  String get cartEmptyMessage => 'Sepetiniz boş';

  @override
  String get cartEmptySubMessage =>
      'Sepetinde ürün bulunmamaktadır.\nHemen alışverişe başla!';

  @override
  String get startShopping => 'Alışverişe Başla';

  @override
  String get recommendedForYou => 'Senin İçin Önerilenler';

  @override
  String get cartVoucherPlaceholder => 'Kupon kodunuzu girin';

  @override
  String get cartSubtotalLabel => 'Ara Toplam';

  @override
  String get discountTitle => 'İndirim';

  @override
  String get cartDeliveryFeeLabel => 'Teslimat Ücreti';

  @override
  String get freeDeliveryReached => 'Ücretsiz teslimat sınırına ulaştınız!';

  @override
  String remainingForFreeDelivery(String amount) {
    return 'Ücretsiz teslimat için $amount daha';
  }

  @override
  String get freeDeliveryDescription =>
      'Sepetinize biraz daha ürün ekleyerek kargo ücretinden kurtulun!';

  @override
  String get cartTotalAmountLabel => 'Genel Toplam';

  @override
  String get checkoutTitle => 'Ödeme';

  @override
  String get addOrderNote => 'Sipariş Notu Ekle';

  @override
  String get orderNote => 'Sipariş Notu';

  @override
  String get enterOrderNoteHint => 'Siparişiniz için notunuzu girin...';

  @override
  String get couponApplied => 'Kupon Uygulandı';

  @override
  String get couponRemoved => 'Kupon Kaldırıldı';

  @override
  String get enterCouponCode => 'Kupon Kodu Girin';

  @override
  String get apply => 'Uygula';

  @override
  String get noCampaignsFound => 'Aktif Kampanya Yok';

  @override
  String get noCampaignsDescription =>
      'Şu anda aktif bir kampanya bulunmamaktadır. Lütfen daha sonra tekrar kontrol edin veya kupon kodu girin.';

  @override
  String get confirmOrder => 'Siparişi Onayla';

  @override
  String get cartSameVendorWarning =>
      'Sepetteki tüm ürünler aynı marketten olmalı';

  @override
  String get orderPlacedTitle => 'Sipariş Alındı!';

  @override
  String orderPlacedMessage(Object orderId, Object total) {
    return 'Sipariş numaranız: $orderId\nToplam: $total';
  }

  @override
  String get ok => 'Tamam';

  @override
  String get duplicateEmail =>
      'Bu email adresi ile zaten bir hesap bulunmaktadır.';

  @override
  String get passwordRuleChars => 'En az 6 karakter';

  @override
  String get passwordRuleDigit => 'En az bir rakam (0-9)';

  @override
  String get passwordRuleUpper => 'En az bir büyük harf (A-Z)';

  @override
  String get passwordRuleLower => 'En az bir küçük harf (a-z)';

  @override
  String get passwordRuleSpecial => 'En az bir özel karakter (@,*,!,? vb.)';

  @override
  String googleLoginFailed(Object error) {
    return 'Google ile giriş başarısız: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Apple ile giriş başarısız: $error';
  }

  @override
  String get attentionRequired => 'Dikkat Gerekenler';

  @override
  String criticalStockAlert(int count) {
    return '$count ürün kritik stok seviyesinde';
  }

  @override
  String delayedOrdersAlert(int count) {
    return '$count sipariş gecikmiş durumda';
  }

  @override
  String unansweredReviewsAlert(int count) {
    return '$count cevaplanmamış yorum var';
  }

  @override
  String get hourlySalesToday => 'Bugünün Saatlik Satışları';

  @override
  String facebookLoginFailed(Object error) {
    return 'Facebook ile giriş başarısız: $error';
  }

  @override
  String errorWithMessage(Object error) {
    return 'Hata: $error';
  }

  @override
  String get clearCartTitle => 'Sepeti Temizle';

  @override
  String get clearCartMessage =>
      'Sepetteki tüm ürünleri kaldırmak istiyor musunuz?';

  @override
  String get clearCartNo => 'Hayır';

  @override
  String get clearCartYes => 'Evet';

  @override
  String get clearCartSuccess => 'Sepet başarıyla temizlendi';

  @override
  String get categoryChangeConfirmTitle => 'Kategori Değişimi';

  @override
  String get categoryChangeConfirmMessage =>
      'Kategori değişimi yaptığınızda sepetinizdeki ürünler silinecektir.';

  @override
  String get categoryChangeConfirmOk => 'Onayla';

  @override
  String get categoryChangeConfirmCancel => 'İptal Et';

  @override
  String productByVendor(Object vendorName) {
    return 'Satıcı: $vendorName';
  }

  @override
  String get alreadyReviewedTitle => 'Bilgi';

  @override
  String get alreadyReviewedMessage => 'Bu ürüne daha önce puan verdiniz.';

  @override
  String get writeReview => 'Yorum Yaz';

  @override
  String get courierLogin => 'Kurye Girişi';

  @override
  String get courierWelcome => 'Hoş Geldin Kurye!';

  @override
  String get courierSubtitle => 'Teslimatlarını yönetmek için giriş yap';

  @override
  String get areYouCourier => 'Kurye misiniz?';

  @override
  String get areYouVendor => 'Satıcı mısınız? ';

  @override
  String get courierSignIn => 'Giriş yap';

  @override
  String get courierLoginLink => 'Kurye Girişi';

  @override
  String get roleCustomer => 'Müşteri';

  @override
  String get roleVendor => 'Satıcı';

  @override
  String get roleCourier => 'Kurye';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get activeDeliveries => 'Aktif Teslimatlar';

  @override
  String get deliveryHistory => 'Teslimat Geçmişi';

  @override
  String get earnings => 'Kazançlar';

  @override
  String get deliveries => 'Teslimatlar';

  @override
  String get noActiveDeliveries => 'Aktif teslimat yok';

  @override
  String get courierProfileNotFound => 'Kurye profili bulunamadı';

  @override
  String get profileUpdatedSuccessfully => 'Profil başarıyla güncellendi';

  @override
  String get invalidStatus =>
      'Geçersiz durum. Geçerli değerler: Offline, Available, Busy, Break, Assigned';

  @override
  String get cannotGoAvailableOutsideWorkingHours =>
      'Çalışma saatleri dışında müsait olamazsınız';

  @override
  String get cannotGoOfflineWithActiveOrders =>
      'Aktif siparişleriniz varken çevrimdışı olamazsınız';

  @override
  String get statusUpdated => 'Durum güncellendi';

  @override
  String get locationUpdatedSuccessfully => 'Konum başarıyla güncellendi';

  @override
  String get invalidLatitude => 'Geçersiz enlem';

  @override
  String get invalidLongitude => 'Geçersiz boylam';

  @override
  String get orderAcceptedSuccessfully => 'Sipariş başarıyla kabul edildi';

  @override
  String get orderRejectedSuccessfully => 'Sipariş başarıyla reddedildi';

  @override
  String get orderPickedUpSuccessfully => 'Sipariş başarıyla alındı';

  @override
  String get orderDeliveredSuccessfully => 'Sipariş başarıyla teslim edildi';

  @override
  String get deliveryProofSubmittedSuccessfully =>
      'Teslimat kanıtı başarıyla gönderildi';

  @override
  String get orderNotFoundOrNotAssigned =>
      'Sipariş bulunamadı veya size atanmamış';

  @override
  String get orderMustBeDeliveredBeforeSubmittingProof =>
      'Teslimat kanıtı göndermeden önce sipariş teslim edilmiş olmalı';

  @override
  String get failedToAcceptOrder =>
      'Sipariş kabul edilemedi. Zaten alınmış veya iptal edilmiş olabilir';

  @override
  String get failedToRejectOrder => 'Sipariş reddedilemedi';

  @override
  String get failedToPickUpOrder => 'Sipariş alınamadı';

  @override
  String get failedToDeliverOrder => 'Sipariş teslim edilemedi';

  @override
  String failedToLoadProfile(Object error) {
    return 'Profil yüklenemedi: $error';
  }

  @override
  String get failedToUpdateStatus => 'Durum güncellenemedi';

  @override
  String get failedToUpdateLocation => 'Konum güncellenemedi';

  @override
  String get failedToLoadStatistics => 'İstatistikler yüklenemedi';

  @override
  String get failedToLoadActiveOrders => 'Aktif siparişler yüklenemedi';

  @override
  String get failedToLoadOrderDetail => 'Sipariş detayı yüklenemedi';

  @override
  String get failedToLoadTodayEarnings => 'Bugünkü kazançlar yüklenemedi';

  @override
  String get failedToLoadWeeklyEarnings => 'Haftalık kazançlar yüklenemedi';

  @override
  String get failedToLoadMonthlyEarnings => 'Aylık kazançlar yüklenemedi';

  @override
  String get failedToLoadEarningsHistory => 'Kazanç geçmişi yüklenemedi';

  @override
  String get failedToSubmitProof => 'Teslimat kanıtı gönderilemedi';

  @override
  String get failedToUpdateProfile => 'Profil güncellenemedi';

  @override
  String get failedToUploadImage => 'Resim yüklenemedi';

  @override
  String get noFileUploaded => 'Dosya yüklenmedi';

  @override
  String get internalServerErrorDuringUpload =>
      'Yükleme sırasında sunucu hatası oluştu';

  @override
  String get checkAvailability => 'Müsaitlik Kontrolü';

  @override
  String get businessSettings => 'İşletme Ayarları';

  @override
  String get businessActive => 'İşletme Aktif';

  @override
  String get customersCanPlaceOrders => 'Müşteriler sipariş verebilir';

  @override
  String get orderTakingClosed => 'Sipariş alımı kapalı';

  @override
  String get businessOperations => 'İşletme İşlemleri';

  @override
  String get minimumOrderAmount => 'Minimum Sipariş Tutarı';

  @override
  String get estimatedDeliveryTime => 'Tahmini Teslimat Süresi (dakika)';

  @override
  String get enterValidAmount => 'Geçerli bir tutar girin';

  @override
  String get enterValidTime => 'Geçerli bir süre girin';

  @override
  String get optional => 'Opsiyonel';

  @override
  String get deliveryFee => 'Teslimat Ücreti';

  @override
  String get addressRequiredTitle => 'Adres Gerekli';

  @override
  String get addressRequiredMessage =>
      'Sipariş vermek için önce bir teslimat adresi eklemeniz gerekiyor.';

  @override
  String get addressRequiredDescription =>
      'Sipariş verebilmek için en az bir adres eklemeniz gerekmektedir. Lütfen adresinizi ekleyin.';

  @override
  String get addAddress => 'Adres Ekle';

  @override
  String get legalDocuments => 'Yasal Belgeler';

  @override
  String get termsOfUse => 'Kullanım Şartları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get refundPolicy => 'İade ve İptal Politikası';

  @override
  String get distanceSalesAgreement => 'Mesafeli Satış Sözleşmesi';

  @override
  String get loadingContent => 'İçerik yükleniyor...';

  @override
  String get contentNotAvailable => 'İçerik mevcut değil';

  @override
  String get error => 'Hata';

  @override
  String get profileUpdated => 'Profil güncellendi';

  @override
  String get updatePersonalInfo => 'Kişisel bilgilerinizi güncelleyin';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String get profileImageUrl => 'Profil Resmi URL';

  @override
  String get dateOfBirth => 'Doğum Tarihi';

  @override
  String get notSelected => 'Seçilmedi';

  @override
  String profileLoadFailed(Object error) {
    return 'Profil yüklenemedi: $error';
  }

  @override
  String get settingsUpdateFailed => 'Ayarlar güncellenemedi';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get pushNotifications => 'Anlık Bildirimler';

  @override
  String get promotionalNotifications => 'Promosyon Bildirimleri';

  @override
  String get newProducts => 'Yeni Ürünler';

  @override
  String get more => 'Daha Fazla';

  @override
  String get accessibilityAndDisplay => 'Erişilebilirlik ve Görünüm';

  @override
  String get helpCenter => 'Yardım Merkezi';

  @override
  String get howCanWeHelpYou => 'Size nasıl yardımcı olabiliriz?';

  @override
  String get faq => 'SSS';

  @override
  String get frequentlyAskedQuestions => 'Sıkça sorulan sorular';

  @override
  String get contactSupport => 'Destek ile İletişim';

  @override
  String get callUs => 'Bizi Arayın';

  @override
  String get liveChat => 'Canlı Sohbet';

  @override
  String get available24x7 => '7/24 ulaşılabilir';

  @override
  String get close => 'Kapat';

  @override
  String get logoutConfirmTitle => 'Çıkış Yap';

  @override
  String get logoutConfirmMessage =>
      'Hesabınızdan çıkmak istediğinize emin misiniz?';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get passwordChangedSuccess => 'Şifre başarıyla değiştirildi';

  @override
  String get changePasswordDescription =>
      'Mevcut şifrenizi girin ve yeni şifrenizi seçin';

  @override
  String get currentPassword => 'Mevcut Şifre';

  @override
  String get currentPasswordRequired => 'Mevcut şifre gerekli';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get newPasswordRequired => 'Yeni şifre gerekli';

  @override
  String get confirmNewPassword => 'Şifre Tekrarı';

  @override
  String get confirmPasswordRequired => 'Şifre tekrarı gerekli';

  @override
  String get secureYourAccount => 'Hesabınızı güvende tutun';

  @override
  String get addressesLoadFailed => 'Adresler yüklenemedi';

  @override
  String get deleteAddressTitle => 'Adresi Sil';

  @override
  String get deleteAddressConfirm =>
      'Bu adresi silmek istediğinizden emin misiniz?';

  @override
  String get delete => 'Sil';

  @override
  String get addressDeleted => 'Adres silindi';

  @override
  String get defaultAddressUpdated => 'Varsayılan adres güncellendi';

  @override
  String get manageDeliveryAddresses => 'Teslimat adreslerinizi yönetin';

  @override
  String get noAddressesYet => 'Henüz adres eklenmemiş';

  @override
  String get tapToAddAddress => 'Yeni adres eklemek için + butonuna tıklayın';

  @override
  String get defaultLabel => 'Varsayılan';

  @override
  String get edit => 'Düzenle';

  @override
  String get setAsDefault => 'Varsayılan Yap';

  @override
  String get addressCountSingular => '1 adres';

  @override
  String addressCountPlural(Object count) {
    return '$count adres';
  }

  @override
  String get locationServicesDisabled => 'Konum servisleri devre dışı';

  @override
  String get pleaseSelectLocation => 'Lütfen bir konum seçin';

  @override
  String get selectedLocation => 'Seçilen Konum';

  @override
  String get addressTitleOptional => 'Adres Başlığı (Opsiyonel)';

  @override
  String get canBeLeftEmpty => 'Boş bırakılabilir';

  @override
  String get address => 'Adres';

  @override
  String get city => 'Şehir';

  @override
  String get district => 'İlçe';

  @override
  String get selectOrDragMarkerOnMap =>
      'Haritada bir konum seçin veya işaretçiyi sürükleyin';

  @override
  String get saveAddressButton => 'Adresi Kaydet';

  @override
  String get selectAddress => 'Adres Seç';

  @override
  String get selectLocationFromMap => 'Haritadan konum seç';

  @override
  String get addressAdded => 'Adres eklendi';

  @override
  String get addressUpdated => 'Adres güncellendi';

  @override
  String get editAddress => 'Adresi Düzenle';

  @override
  String get addNewAddress => 'Yeni Adres Ekle';

  @override
  String get updateAddressInfo => 'Adres bilgilerini güncelleyin';

  @override
  String get enterDeliveryAddressDetails => 'Teslimat adresi bilgilerini girin';

  @override
  String get addressTitleHint => 'Adres Başlığı (Ev, İş, vb.)';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String get selectAddressFromMap => 'Haritadan Adres Seç';

  @override
  String get fullAddress => 'Açık Adres';

  @override
  String get addressRequired => 'Adres gerekli';

  @override
  String get cityRequired => 'Şehir gerekli';

  @override
  String get districtRequired => 'İlçe gerekli';

  @override
  String get postalCodeOptional => 'Posta Kodu (Opsiyonel)';

  @override
  String get updateAddressButton => 'Adresi Güncelle';

  @override
  String get updateAddressDetails => 'Adres detaylarını güncelle';

  @override
  String get createNewAddress => 'Yeni adres oluştur';

  @override
  String get orderUpdates => 'Sipariş Güncellemeleri';

  @override
  String get orderUpdatesDescription =>
      'Sipariş durumu değişikliklerinde bildirim al';

  @override
  String get promotions => 'Kampanyalar';

  @override
  String get promotionsDescription => 'Özel teklifler ve kampanyalar';

  @override
  String get newProductsDescription => 'Yeni ürün eklendiğinde bildirim al';

  @override
  String get settingsSaved => 'Ayarlar kaydedildi';

  @override
  String get regionalSettingsDescription => 'Tarih ve saat ayarları';

  @override
  String get timeZoneHint => 'Örn: Europe/Istanbul, America/New_York';

  @override
  String get manageNotificationPreferences => 'Bildirim tercihlerinizi yönetin';

  @override
  String get orderHistoryDescription => 'Geçmiş siparişlerinizi görüntüleyin';

  @override
  String get myAddressesDescription => 'Teslimat adreslerinizi yönetin';

  @override
  String get myFavoriteProducts => 'Favori Ürünlerim';

  @override
  String get myFavoriteProductsDescription =>
      'Beğendiğiniz ürünleri görüntüleyin ve yönetin';

  @override
  String get changePasswordSubtitle =>
      'Şifrenizi değiştirin ve güvenliği artırın';

  @override
  String get notificationSettingsDescription =>
      'Bildirim tercihlerinizi yönetin';

  @override
  String get selectLanguageDescription => 'Uygulama dilini değiştirin';

  @override
  String get selectLanguageSubtitle => 'Tercih ettiğiniz dili seçin';

  @override
  String get languageChanged => 'Dil değiştirildi';

  @override
  String languagesCount(Object count) {
    return '$count dil';
  }

  @override
  String get legalDocumentsDescription => 'Kullanım şartları ve politikalar';

  @override
  String get helpCenterDescription => 'SSS ve destek hattı';

  @override
  String get logoutDescription => 'Hesabınızdan çıkış yapın';

  @override
  String get vendorRegister => 'Satıcı Kaydı';

  @override
  String get talabiBusiness => 'Talabi Business';

  @override
  String get createBusinessAccount => 'İşletme Hesabı Oluştur';

  @override
  String get createYourStoreAndStartSelling =>
      'Mağazanızı oluşturun ve satışa başlayın';

  @override
  String get businessName => 'İşletme Adı';

  @override
  String get businessNameRequired => 'İşletme adı gerekli';

  @override
  String get phoneNumberRequired => 'Telefon numarası gerekli';

  @override
  String get createVendorAccount => 'Satıcı Hesabı Oluştur';

  @override
  String get alreadyHaveVendorAccount => 'Zaten satıcı hesabınız var mı? ';

  @override
  String get isCustomerAccount => 'Müşteri hesabı mı? ';

  @override
  String get emailAlreadyExists =>
      'Bu email adresi ile zaten bir hesap bulunmaktadır.';

  @override
  String get enterFourDigitCode => 'Lütfen 4 haneli kodu giriniz';

  @override
  String get emailVerifiedSuccess => 'Email adresi başarıyla doğrulandı';

  @override
  String get emailVerifiedLoginFailed =>
      'Email doğrulandı ancak otomatik giriş başarısız. Lütfen giriş yapın.';

  @override
  String get verificationFailed => 'Doğrulama başarısız';

  @override
  String get verificationCodeResent => 'Doğrulama kodu yeniden gönderildi';

  @override
  String get codeSendFailed => 'Kod gönderilemedi';

  @override
  String get fourDigitVerificationCode => '4 Haneli Doğrulama Kodu';

  @override
  String enterCodeSentToEmail(Object email) {
    return '$email adresine gönderilen 4 haneli kodu giriniz';
  }

  @override
  String codeExpiresIn(Object time) {
    return 'Kod $time sonra geçersiz olacak';
  }

  @override
  String get resendCode => 'Tekrar Kod Gönder';

  @override
  String settingsLoadError(Object error) {
    return 'Ayarlar yüklenemedi: $error';
  }

  @override
  String get settingsUpdated => 'Ayarlar güncellendi';

  @override
  String get reviewApproved => 'Yorum onaylandı';

  @override
  String reviewApproveError(Object error) {
    return 'Yorum onaylanırken hata oluştu: $error';
  }

  @override
  String get rejectReview => 'Yorumu Reddet';

  @override
  String get rejectReviewConfirmation =>
      'Bu yorumu reddetmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get reject => 'Reddet';

  @override
  String get reviewRejected => 'Yorum reddedildi';

  @override
  String reviewRejectError(Object error) {
    return 'Yorum reddedilirken hata oluştu: $error';
  }

  @override
  String userId(Object id) {
    return 'Kullanıcı ID: $id';
  }

  @override
  String get rating => 'Puan';

  @override
  String get comment => 'Yorum';

  @override
  String get noComment => 'Yorum yok';

  @override
  String get date => 'Tarih';

  @override
  String get approve => 'Onayla';

  @override
  String get verify => 'Onayla';

  @override
  String get placeOrder => 'Sipariş Ver';

  @override
  String get deliveryAddress => 'Teslimat Adresi';

  @override
  String get changeAddress => 'Değiştir';

  @override
  String get paymentMethod => 'Ödeme Yöntemi';

  @override
  String get cash => 'Nakit';

  @override
  String get creditCard => 'Kredi Kartı';

  @override
  String get mobilePayment => 'Mobil Ödeme';

  @override
  String get comingSoon => 'Çok Yakında';

  @override
  String get orderNotePlaceholder => 'Kurye için not ekle (isteğe bağlı)';

  @override
  String get estimatedDelivery => 'Tahmini Teslimat';

  @override
  String get minutes => 'dakika';

  @override
  String get orderSummary => 'Sipariş Özeti';

  @override
  String get pleaseSelectAddress => 'Lütfen teslimat adresi seçin';

  @override
  String get pleaseSelectPaymentMethod => 'Lütfen ödeme yöntemi seçin';

  @override
  String get orderCreatedSuccess => 'Siparişiniz başarıyla oluşturuldu!';

  @override
  String get noAddressFound => 'Kayıtlı adres bulunamadı';

  @override
  String get cashDescription =>
      'Nakit olarak kapıda kuryeye teslim edebilirsiniz.';

  @override
  String get paymentComingSoonDescription =>
      'Bu ödeme yöntemi yakında hizmete girecektir.';

  @override
  String get skip => 'Geç';

  @override
  String get next => 'İleri';

  @override
  String get getStarted => 'Hadi Başlayın!';

  @override
  String get onboardingTitle1 =>
      'Lezzetli Yemekler\nDakikalar İçinde Kapınızda';

  @override
  String get onboardingDesc1 =>
      'Favori restoranlarınızdan dilediğiniz yemeği sipariş verin, sıcak sıcak tadını çıkarın.';

  @override
  String get onboardingTitle2 =>
      'Market Alışverişiniz\nDakikalar İçinde Kapınızda';

  @override
  String get onboardingDesc2 =>
      'Taze sebze, meyve ve günlük ihtiyaçlarınız en hızlı şekilde kapınızda.';

  @override
  String get onboardingTitle3 => 'En İyi Fiyatlar & Fırsatlar';

  @override
  String get onboardingDesc3 =>
      'Her gün özel fırsatların ve rekabetçi fiyatların tadını çıkarın';

  @override
  String get pending => 'Bekleyen';

  @override
  String get preparing => 'Hazırlanıyor';

  @override
  String get ready => 'Hazır';

  @override
  String get outForDelivery => 'Teslimata Çıktı';

  @override
  String get delivered => 'Teslim Edildi';

  @override
  String get cancelled => 'İptal Edildi';

  @override
  String get assigned => 'Atandı';

  @override
  String get accepted => 'Kabul Edildi';

  @override
  String get rejected => 'Reddedildi';

  @override
  String get pickedUp => 'Teslim Alındı';

  @override
  String get courierInformation => 'Kurye Bilgileri';

  @override
  String get assignedAt => 'Atanma Tarihi';

  @override
  String get acceptedAt => 'Kabul Tarihi';

  @override
  String get pickedUpAt => 'Teslim Alındı';

  @override
  String get outForDeliveryAt => 'Teslimata Çıktı';

  @override
  String get vendorOrders => 'Satıcı Siparişleri';

  @override
  String pendingOrdersCount(int count) {
    return '$count adet bekleyen sipariş';
  }

  @override
  String preparingOrdersCount(int count) {
    return '$count adet hazırlanan sipariş';
  }

  @override
  String readyOrdersCount(int count) {
    return '$count adet hazır sipariş';
  }

  @override
  String deliveredOrdersCount(int count) {
    return '$count adet sipariş teslim edildi';
  }

  @override
  String get noOrdersFound => 'Sipariş bulunamadı';

  @override
  String get order => 'Sipariş';

  @override
  String get customer => 'Müşteri';

  @override
  String get vendorDashboard => 'Satıcı Paneli';

  @override
  String summaryLoadError(Object error) {
    return 'Özet yüklenemedi: $error';
  }

  @override
  String welcomeVendor(Object name) {
    return 'Hoş Geldiniz, $name';
  }

  @override
  String get todayOrders => 'Bugünkü Siparişler';

  @override
  String get pendingOrders => 'Bekleyen Siparişler';

  @override
  String get todayRevenue => 'Bugünkü Gelir';

  @override
  String get weeklyRevenue => 'Haftalık Gelir';

  @override
  String get quickActions => 'Hızlı İşlemler';

  @override
  String get reports => 'Raporlar';

  @override
  String get logoUpdated => 'Logo güncellendi';

  @override
  String logoUploadFailed(Object error) {
    return 'Logo yüklenemedi: $error';
  }

  @override
  String get locationSelectedChange => 'Konum Seçildi (Değiştir)';

  @override
  String get selectLocationFromMapRequired => 'Haritadan Konum Seç *';

  @override
  String get locationSelectionRequired => 'Haritadan konum seçimi zorunludur';

  @override
  String get addressAutoFillHint =>
      'Haritadan seçilen adres otomatik doldurulur, manuel düzenleyebilirsiniz';

  @override
  String get selectLocationFirst => 'Önce haritadan konum seçmelisiniz';

  @override
  String get vendorLogin => 'Satıcı Girişi';

  @override
  String get welcomeBackVendor => 'Tekrar Hoş Geldiniz, Satıcı!';

  @override
  String get vendorLoginDescription =>
      'Mağazanızı ve siparişlerinizi yönetmek için giriş yapın';

  @override
  String get areYouCustomer => 'Müşteri misiniz?';

  @override
  String get vendorNotificationsTitle => 'Bildirimler';

  @override
  String get vendorNotificationsEmptyMessage => 'Henüz bildiriminiz yok.';

  @override
  String get vendorNotificationsErrorMessage =>
      'Bildirimler yüklenirken bir hata oluştu.';

  @override
  String get vendorProductsTitle => 'Ürünlerim';

  @override
  String get vendorProductsSearchHint => 'Ürün ara...';

  @override
  String vendorProductsLoadError(Object error) {
    return 'Ürünler yüklenemedi: $error';
  }

  @override
  String vendorProductsSetOutOfStock(Object productName) {
    return '$productName stok dışı yapıldı';
  }

  @override
  String vendorProductsSetInStock(Object productName) {
    return '$productName stokta';
  }

  @override
  String get vendorProductsDeleteTitle => 'Ürünü Sil';

  @override
  String vendorProductsDeleteConfirmation(Object productName) {
    return '$productName ürününü silmek istediğinize emin misiniz?';
  }

  @override
  String vendorProductsDeleteSuccess(Object productName) {
    return '$productName silindi';
  }

  @override
  String get vendorProductsEmpty => 'Ürün bulunamadı';

  @override
  String get vendorProductsAddFirst => 'İlk Ürününü Ekle';

  @override
  String get vendorProductsAddNew => 'Yeni Ürün';

  @override
  String get vendorProductFormEditTitle => 'Ürün Düzenle';

  @override
  String get vendorProductFormNewTitle => 'Yeni Ürün';

  @override
  String get vendorProductFormImageUploaded => 'Resim yüklendi';

  @override
  String vendorProductFormImageUploadError(Object error) {
    return 'Resim yüklenemedi: $error';
  }

  @override
  String get vendorProductFormSourceCamera => 'Kamera';

  @override
  String get vendorProductFormSourceGallery => 'Galeri';

  @override
  String get vendorProductFormCreateSuccess => 'Ürün oluşturuldu';

  @override
  String get vendorProductFormUpdateSuccess => 'Ürün güncellendi';

  @override
  String vendorProductFormError(Object error) {
    return 'Hata: $error';
  }

  @override
  String get vendorProductFormNameLabel => 'Ürün Adı *';

  @override
  String get vendorProductFormNameRequired => 'Ürün adı gerekli';

  @override
  String get vendorProductFormDescriptionLabel => 'Açıklama';

  @override
  String get vendorProductFormCategoryLabel => 'Kategori';

  @override
  String get vendorProductFormPriceLabel => 'Fiyat *';

  @override
  String get vendorProductFormPriceRequired => 'Fiyat gerekli';

  @override
  String get vendorProductFormPriceInvalid => 'Geçerli bir fiyat girin';

  @override
  String get vendorProductFormStockLabel => 'Stok Miktarı';

  @override
  String get vendorProductFormInvalidNumber => 'Geçerli bir sayı girin';

  @override
  String get vendorProductFormPreparationTimeLabel =>
      'Hazırlık Süresi (dakika)';

  @override
  String get vendorProductFormInStockLabel => 'Stokta';

  @override
  String get vendorProductFormInStockDescription =>
      'Ürün müşterilere gösterilecek';

  @override
  String get vendorProductFormOutOfStockDescription =>
      'Ürün stok dışı olarak işaretlenecek';

  @override
  String get updateButton => 'Güncelle';

  @override
  String get createButton => 'Oluştur';

  @override
  String get vendorProductFormAddImage => 'Resim Ekle';

  @override
  String get vendorProfileTitle => 'Satıcı Profilim';

  @override
  String get vendorFallbackSubtitle => 'Satıcı';

  @override
  String get businessInfo => 'İşletme Bilgileri';

  @override
  String get addressLabel => 'Adres';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get generalSettings => 'Genel Ayarlar';

  @override
  String get businessSettingsTitle => 'İşletme Ayarları';

  @override
  String get businessSettingsSubtitle =>
      'Minimum sipariş, teslimat ücreti ve diğer ayarlar';

  @override
  String get languageNameTr => 'Türkçe';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameAr => 'العربية';

  @override
  String get businessNameFallback => 'İşletme Adı';

  @override
  String get retry => 'Yeniden Dene';

  @override
  String get markAsRead => 'Okundu olarak işaretle';

  @override
  String get pendingReviews => 'Bekleyen Yorumlar';

  @override
  String get noPendingReviews => 'Bekleyen yorum yok';

  @override
  String reviewsLoadError(Object error) {
    return 'Yorumlar yüklenemedi: $error';
  }

  @override
  String get salesReports => 'Satış Raporları';

  @override
  String get selectDateRange => 'Tarih Aralığı Seç';

  @override
  String get daily => 'Günlük';

  @override
  String get weekly => 'Haftalık';

  @override
  String get monthly => 'Aylık';

  @override
  String get noReportFound => 'Rapor bulunamadı';

  @override
  String get totalOrders => 'Toplam Sipariş';

  @override
  String get totalRevenue => 'Toplam Gelir';

  @override
  String get completed => 'Tamamlanan';

  @override
  String get cancelledOrders => 'İptal Edilen';

  @override
  String get dailySales => 'Günlük Satışlar';

  @override
  String orderCount(Object count) {
    return '$count sipariş';
  }

  @override
  String get refresh => 'Yenile';

  @override
  String get cancelOrder => 'Siparişi İptal Et';

  @override
  String get reorder => 'Yeniden Sipariş Ver';

  @override
  String get orderCancelled => 'Sipariş iptal edildi';

  @override
  String get cancelReason => 'İptal nedeni';

  @override
  String get cancelReasonDescription =>
      'İptal nedeninizi belirtin (en az 10 karakter):';

  @override
  String get acceptOrderTitle => 'Sipariş Kabul';

  @override
  String get acceptOrderConfirmation =>
      'Siparişi kabul etmek istediğinizden emin misiniz?';

  @override
  String get acceptOrder => 'Kabul Et';

  @override
  String get updateOrderStatusTitle => 'Sipariş Durumu Güncelleme';

  @override
  String get markAsReadyConfirmation =>
      'Siparişi \"Hazır\" olarak işaretlemek istediğinizden emin misiniz?';

  @override
  String get markAsReady => 'Hazır Olarak İşaretle';

  @override
  String get rejectOrder => 'Siparişi Reddet';

  @override
  String get rejectOrderTitle => 'Sipariş Reddi';

  @override
  String get rejectReason => 'Red sebebi';

  @override
  String get rejectReasonDescription =>
      'Red sebebinizi girin (en az 1 karakter):';

  @override
  String get rejectReasonHint => 'Red sebebi...';

  @override
  String get rejectOrderConfirmation =>
      'Bu siparişi reddetmek istediğinizden emin misiniz?';

  @override
  String get orderRejected => 'Sipariş reddedildi';

  @override
  String get pieces => 'adet';

  @override
  String get orderNotFound => 'Sipariş bulunamadı';

  @override
  String get productsAddedToCart =>
      'Ürünler sepete eklendi, sepete yönlendiriliyorsunuz...';

  @override
  String reorderFailed(Object error) {
    return 'Yeniden sipariş oluşturulamadı: $error';
  }

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi';

  @override
  String get locationPermissionDeniedForever =>
      'Konum izni kalıcı olarak reddedildi';

  @override
  String vendorsLoadFailed(Object error) {
    return 'Marketler yüklenemedi: $error';
  }

  @override
  String get yourLocation => 'Konumunuz';

  @override
  String get locationPermissionTitle => 'Konum İzni Gerekli';

  @override
  String get locationPermissionMessage =>
      'Uygulamanın size yakın restoranları gösterebilmesi ve siparişlerinizi takip edebilmesi için konum iznine ihtiyacımız var.';

  @override
  String get allow => 'İzin Ver';

  @override
  String get locationManagement => 'Konum Yönetimi';

  @override
  String get currentLocationInfo => 'Mevcut Konum Bilgisi';

  @override
  String get latitude => 'Enlem';

  @override
  String get longitude => 'Boylam';

  @override
  String get lastLocationUpdate => 'Son Güncelleme';

  @override
  String get noLocationData => 'Henüz konum bilgisi yok';

  @override
  String get selectLocationOnMap => 'Haritada Konum Seç';

  @override
  String get useCurrentLocation => 'Mevcut Konumu Kullan';

  @override
  String get updateLocation => 'Konumu Güncelle';

  @override
  String get locationSharingInfo =>
      'Konum paylaşımı, yakınındaki restoranlardan sipariş alabilmen için gereklidir. Durumun \"Available\" olduğunda konumun otomatik olarak paylaşılır.';

  @override
  String get locationManagementDescription =>
      'Mevcut konumunu görüntüle ve güncelle';

  @override
  String get vendorsMap => 'Marketler Haritası';

  @override
  String get findMyLocation => 'Konumumu Bul';

  @override
  String get viewProducts => 'Ürünleri Görüntüle';

  @override
  String get gettingLocation => 'Konum alınıyor...';

  @override
  String searchError(Object error) {
    return 'Arama hatası: $error';
  }

  @override
  String productAddedToCart(Object productName) {
    return '$productName sepete eklendi';
  }

  @override
  String get filters => 'Filtreler';

  @override
  String get clear => 'Temizle';

  @override
  String get selectCategory => 'Kategori seçin';

  @override
  String get priceRange => 'Fiyat Aralığı';

  @override
  String get minPrice => 'Min Fiyat';

  @override
  String get maxPrice => 'Max Fiyat';

  @override
  String get selectCity => 'Şehir seçin';

  @override
  String get minimumRating => 'Minimum Rating';

  @override
  String get maximumDistance => 'Maksimum Mesafe (km)';

  @override
  String get distanceKm => 'Mesafe (km)';

  @override
  String get sortBy => 'Sıralama';

  @override
  String get selectSortBy => 'Sıralama seçin';

  @override
  String get priceLowToHigh => 'Fiyat (Düşükten Yükseğe)';

  @override
  String get priceHighToLow => 'Fiyat (Yüksekten Düşüğe)';

  @override
  String get sortByName => 'İsme Göre';

  @override
  String get newest => 'En Yeni';

  @override
  String get ratingHighToLow => 'Rating (Yüksekten Düşüğe)';

  @override
  String get popularity => 'Popülerlik';

  @override
  String get distance => 'Mesafe';

  @override
  String get applyFilters => 'Filtreleri Uygula';

  @override
  String get searchProductsOrVendors => 'Ürün veya market ara...';

  @override
  String get suggestions => 'Öneriler';

  @override
  String get product => 'Ürün';

  @override
  String get searchHistory => 'Arama Geçmişi';

  @override
  String get typeToSearch => 'Arama yapmak için yukarıdaki kutuya yazın';

  @override
  String get recentSearches => 'Son Aramalar';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String cityLabel(Object city) {
    return 'Şehir: $city';
  }

  @override
  String distanceLabel(Object distance) {
    return 'Mesafe: $distance km';
  }

  @override
  String get popularSearches => 'Popüler Aramalar';

  @override
  String get deliveryZones => 'Teslimat Bölgeleri';

  @override
  String get deliveryZonesDescription =>
      'Teslimat yaptığınız şehir ve ilçeleri yönetin';

  @override
  String get deliveryZonesUpdated => 'Teslimat bölgeleri başarıyla güncellendi';

  @override
  String removedFromFavorites(Object productName) {
    return '$productName favorilerden çıkarıldı';
  }

  @override
  String get noFavoritesFound => 'Henüz favori ürününüz yok';

  @override
  String get favoritesEmptyMessage =>
      'Beğendiğiniz ürünleri favorilere ekleyerek burada görüntüleyebilirsiniz.';

  @override
  String addedToFavorites(Object productName) {
    return '$productName favorilere eklendi';
  }

  @override
  String favoriteOperationFailed(Object error) {
    return 'Favori işlemi başarısız: $error';
  }

  @override
  String get noProductsYet => 'Henüz ürün yok.';

  @override
  String productLoadFailed(Object error) {
    return 'Ürün yüklenemedi: $error';
  }

  @override
  String get productNotFound => 'Ürün bulunamadı';

  @override
  String get rateVendor => 'Vendor\'u Değerlendir';

  @override
  String get shareYourThoughts => 'Düşüncelerinizi paylaşın...';

  @override
  String get submit => 'Gönder';

  @override
  String get vendorReviewSubmitted => 'Vendor değerlendirmesi gönderildi!';

  @override
  String get productReviewSubmitted => 'Ürün değerlendirmesi gönderildi!';

  @override
  String get noDescription => 'Açıklama bulunmuyor.';

  @override
  String get readMore => 'Daha fazla oku';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get deliveryTime => 'Teslimat Süresi';

  @override
  String get deliveryType => 'Teslimat Türü';

  @override
  String get reviewsTitle => 'Değerlendirmeler';

  @override
  String reviews(Object count) {
    return 'Yorumlar ($count)';
  }

  @override
  String get noReviewsYet => 'Henüz yorum yok. İlk yorumu siz yapın!';

  @override
  String get seeAllReviews => 'Tüm Yorumları Gör';

  @override
  String by(Object vendorName) {
    return 'Tarafından: $vendorName';
  }

  @override
  String get orderCreatedSuccessfully => 'Siparişiniz Başarıyla Oluşturuldu!';

  @override
  String get orderCode => 'Sipariş Kodu';

  @override
  String get orderPreparationStarted =>
      'Siparişiniz hazırlanmaya başlandı. Sipariş durumunuzu \"Siparişlerim\" sayfasından takip edebilirsiniz.';

  @override
  String get homePage => 'Ana Sayfa';

  @override
  String ordersLoadFailed(Object error) {
    return 'Siparişler yüklenemedi: $error';
  }

  @override
  String get noOrdersYet => 'Henüz siparişiniz yok';

  @override
  String get onWay => 'Yolda';

  @override
  String get unknownVendor => 'Bilinmeyen Satıcı';

  @override
  String get unknown => 'Bilinmeyen';

  @override
  String get cancelItem => 'Ürünü İptal Et';

  @override
  String get itemCancelled => 'Ürün İptal Edildi';

  @override
  String get itemCancelSuccess => 'Ürün başarıyla iptal edildi';

  @override
  String itemCancelFailed(Object error) {
    return 'Ürün iptal edilemedi: $error';
  }

  @override
  String get promotionalBannerTitle => 'Acıktınız mı?\nSizi düşündük!';

  @override
  String get promotionalBannerSubtitle =>
      'Ücretsiz teslimat, düşük ücretler & %10 nakit iade!';

  @override
  String get orderNow => 'Sipariş Ver';

  @override
  String get categories => 'Kategoriler';

  @override
  String get categoryNotFound => 'Kategori bulunamadı';

  @override
  String get picksForYou => 'Sizin İçin Seçtiklerimiz';

  @override
  String addressUpdateFailed(Object error) {
    return 'Adres güncellenemedi: $error';
  }

  @override
  String unreadNotificationsCount(Object count) {
    return '$count okunmamış bildirim';
  }

  @override
  String get campaigns => 'Kampanyalar';

  @override
  String productsCount(Object count) {
    return '$count ürün';
  }

  @override
  String campaignsCount(Object count) {
    return '$count kampanya';
  }

  @override
  String vendorsCount(Object count) {
    return '$count işletme';
  }

  @override
  String get similarProducts => 'Benzer Ürünler';

  @override
  String get areYouHungry => 'Acıktınız mı?';

  @override
  String get onboardingDescription =>
      'İhtiyacını talep et, en hızlı şekilde sana ulaştıralım.\nSipariş vermek artık tek dokunuş kadar kolay.';

  @override
  String get unlockDescription => 'Talabî\'ye doğru kaydırın!';

  @override
  String get addAddressToOrder => 'Sipariş vermek için adres ekleyin';

  @override
  String get createCourierAccount => 'Kurye Hesabı Oluştur';

  @override
  String get startDeliveringToday => 'Bugün teslimata başla ve para kazan';

  @override
  String get alreadyHaveCourierAccount => 'Zaten kurye hesabınız var mı? ';

  @override
  String get courierRegister => 'Kurye Kaydı';

  @override
  String get talabiCourier => 'Talabi Kurye';

  @override
  String get today => 'Bugün';

  @override
  String get allTime => 'Tüm zamanlar';

  @override
  String get accept => 'Kabul Et';

  @override
  String get markAsPickedUp => 'Alındı Olarak İşaretle';

  @override
  String get markAsDelivered => 'Teslim Edildi Olarak İşaretle';

  @override
  String get orderAccepted => 'Sipariş kabul edildi';

  @override
  String get orderMarkedAsPickedUp => 'Sipariş alındı olarak işaretlendi';

  @override
  String get orderDelivered => 'Sipariş teslim edildi';

  @override
  String get actionCouldNotBeCompleted => 'İşlem tamamlanamadı';

  @override
  String get cannotChangeStatusWhileBusy => 'Meşgulken durum değiştirilemez';

  @override
  String newOrderAssigned(Object orderId) {
    return 'Yeni sipariş #$orderId atandı!';
  }

  @override
  String get currentStatus => 'Anlık Durum';

  @override
  String get performance => 'Performans';

  @override
  String get availabilityStatus => 'Müsaitlik Durumu';

  @override
  String get checkNewOrderConditions =>
      'Yeni sipariş alabilme şartlarını buradan kontrol et';

  @override
  String get navigationApp => 'Navigasyon Uygulaması';

  @override
  String get selectPreferredNavigationApp =>
      'Tercih ettiğin navigasyon uygulamasını seç';

  @override
  String get noVehicleInfo => 'Araç bilgisi yok';

  @override
  String get cannotChangeStatusWithActiveOrders =>
      'Aktif sipariş varken durum değiştirilemez';

  @override
  String get cannotGoOfflineUntilOrdersCompleted =>
      'Aktif sipariş tamamlanana kadar offline olamazsın';

  @override
  String get points => 'Puan';

  @override
  String get totalEarnings => 'Toplam Kazanç';

  @override
  String get logoutConfirm => 'Çıkış yapmak istediğine emin misin?';

  @override
  String get personalInfo => 'Kişisel Bilgiler';

  @override
  String get courierSettings => 'Kurye Ayarları';

  @override
  String get vehicleType => 'Araç Türü';

  @override
  String get maxActiveOrders => 'Maksimum Aktif Sipariş';

  @override
  String get useWorkingHours => 'Çalışma saatlerini kullan';

  @override
  String get onlyAvailableDuringSetHours =>
      'Sadece belirlediğin saatlerde \"Müsait\" olabilirsin';

  @override
  String get startTime => 'Başlangıç Saati';

  @override
  String get endTime => 'Bitiş Saati';

  @override
  String get mustSelectStartAndEndTime =>
      'Çalışma saatleri için başlangıç ve bitiş seçmelisin';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get mustSelectVehicleType => 'Araç türü seçmelisin';

  @override
  String get selectVehicleType => 'Araç Türü Seçin';

  @override
  String get selectVehicleTypeDescription =>
      'Lütfen kullanacağınız araç türünü seçin. Bu seçim zorunludur.';

  @override
  String get motorcycle => 'Motor';

  @override
  String get car => 'Araba';

  @override
  String get bicycle => 'Bisiklet';

  @override
  String get vehicleTypeUpdatedSuccessfully =>
      'Araç türü başarıyla güncellendi';

  @override
  String get failedToUpdateVehicleType => 'Araç türü güncellenemedi';

  @override
  String get selectLocationRequired => 'Konum Seçimi Zorunlu';

  @override
  String get selectLocationRequiredDescription =>
      'Lütfen konumunuzu seçin. Bu bilgi sipariş almak için gereklidir.';

  @override
  String get selectFromMap => 'Haritadan Seç';

  @override
  String get gettingCurrentLocation => 'Konumunuz alınıyor...';

  @override
  String get locationServicesDisabledTitle => 'Konum Servisleri Kapalı';

  @override
  String get locationServicesDisabledMessage =>
      'Konum servisleri kapalı. Lütfen ayarlardan konum servislerini açın.';

  @override
  String get openSettings => 'Ayarları Aç';

  @override
  String get assignCourierConfirmationTitle => 'Kurye Atamasını Onayla';

  @override
  String assignCourierConfirmationMessage(String courierName) {
    return '$courierName adlı kuryeye bu siparişi atamak istediğinize emin misiniz?';
  }

  @override
  String get assign => 'Ata';

  @override
  String get courierAssignedSuccessfully => 'Kurye başarıyla atandı';

  @override
  String get enterValidNumber => 'Geçerli bir sayı gir';

  @override
  String profileUpdateFailed(Object error) {
    return 'Profil güncellenemedi: $error';
  }

  @override
  String get availabilityConditions => 'Müsaitlik Koşulları';

  @override
  String get whenConditionsMetCanReceiveOrders =>
      'Aşağıdaki şartlar sağlandığında yeni sipariş atanabilir:';

  @override
  String get statusMustBeAvailable => 'Durumun \"Available / Müsait\" olmalı';

  @override
  String activeOrdersBelowLimit(Object current, Object max) {
    return 'Aktif sipariş sayın, maksimum limitin altında olmalı ($current / $max)';
  }

  @override
  String get courierAccountMustBeActive => 'Kurye hesabın aktif olmalı';

  @override
  String get currentlyBlockingReasons => 'Şu anda engelleyen nedenler';

  @override
  String get everythingLooksGood =>
      'Her şey yolunda görünüyor, yeni siparişler gelebilir';

  @override
  String get available => 'Müsait';

  @override
  String get notAvailable => 'Müsait Değil';

  @override
  String get earningsTitle => 'Kazançlar';

  @override
  String get todayEarnings => 'Bugün';

  @override
  String get thisWeek => 'Bu Hafta';

  @override
  String get thisMonth => 'Bu Ay';

  @override
  String get totalEarningsLabel => 'Toplam Kazanç';

  @override
  String get avgPerDelivery => 'Teslimat Başına Ortalama';

  @override
  String get history => 'Geçmiş';

  @override
  String get noEarningsForPeriod => 'Bu dönem için kazanç bulunamadı';

  @override
  String get navigationAppUpdated => 'Navigasyon uygulaması güncellendi';

  @override
  String navigationPreferenceNotSaved(Object error) {
    return 'Navigasyon tercihi kaydedilemedi: $error';
  }

  @override
  String get selectDefaultNavigationApp =>
      'Teslimat adresine giderken kullanmak istediğin varsayılan navigasyon uygulamasını seç';

  @override
  String get note => 'Not';

  @override
  String get ifAppNotInstalledSystemWillOfferAlternative =>
      'Seçtiğin uygulama cihazında yüklü değilse sistem sana uygun bir seçenek sunar';

  @override
  String get preferenceOnlyForCourierAccount =>
      'Bu tercih sadece kurye hesabın için geçerlidir';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get noNotificationsYet =>
      'Henüz bir bildirimin yok.\nSipariş hareketlerin burada görünecek';

  @override
  String get notificationsLoadFailed => 'Bildirimler yüklenemedi';

  @override
  String notificationProcessingFailed(Object error) {
    return 'Bildirim işlenemedi: $error';
  }

  @override
  String get orderDetailTitle => 'Sipariş Detayı';

  @override
  String get pickupLocation => 'Alış Konumu';

  @override
  String get deliveryLocation => 'Teslimat Konumu';

  @override
  String get orderItems => 'Sipariş Ürünleri';

  @override
  String get viewMap => 'Haritayı Görüntüle';

  @override
  String get deliveryProof => 'Teslimat Kanıtı';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get signature => 'İmza';

  @override
  String get notes => 'Notlar';

  @override
  String get notesOptional => 'Notlar (Opsiyonel)';

  @override
  String get leftAtFrontDoor => 'Kapı önüne bırakıldı, vb.';

  @override
  String get submitProofAndCompleteDelivery =>
      'Kanıt Gönder ve Teslimatı Tamamla';

  @override
  String get pleaseTakePhoto => 'Lütfen teslimatın fotoğrafını çekin';

  @override
  String get pleaseObtainSignature => 'Lütfen imza alın';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get noDeliveryHistoryYet => 'Henüz teslimat geçmişi yok';

  @override
  String get pickup => 'Alış';

  @override
  String get delivery => 'Teslimat';

  @override
  String get talabi => 'Talabi';

  @override
  String get navigate => 'Yönlendir';

  @override
  String couldNotLaunchMaps(Object error) {
    return 'Haritalar açılamadı: $error';
  }

  @override
  String get marketBannerTitle => 'Market Alışverişin\nKapında';

  @override
  String get selectCountry => 'Ülke Seçiniz';

  @override
  String get localityNeighborhood => 'Mahalle';

  @override
  String get selectCityDistrictWarning =>
      'Lütfen onaylamak için İl ve İlçe seçiniz.';

  @override
  String get passwordResetSuccess => 'Şifre başarıyla sıfırlandı';

  @override
  String get verificationCode => 'Doğrulama Kodu';

  @override
  String get verificationCodeSentDesc =>
      'Lütfen şu adrese gönderilen doğrulama kodunu girin:';

  @override
  String get createPassword => 'Yeni Şifre Oluştur';

  @override
  String get createPasswordDesc => 'Lütfen hesabınız için yeni bir şifre girin';

  @override
  String get requiredField => 'Bu alan zorunludur';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get codeExpired => 'Kodun süresi doldu.';

  @override
  String get businessType => 'İşletme Türü';

  @override
  String get businessTypeRequired => 'İşletme türü gerekli';

  @override
  String get restaurant => 'Restoran';

  @override
  String get market => 'Market';

  @override
  String get defaultError => 'Bir hata oluştu';

  @override
  String get passwordPlaceholder => '******';

  @override
  String get vehicleTypeRequired => 'Araç Tipi zorunludur';

  @override
  String get errorLoginVendorToCustomer =>
      'Satıcı hesabıyla, müşteri ekranlarına giriş yapılamaz.';

  @override
  String get errorLoginCourierToCustomer =>
      'Kurye hesabıyla, müşteri ekranlarına giriş yapılamaz.';

  @override
  String get errorLoginCustomerToVendor =>
      'Müşteri hesabıyla, satıcı ekranlarına giriş yapılamaz.';

  @override
  String get errorLoginCourierToVendor =>
      'Kurye hesabıyla, satıcı ekranlarına giriş yapılamaz.';

  @override
  String get errorLoginCustomerToCourier =>
      'Müşteri hesabıyla, kurye ekranlarına giriş yapılamaz.';

  @override
  String get errorLoginVendorToCourier =>
      'Satıcı hesabıyla, kurye ekranlarına giriş yapılamaz.';

  @override
  String get keywordTokenExpired => 'süresi';

  @override
  String get accountPendingApprovalTitle => 'Hesabınız Onay Bekliyor';

  @override
  String get accountPendingApprovalMessage =>
      'Hesabınız şu anda incelenmektedir. Onaylandıktan sonra erişiminiz açılacaktır.';

  @override
  String get vendorStatusNormal => 'Normal';

  @override
  String get vendorStatusBusy => 'Yoğun';

  @override
  String get vendorStatusOverloaded => 'Çok Yoğun';

  @override
  String get vendorStatusNormalDesc => 'Standart süre';

  @override
  String get vendorStatusBusyDesc => '+15 dk';

  @override
  String get vendorStatusOverloadedDesc => '+45 dk';

  @override
  String get storeStatus => 'Mağaza Durumu';

  @override
  String get workingHoursRequired => 'Çalışma Saatleri Zorunludur';

  @override
  String get workingHoursRequiredDescription =>
      'Sipariş almaya başlamak için lütfen çalışma saatlerinizi belirleyin.';

  @override
  String get workingHoursStart => 'Başlangıç Saati';

  @override
  String get workingHoursEnd => 'Bitiş Saati';

  @override
  String get selectTime => 'Saat Seçin';

  @override
  String get workingHoursUpdatedSuccessfully =>
      'Çalışma saatleri başarıyla güncellendi';

  @override
  String get failedToUpdateWorkingHours => 'Çalışma saatleri güncellenemedi';

  @override
  String get workingHours => 'Çalışma Saatleri';

  @override
  String get workingDays => 'Çalışma Günleri';

  @override
  String get closed => 'Kapalı';

  @override
  String get open24Hours => '24 Saat Açık';

  @override
  String get hours => 'Saat';

  @override
  String get workingHoursDescription =>
      'İşletmenizin açık olduğu günleri ve saatleri buradan düzenleyebilirsiniz.';

  @override
  String workingHoursSaveError(Object error) {
    return 'Çalışma saatleri kaydedilirken hata oluştu: $error';
  }

  @override
  String get shamCashAccountNumber => 'Sham Cash Hesap Numarası';

  @override
  String get newOffers => 'YENİ TEKLİFLER';

  @override
  String get activeDeliveriesSectionTitle => 'AKTİF TESLİMATLAR';

  @override
  String get newOrderOffer => 'Yeni Sipariş Teklifi!';

  @override
  String get viewableAfterAcceptance =>
      'Sipariş kabul edildikten sonra görüntülenebilir';

  @override
  String get rejectReasonLabel => 'Lütfen reddetme sebebini belirtin:';

  @override
  String get pleaseEnterReason => 'Lütfen bir sebep girin';

  @override
  String get statusAssigned => 'Atandı';

  @override
  String get statusAccepted => 'Kabul Edildi';

  @override
  String get statusRejected => 'Reddedildi';

  @override
  String get statusPickedUp => 'Teslim Alındı';

  @override
  String get statusOutForDelivery => 'Yolda';

  @override
  String get statusDelivered => 'Teslim Edildi';

  @override
  String get rateOrder => 'Siparişi Değerlendir';

  @override
  String get rateCourier => 'Kurye Puanı';

  @override
  String get feedbackSubmittedSuccessfully =>
      'Değerlendirme başarıyla gönderildi';

  @override
  String get orderNotDelivered => 'Sipariş teslim edilmedi';

  @override
  String get orderAlreadyReviewed =>
      'Bu sipariş için zaten değerlendirme yapıldı';

  @override
  String get popupTitle => 'Siparişi Değerlendir';

  @override
  String get popupMessage =>
      'Son siparişin nasıldı? Deneyimini paylaşmak ister misin?';

  @override
  String get notNow => 'Şimdi Değil';

  @override
  String get viewReviews => 'Değerlendirmemi Gör';

  @override
  String get reviewDetail => 'Değerlendirme Detayı';

  @override
  String get status => 'Durum';

  @override
  String get transactionDeposit => 'Para Yatırma';

  @override
  String get transactionWithdrawal => 'Para Çekme';

  @override
  String get transactionPayment => 'Ödeme';

  @override
  String get transactionRefund => 'İade';

  @override
  String get transactionEarning => 'Kazanç';

  @override
  String get transactionDetail => 'İşlem Detayı';

  @override
  String get viewOrder => 'Siparişi Görüntüle';

  @override
  String get transactionType => 'İşlem Tipi';

  @override
  String get referenceNo => 'Referans No';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get amountToWithdraw => 'Çekilecek Tutar';

  @override
  String get all => 'Tümü';

  @override
  String get balance => 'Bakiye';

  @override
  String get savedAccounts => 'Kayıtlı Hesaplar';

  @override
  String get addAccount => 'Hesap Ekle';

  @override
  String get accountName => 'Hesap Adı';

  @override
  String get ibanOrAccountNumber => 'IBAN veya Hesap Numarası';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get areYouSure => 'Emin misiniz?';

  @override
  String get editAccount => 'Hesabı Düzenle';

  @override
  String get selectAccount => 'Hesap Seçin';

  @override
  String get accountNameRequired => 'Hesap adı gerekli';

  @override
  String get ibanRequired => 'IBAN/Hesap numarası gerekli';

  @override
  String get noSavedAccounts => 'Henüz kayıtlı hesap yok';

  @override
  String get withdrawalRequests => 'Para Çekme Talepleri';

  @override
  String get vendorProductFormOptionsTitle => 'Seçenekler ve Ekstralar';

  @override
  String get vendorProductFormNoOptions => 'Henüz seçenek eklenmemiş.';

  @override
  String get vendorProductFormAddGroup => 'Grup Ekle';

  @override
  String get vendorProductFormEditGroup => 'Grubu Düzenle';

  @override
  String get vendorProductFormGroupNameLabel => 'Grup Adı (Örn: Boyut, Soslar)';

  @override
  String get vendorProductFormRequiredLabel => 'Zorunlu Seçim';

  @override
  String get vendorProductFormMultiSelectLabel => 'Çoklu Seçim';

  @override
  String get vendorProductFormSingleSelectLabel => 'Tekli Seçim';

  @override
  String get vendorProductFormRequired => 'Zorunlu';

  @override
  String get vendorProductFormOptional => 'Opsiyonel';

  @override
  String get vendorProductFormAddOption => 'Yeni Seçenek Ekle';

  @override
  String get vendorProductFormCategoryRequired => 'Kategori seçimi zorunludur';

  @override
  String get vendorProductFormCurrencyLabel => 'Para Birimi';

  @override
  String get vendorProductFormPriceAdjustment => 'Fiyat Ayarlaması';

  @override
  String get vendorProductFormMinSelection => 'Min Seçim';

  @override
  String get vendorProductFormMaxSelection => 'Max Seçim (0 = Sınırsız)';

  @override
  String get vendorProductFormAddOptionTitle => 'Seçenek Ekle';

  @override
  String get vendorProductFormEditOptionTitle => 'Seçeneği Düzenle';

  @override
  String get vendorProductFormOptionNameLabel =>
      'Seçenek Adı (Örn: Büyük, Acı Sos)';

  @override
  String get vendorProductFormDefaultSelected => 'Varsayılan Seçili';

  @override
  String get productOptionsTitle => 'Seçenekler';

  @override
  String optionSelectionRequired(String name) {
    return '$name seçimi zorunludur.';
  }

  @override
  String get allReviews => 'Tüm Değerlendirmeler';

  @override
  String get selectOption => 'Seçiniz';

  @override
  String get ratingsLabel => 'puan';

  @override
  String get commentsLabel => 'yorum';

  @override
  String get sellerLabel => 'Satıcı';

  @override
  String get deliveryTimeRange => '10 - 20 dk';

  @override
  String allReviewCount(int count) {
    return 'Tüm Değerlendirmeler ($count)';
  }

  @override
  String get deleteAccountSuccess => 'Hesabınız başarıyla silindi.';

  @override
  String get deleteMyAccount => 'Hesabımı Kalıcı Olarak Sil';

  @override
  String get deleteMyAccountConfirmationTitle =>
      'Hesabınızı Silmek İstediğinize Emin Misiniz?';

  @override
  String get deleteMyAccountConfirmationMessage =>
      'Bu işlem geri alınamaz. Tüm verileriniz kalıcı olarak silinecektir. Devam etmek istiyor musunuz?';

  @override
  String get imprint => 'Künye ve İletişim';

  @override
  String get companyTitle => 'Firma Ünvanı';

  @override
  String get mersisNo => 'MERSİS No';

  @override
  String get contactEmail => 'İletişim E-postası';

  @override
  String get contactPhone => 'İletişim Telefonu';

  @override
  String get officialAddress => 'Resmi Adres';
}

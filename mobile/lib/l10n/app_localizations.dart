import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Talabi'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @turkishLira.
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira'**
  String get turkishLira;

  /// No description provided for @tether.
  ///
  /// In en, this message translates to:
  /// **'Tether'**
  String get tether;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @orderDetail.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetail;

  /// No description provided for @deliveryTracking.
  ///
  /// In en, this message translates to:
  /// **'Delivery Tracking'**
  String get deliveryTracking;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @regionalSettings.
  ///
  /// In en, this message translates to:
  /// **'Regional Settings'**
  String get regionalSettings;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @timeZone.
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get timeZone;

  /// No description provided for @hour24.
  ///
  /// In en, this message translates to:
  /// **'24 Hour'**
  String get hour24;

  /// No description provided for @hour12.
  ///
  /// In en, this message translates to:
  /// **'12 Hour'**
  String get hour12;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit business name, address and contact information'**
  String get editProfileDescription;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @favoriteProducts.
  ///
  /// In en, this message translates to:
  /// **'Favorite Products'**
  String get favoriteProducts;

  /// No description provided for @popularProducts.
  ///
  /// In en, this message translates to:
  /// **'Popular Products'**
  String get popularProducts;

  /// No description provided for @popularVendors.
  ///
  /// In en, this message translates to:
  /// **'Popular Businesses'**
  String get popularVendors;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @productDetail.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get productDetail;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'To keep connected with us please login with your personal info'**
  String get loginDescription;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me?'**
  String get rememberMe;

  /// No description provided for @recoveryPassword.
  ///
  /// In en, this message translates to:
  /// **'Recovery Password'**
  String get recoveryPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started with Talabi'**
  String get registerDescription;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'E-posta gerekli'**
  String get emailRequired;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Geçerli bir e-posta girin'**
  String get validEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Şifre gerekli'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Şifre en az 6 karakter olmalı'**
  String get passwordMinLength;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Ad soyad gerekli'**
  String get fullNameRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Giriş başarısız'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Kayıt başarısız'**
  String get registerFailed;

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordReset;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget Password'**
  String get forgetPassword;

  /// No description provided for @forgetPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email account to reset password'**
  String get forgetPasswordDescription;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email has been sent to your email address'**
  String get passwordResetEmailSent;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email'**
  String get passwordResetFailed;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @emailVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification link to your email address. Please check your inbox and click the link to verify your account.'**
  String get emailVerificationDescription;

  /// No description provided for @iHaveVerified.
  ///
  /// In en, this message translates to:
  /// **'I Have Verified'**
  String get iHaveVerified;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resendFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Resend feature coming soon'**
  String get resendFeatureComingSoon;

  /// No description provided for @pleaseVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address.'**
  String get pleaseVerifyEmail;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Some features may be limited'**
  String get offlineModeDescription;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility & Display'**
  String get accessibilityTitle;

  /// No description provided for @accessibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize themes, contrast and text size for better readability'**
  String get accessibilityDescription;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for low light environments'**
  String get darkModeDescription;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better visibility'**
  String get highContrastDescription;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @textSizeDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size for better readability'**
  String get textSizeDescription;

  /// No description provided for @textSizePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview Text'**
  String get textSizePreview;

  /// No description provided for @cartEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyMessage;

  /// No description provided for @cartVoucherPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your voucher code'**
  String get cartVoucherPlaceholder;

  /// No description provided for @cartSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotalLabel;

  /// No description provided for @cartDeliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get cartDeliveryFeeLabel;

  /// No description provided for @cartTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get cartTotalAmountLabel;

  /// No description provided for @cartSameVendorWarning.
  ///
  /// In en, this message translates to:
  /// **'All items in the cart must be from the same vendor'**
  String get cartSameVendorWarning;

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Received!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order number: {orderId}\\nTotal: {total}'**
  String orderPlacedMessage(Object orderId, Object total);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(Object error);

  /// No description provided for @clearCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCartTitle;

  /// No description provided for @clearCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove all items from the cart?'**
  String get clearCartMessage;

  /// No description provided for @clearCartNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get clearCartNo;

  /// No description provided for @clearCartYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get clearCartYes;

  /// No description provided for @clearCartSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared successfully'**
  String get clearCartSuccess;

  /// No description provided for @productByVendor.
  ///
  /// In en, this message translates to:
  /// **'By {vendorName}'**
  String productByVendor(Object vendorName);

  /// No description provided for @alreadyReviewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get alreadyReviewedTitle;

  /// No description provided for @alreadyReviewedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this product.'**
  String get alreadyReviewedMessage;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @courierLogin.
  ///
  /// In en, this message translates to:
  /// **'Courier Login'**
  String get courierLogin;

  /// No description provided for @courierWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Courier!'**
  String get courierWelcome;

  /// No description provided for @courierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your deliveries'**
  String get courierSubtitle;

  /// No description provided for @areYouCourier.
  ///
  /// In en, this message translates to:
  /// **'Are you a courier?'**
  String get areYouCourier;

  /// No description provided for @courierSignIn.
  ///
  /// In en, this message translates to:
  /// **'Courier Sign In'**
  String get courierSignIn;

  /// No description provided for @courierLoginLink.
  ///
  /// In en, this message translates to:
  /// **'Courier Login'**
  String get courierLoginLink;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get roleVendor;

  /// No description provided for @roleCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get roleCourier;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @activeDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Active Deliveries'**
  String get activeDeliveries;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @noActiveDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No active deliveries'**
  String get noActiveDeliveries;

  /// No description provided for @courierProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Courier profile not found'**
  String get courierProfileNotFound;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @invalidStatus.
  ///
  /// In en, this message translates to:
  /// **'Invalid status. Valid values: Offline, Available, Busy, Break, Assigned'**
  String get invalidStatus;

  /// No description provided for @cannotGoAvailableOutsideWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Cannot go available outside working hours'**
  String get cannotGoAvailableOutsideWorkingHours;

  /// No description provided for @cannotGoOfflineWithActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Cannot go offline with active orders'**
  String get cannotGoOfflineWithActiveOrders;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @locationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdatedSuccessfully;

  /// No description provided for @invalidLatitude.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude'**
  String get invalidLatitude;

  /// No description provided for @invalidLongitude.
  ///
  /// In en, this message translates to:
  /// **'Invalid longitude'**
  String get invalidLongitude;

  /// No description provided for @orderAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully'**
  String get orderAcceptedSuccessfully;

  /// No description provided for @orderRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order rejected successfully'**
  String get orderRejectedSuccessfully;

  /// No description provided for @orderPickedUpSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order picked up successfully'**
  String get orderPickedUpSuccessfully;

  /// No description provided for @orderDeliveredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order delivered successfully'**
  String get orderDeliveredSuccessfully;

  /// No description provided for @deliveryProofSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Delivery proof submitted successfully'**
  String get deliveryProofSubmittedSuccessfully;

  /// No description provided for @orderNotFoundOrNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Order not found or not assigned to you'**
  String get orderNotFoundOrNotAssigned;

  /// No description provided for @orderMustBeDeliveredBeforeSubmittingProof.
  ///
  /// In en, this message translates to:
  /// **'Order must be delivered before submitting proof'**
  String get orderMustBeDeliveredBeforeSubmittingProof;

  /// No description provided for @failedToAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order. It might be already taken or cancelled'**
  String get failedToAcceptOrder;

  /// No description provided for @failedToRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject order'**
  String get failedToRejectOrder;

  /// No description provided for @failedToPickUpOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick up order'**
  String get failedToPickUpOrder;

  /// No description provided for @failedToDeliverOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to deliver order'**
  String get failedToDeliverOrder;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load courier profile'**
  String get failedToLoadProfile;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @failedToUpdateLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to update location'**
  String get failedToUpdateLocation;

  /// No description provided for @failedToLoadStatistics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStatistics;

  /// No description provided for @failedToLoadActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load active orders'**
  String get failedToLoadActiveOrders;

  /// No description provided for @failedToLoadOrderDetail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order detail'**
  String get failedToLoadOrderDetail;

  /// No description provided for @failedToLoadTodayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load today earnings'**
  String get failedToLoadTodayEarnings;

  /// No description provided for @failedToLoadWeeklyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load weekly earnings'**
  String get failedToLoadWeeklyEarnings;

  /// No description provided for @failedToLoadMonthlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load monthly earnings'**
  String get failedToLoadMonthlyEarnings;

  /// No description provided for @failedToLoadEarningsHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load earnings history'**
  String get failedToLoadEarningsHistory;

  /// No description provided for @failedToSubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit proof'**
  String get failedToSubmitProof;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @noFileUploaded.
  ///
  /// In en, this message translates to:
  /// **'No file uploaded'**
  String get noFileUploaded;

  /// No description provided for @internalServerErrorDuringUpload.
  ///
  /// In en, this message translates to:
  /// **'Internal server error during upload'**
  String get internalServerErrorDuringUpload;

  /// No description provided for @checkAvailability.
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get checkAvailability;

  /// No description provided for @businessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// No description provided for @businessActive.
  ///
  /// In en, this message translates to:
  /// **'Business Active'**
  String get businessActive;

  /// No description provided for @customersCanPlaceOrders.
  ///
  /// In en, this message translates to:
  /// **'Customers can place orders'**
  String get customersCanPlaceOrders;

  /// No description provided for @orderTakingClosed.
  ///
  /// In en, this message translates to:
  /// **'Order taking is closed'**
  String get orderTakingClosed;

  /// No description provided for @businessOperations.
  ///
  /// In en, this message translates to:
  /// **'Business Operations'**
  String get businessOperations;

  /// No description provided for @minimumOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Amount'**
  String get minimumOrderAmount;

  /// No description provided for @estimatedDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery Time (minutes)'**
  String get estimatedDeliveryTime;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @enterValidTime.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid time'**
  String get enterValidTime;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @addressRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Required'**
  String get addressRequiredTitle;

  /// No description provided for @addressRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to add a delivery address before placing an order.'**
  String get addressRequiredMessage;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

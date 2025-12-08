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

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

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

  /// No description provided for @selectCurrencyDescription.
  ///
  /// In en, this message translates to:
  /// **'Currency selection'**
  String get selectCurrencyDescription;

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

  /// No description provided for @editCourierProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit name, phone, vehicle information and working hours'**
  String get editCourierProfileDescription;

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
  /// **'Welcome!'**
  String get welcomeBack;

  /// No description provided for @loginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to place orders and track them in real-time'**
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
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
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

  /// No description provided for @verificationEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email has been resent'**
  String get verificationEmailResent;

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
  /// **'Your order number: {orderId}\nTotal: {total}'**
  String orderPlacedMessage(Object orderId, Object total);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @duplicateEmail.
  ///
  /// In en, this message translates to:
  /// **'An account with this email address already exists.'**
  String get duplicateEmail;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Google login failed: {error}'**
  String googleLoginFailed(Object error);

  /// No description provided for @appleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple login failed: {error}'**
  String appleLoginFailed(Object error);

  /// No description provided for @facebookLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Facebook login failed: {error}'**
  String facebookLoginFailed(Object error);

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

  /// No description provided for @areYouVendor.
  ///
  /// In en, this message translates to:
  /// **'Are you a vendor? '**
  String get areYouVendor;

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
  /// **'Failed to load courier profile: {error}'**
  String failedToLoadProfile(Object error);

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

  /// No description provided for @addressRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'You must add at least one address to place orders. Please add your address.'**
  String get addressRequiredDescription;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @legalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get legalDocuments;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get refundPolicy;

  /// No description provided for @distanceSalesAgreement.
  ///
  /// In en, this message translates to:
  /// **'Distance Sales Agreement'**
  String get distanceSalesAgreement;

  /// No description provided for @loadingContent.
  ///
  /// In en, this message translates to:
  /// **'Loading content...'**
  String get loadingContent;

  /// No description provided for @contentNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Content not available'**
  String get contentNotAvailable;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @profileImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Profile Image URL'**
  String get profileImageUrl;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String profileLoadFailed(Object error);

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings'**
  String get settingsUpdateFailed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @promotionalNotifications.
  ///
  /// In en, this message translates to:
  /// **'Promotional Notifications'**
  String get promotionalNotifications;

  /// No description provided for @newProducts.
  ///
  /// In en, this message translates to:
  /// **'New Products'**
  String get newProducts;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @accessibilityAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Accessibility & Display'**
  String get accessibilityAndDisplay;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @available24x7.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get available24x7;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get logoutConfirmMessage;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get changePasswordDescription;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation is required'**
  String get confirmPasswordRequired;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureYourAccount;

  /// No description provided for @addressesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load addresses'**
  String get addressesLoadFailed;

  /// No description provided for @deleteAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddressTitle;

  /// No description provided for @deleteAddressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get deleteAddressConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @defaultAddressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default address updated'**
  String get defaultAddressUpdated;

  /// No description provided for @manageDeliveryAddresses.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery addresses'**
  String get manageDeliveryAddresses;

  /// No description provided for @noAddressesYet.
  ///
  /// In en, this message translates to:
  /// **'No addresses yet'**
  String get noAddressesYet;

  /// No description provided for @tapToAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Tap + button to add a new address'**
  String get tapToAddAddress;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @addressCountSingular.
  ///
  /// In en, this message translates to:
  /// **'1 address'**
  String get addressCountSingular;

  /// No description provided for @addressCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} addresses'**
  String addressCountPlural(Object count);

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @addressTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Address Title (Optional)'**
  String get addressTitleOptional;

  /// No description provided for @canBeLeftEmpty.
  ///
  /// In en, this message translates to:
  /// **'Can be left empty'**
  String get canBeLeftEmpty;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @selectOrDragMarkerOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select a location on the map or drag the marker'**
  String get selectOrDragMarkerOnMap;

  /// No description provided for @saveAddressButton.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddressButton;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddress;

  /// No description provided for @selectLocationFromMap.
  ///
  /// In en, this message translates to:
  /// **'Select location from map'**
  String get selectLocationFromMap;

  /// No description provided for @addressAdded.
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @updateAddressInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your address information'**
  String get updateAddressInfo;

  /// No description provided for @enterDeliveryAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your delivery address details'**
  String get enterDeliveryAddressDetails;

  /// No description provided for @addressTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Address Title (Home, Work, etc.)'**
  String get addressTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @selectAddressFromMap.
  ///
  /// In en, this message translates to:
  /// **'Select Address from Map'**
  String get selectAddressFromMap;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @districtRequired.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// No description provided for @postalCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Postal Code (Optional)'**
  String get postalCodeOptional;

  /// No description provided for @updateAddressButton.
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get updateAddressButton;

  /// No description provided for @updateAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Update address details'**
  String get updateAddressDetails;

  /// No description provided for @createNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Create new address'**
  String get createNewAddress;

  /// No description provided for @orderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Order Updates'**
  String get orderUpdates;

  /// No description provided for @orderUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when your order status changes'**
  String get orderUpdatesDescription;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @promotionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Special offers and promotions'**
  String get promotionsDescription;

  /// No description provided for @newProductsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when new products are added'**
  String get newProductsDescription;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @regionalSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Date and time settings'**
  String get regionalSettingsDescription;

  /// No description provided for @timeZoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Europe/Istanbul, America/New_York'**
  String get timeZoneHint;

  /// No description provided for @manageNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get manageNotificationPreferences;

  /// No description provided for @orderHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'View your past orders'**
  String get orderHistoryDescription;

  /// No description provided for @myAddressesDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery addresses'**
  String get myAddressesDescription;

  /// No description provided for @myFavoriteProducts.
  ///
  /// In en, this message translates to:
  /// **'My Favorite Products'**
  String get myFavoriteProducts;

  /// No description provided for @myFavoriteProductsDescription.
  ///
  /// In en, this message translates to:
  /// **'View and manage your favorite products'**
  String get myFavoriteProductsDescription;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your password and enhance security'**
  String get changePasswordSubtitle;

  /// No description provided for @notificationSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get notificationSettingsDescription;

  /// No description provided for @selectLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Change application language'**
  String get selectLanguageDescription;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get selectLanguageSubtitle;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @languagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} languages'**
  String languagesCount(Object count);

  /// No description provided for @legalDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Terms of use and policies'**
  String get legalDocumentsDescription;

  /// No description provided for @helpCenterDescription.
  ///
  /// In en, this message translates to:
  /// **'FAQ and support line'**
  String get helpCenterDescription;

  /// No description provided for @logoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get logoutDescription;

  /// No description provided for @vendorRegister.
  ///
  /// In en, this message translates to:
  /// **'Vendor Registration'**
  String get vendorRegister;

  /// No description provided for @talabiBusiness.
  ///
  /// In en, this message translates to:
  /// **'Talabi Business'**
  String get talabiBusiness;

  /// No description provided for @createBusinessAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Business Account'**
  String get createBusinessAccount;

  /// No description provided for @createYourStoreAndStartSelling.
  ///
  /// In en, this message translates to:
  /// **'Create your store and start selling'**
  String get createYourStoreAndStartSelling;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @createVendorAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Vendor Account'**
  String get createVendorAccount;

  /// No description provided for @alreadyHaveVendorAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have a vendor account? '**
  String get alreadyHaveVendorAccount;

  /// No description provided for @isCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Customer account? '**
  String get isCustomerAccount;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailAlreadyExists;

  /// No description provided for @enterFourDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 4-digit code'**
  String get enterFourDigitCode;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email address verified successfully'**
  String get emailVerifiedSuccess;

  /// No description provided for @emailVerifiedLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Email verified but auto-login failed. Please login manually.'**
  String get emailVerifiedLoginFailed;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent'**
  String get verificationCodeResent;

  /// No description provided for @codeSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get codeSendFailed;

  /// No description provided for @fourDigitVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'4-Digit Verification Code'**
  String get fourDigitVerificationCode;

  /// No description provided for @enterCodeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code sent to {email}'**
  String enterCodeSentToEmail(Object email);

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Code will expire in {time}'**
  String codeExpiresIn(Object time);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String settingsLoadError(Object error);

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// No description provided for @reviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Review approved'**
  String get reviewApproved;

  /// No description provided for @reviewApproveError.
  ///
  /// In en, this message translates to:
  /// **'Error approving review: {error}'**
  String reviewApproveError(Object error);

  /// No description provided for @rejectReview.
  ///
  /// In en, this message translates to:
  /// **'Reject Review'**
  String get rejectReview;

  /// No description provided for @rejectReviewConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this review? This cannot be undone.'**
  String get rejectReviewConfirmation;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @reviewRejected.
  ///
  /// In en, this message translates to:
  /// **'Review rejected'**
  String get reviewRejected;

  /// No description provided for @reviewRejectError.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting review: {error}'**
  String reviewRejectError(Object error);

  /// No description provided for @reviewDetail.
  ///
  /// In en, this message translates to:
  /// **'Review Detail'**
  String get reviewDetail;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String userId(Object id);

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @noComment.
  ///
  /// In en, this message translates to:
  /// **'No comment'**
  String get noComment;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmation'**
  String get checkoutTitle;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAddress;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @mobilePayment.
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment'**
  String get mobilePayment;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @orderNote.
  ///
  /// In en, this message translates to:
  /// **'Order Note'**
  String get orderNote;

  /// No description provided for @orderNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add note for courier (optional)'**
  String get orderNotePlaceholder;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @pleaseSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery address'**
  String get pleaseSelectAddress;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @orderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your order has been created successfully!'**
  String get orderCreatedSuccess;

  /// No description provided for @noAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No address found'**
  String get noAddressFound;

  /// No description provided for @cashDescription.
  ///
  /// In en, this message translates to:
  /// **'You can pay cash to the courier at the door.'**
  String get cashDescription;

  /// No description provided for @paymentComingSoonDescription.
  ///
  /// In en, this message translates to:
  /// **'This payment method will be available soon.'**
  String get paymentComingSoonDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Shop Everything You Need'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Fresh groceries, daily essentials, and more—all in one app'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Fast & Reliable Delivery'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Track your order in real-time and get it delivered quickly'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Best Prices & Offers'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Enjoy exclusive deals and competitive prices every day'**
  String get onboardingDesc3;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @courierInformation.
  ///
  /// In en, this message translates to:
  /// **'Courier Information'**
  String get courierInformation;

  /// No description provided for @assignedAt.
  ///
  /// In en, this message translates to:
  /// **'Assigned At'**
  String get assignedAt;

  /// No description provided for @acceptedAt.
  ///
  /// In en, this message translates to:
  /// **'Accepted At'**
  String get acceptedAt;

  /// No description provided for @pickedUpAt.
  ///
  /// In en, this message translates to:
  /// **'Picked Up At'**
  String get pickedUpAt;

  /// No description provided for @outForDeliveryAt.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery At'**
  String get outForDeliveryAt;

  /// No description provided for @vendorOrders.
  ///
  /// In en, this message translates to:
  /// **'Vendor Orders'**
  String get vendorOrders;

  /// No description provided for @pendingOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending orders'**
  String pendingOrdersCount(int count);

  /// No description provided for @preparingOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} preparing orders'**
  String preparingOrdersCount(int count);

  /// No description provided for @readyOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} ready orders'**
  String readyOrdersCount(int count);

  /// No description provided for @deliveredOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders delivered'**
  String deliveredOrdersCount(int count);

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @vendorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Vendor Dashboard'**
  String get vendorDashboard;

  /// No description provided for @summaryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load summary: {error}'**
  String summaryLoadError(Object error);

  /// No description provided for @welcomeVendor.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeVendor(Object name);

  /// No description provided for @todayOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todayOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @todayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todayRevenue;

  /// No description provided for @weeklyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Weekly Revenue'**
  String get weeklyRevenue;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @logoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated'**
  String get logoUpdated;

  /// No description provided for @logoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Logo upload failed: {error}'**
  String logoUploadFailed(Object error);

  /// No description provided for @locationSelectedChange.
  ///
  /// In en, this message translates to:
  /// **'Location Selected (Change)'**
  String get locationSelectedChange;

  /// No description provided for @selectLocationFromMapRequired.
  ///
  /// In en, this message translates to:
  /// **'Select Location from Map *'**
  String get selectLocationFromMapRequired;

  /// No description provided for @locationSelectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location selection from map is required'**
  String get locationSelectionRequired;

  /// No description provided for @addressAutoFillHint.
  ///
  /// In en, this message translates to:
  /// **'Address selected from map is auto-filled, you can edit manually'**
  String get addressAutoFillHint;

  /// No description provided for @selectLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'You must select a location from map first'**
  String get selectLocationFirst;

  /// No description provided for @vendorLogin.
  ///
  /// In en, this message translates to:
  /// **'Vendor Login'**
  String get vendorLogin;

  /// No description provided for @welcomeBackVendor.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Vendor!'**
  String get welcomeBackVendor;

  /// No description provided for @vendorLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your store and orders'**
  String get vendorLoginDescription;

  /// No description provided for @areYouCustomer.
  ///
  /// In en, this message translates to:
  /// **'Are you a customer?'**
  String get areYouCustomer;

  /// No description provided for @vendorNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get vendorNotificationsTitle;

  /// No description provided for @vendorNotificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet.'**
  String get vendorNotificationsEmptyMessage;

  /// No description provided for @vendorNotificationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading notifications.'**
  String get vendorNotificationsErrorMessage;

  /// No description provided for @vendorProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get vendorProductsTitle;

  /// No description provided for @vendorProductsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get vendorProductsSearchHint;

  /// No description provided for @vendorProductsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products: {error}'**
  String vendorProductsLoadError(Object error);

  /// No description provided for @vendorProductsSetOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'{productName} set to out of stock'**
  String vendorProductsSetOutOfStock(Object productName);

  /// No description provided for @vendorProductsSetInStock.
  ///
  /// In en, this message translates to:
  /// **'{productName} is in stock'**
  String vendorProductsSetInStock(Object productName);

  /// No description provided for @vendorProductsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get vendorProductsDeleteTitle;

  /// No description provided for @vendorProductsDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {productName}?'**
  String vendorProductsDeleteConfirmation(Object productName);

  /// No description provided for @vendorProductsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'{productName} has been deleted'**
  String vendorProductsDeleteSuccess(Object productName);

  /// No description provided for @vendorProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get vendorProductsEmpty;

  /// No description provided for @vendorProductsAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Product'**
  String get vendorProductsAddFirst;

  /// No description provided for @vendorProductsAddNew.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get vendorProductsAddNew;

  /// No description provided for @vendorProductFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get vendorProductFormEditTitle;

  /// No description provided for @vendorProductFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get vendorProductFormNewTitle;

  /// No description provided for @vendorProductFormImageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get vendorProductFormImageUploaded;

  /// No description provided for @vendorProductFormImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String vendorProductFormImageUploadError(Object error);

  /// No description provided for @vendorProductFormSourceCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get vendorProductFormSourceCamera;

  /// No description provided for @vendorProductFormSourceGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get vendorProductFormSourceGallery;

  /// No description provided for @vendorProductFormCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get vendorProductFormCreateSuccess;

  /// No description provided for @vendorProductFormUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get vendorProductFormUpdateSuccess;

  /// No description provided for @vendorProductFormError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String vendorProductFormError(Object error);

  /// No description provided for @vendorProductFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get vendorProductFormNameLabel;

  /// No description provided for @vendorProductFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get vendorProductFormNameRequired;

  /// No description provided for @vendorProductFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get vendorProductFormDescriptionLabel;

  /// No description provided for @vendorProductFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get vendorProductFormCategoryLabel;

  /// No description provided for @vendorProductFormPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price *'**
  String get vendorProductFormPriceLabel;

  /// No description provided for @vendorProductFormPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get vendorProductFormPriceRequired;

  /// No description provided for @vendorProductFormPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get vendorProductFormPriceInvalid;

  /// No description provided for @vendorProductFormStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get vendorProductFormStockLabel;

  /// No description provided for @vendorProductFormInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get vendorProductFormInvalidNumber;

  /// No description provided for @vendorProductFormPreparationTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time (minutes)'**
  String get vendorProductFormPreparationTimeLabel;

  /// No description provided for @vendorProductFormInStockLabel.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get vendorProductFormInStockLabel;

  /// No description provided for @vendorProductFormInStockDescription.
  ///
  /// In en, this message translates to:
  /// **'The product will be visible to customers'**
  String get vendorProductFormInStockDescription;

  /// No description provided for @vendorProductFormOutOfStockDescription.
  ///
  /// In en, this message translates to:
  /// **'The product will be marked as out of stock'**
  String get vendorProductFormOutOfStockDescription;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @vendorProductFormAddImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get vendorProductFormAddImage;

  /// No description provided for @vendorProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My Vendor Profile'**
  String get vendorProfileTitle;

  /// No description provided for @vendorFallbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorFallbackSubtitle;

  /// No description provided for @businessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInfo;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @businessSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettingsTitle;

  /// No description provided for @businessSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum order, delivery fee, and other settings'**
  String get businessSettingsSubtitle;

  /// No description provided for @languageNameTr.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageNameTr;

  /// No description provided for @languageNameEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @languageNameAr.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageNameAr;

  /// No description provided for @businessNameFallback.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessNameFallback;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @pendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending Reviews'**
  String get pendingReviews;

  /// No description provided for @noPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'No pending reviews'**
  String get noPendingReviews;

  /// No description provided for @reviewsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews: {error}'**
  String reviewsLoadError(Object error);

  /// No description provided for @salesReports.
  ///
  /// In en, this message translates to:
  /// **'Sales Reports'**
  String get salesReports;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @noReportFound.
  ///
  /// In en, this message translates to:
  /// **'No report found'**
  String get noReportFound;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledOrders;

  /// No description provided for @dailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get dailySales;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String orderCount(Object count);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancel reason'**
  String get cancelReason;

  /// No description provided for @cancelReasonDescription.
  ///
  /// In en, this message translates to:
  /// **'Please specify your cancellation reason (at least 10 characters):'**
  String get cancelReasonDescription;

  /// Order acceptance popup title
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrderTitle;

  /// Order acceptance confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this order?'**
  String get acceptOrderConfirmation;

  /// Accept order button
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptOrder;

  /// Order status update popup title
  ///
  /// In en, this message translates to:
  /// **'Update Order Status'**
  String get updateOrderStatusTitle;

  /// Mark order as ready confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this order as \"Ready\"?'**
  String get markAsReadyConfirmation;

  /// Mark order as ready button
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get markAsReady;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @rejectOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Rejection'**
  String get rejectOrderTitle;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get rejectReason;

  /// No description provided for @rejectReasonDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter the rejection reason (at least 1 character):'**
  String get rejectReasonDescription;

  /// No description provided for @rejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason...'**
  String get rejectReasonHint;

  /// No description provided for @rejectOrderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get rejectOrderConfirmation;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @pieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get pieces;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @productsAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Products added to cart, redirecting to cart...'**
  String get productsAddedToCart;

  /// No description provided for @reorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String reorderFailed(Object error);

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionDeniedForever;

  /// No description provided for @vendorsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load vendors: {error}'**
  String vendorsLoadFailed(Object error);

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'We need your location permission to show nearby restaurants and track your orders.'**
  String get locationPermissionMessage;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @locationManagement.
  ///
  /// In en, this message translates to:
  /// **'Location Management'**
  String get locationManagement;

  /// No description provided for @currentLocationInfo.
  ///
  /// In en, this message translates to:
  /// **'Current Location Information'**
  String get currentLocationInfo;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @lastLocationUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastLocationUpdate;

  /// No description provided for @noLocationData.
  ///
  /// In en, this message translates to:
  /// **'No location data available'**
  String get noLocationData;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get selectLocationOnMap;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @updateLocation.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// No description provided for @locationSharingInfo.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is required to receive orders from nearby restaurants. Your location is automatically shared when your status is \"Available\".'**
  String get locationSharingInfo;

  /// No description provided for @locationManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'View and update your current location'**
  String get locationManagementDescription;

  /// No description provided for @vendorsMap.
  ///
  /// In en, this message translates to:
  /// **'Vendors Map'**
  String get vendorsMap;

  /// No description provided for @findMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Find My Location'**
  String get findMyLocation;

  /// No description provided for @viewProducts.
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get viewProducts;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search error: {error}'**
  String searchError(Object error);

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String productAddedToCart(Object productName);

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get selectCity;

  /// No description provided for @minimumRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// No description provided for @maximumDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance (km)'**
  String get maximumDistance;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @selectSortBy.
  ///
  /// In en, this message translates to:
  /// **'Select sort by'**
  String get selectSortBy;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price (Low to High)'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price (High to Low)'**
  String get priceHighToLow;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @ratingHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Rating (High to Low)'**
  String get ratingHighToLow;

  /// No description provided for @popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @searchProductsOrVendors.
  ///
  /// In en, this message translates to:
  /// **'Search products or vendors...'**
  String get searchProductsOrVendors;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type in the box above to search'**
  String get typeToSearch;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City: {city}'**
  String cityLabel(Object city);

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String distanceLabel(Object distance);

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'{productName} removed from favorites'**
  String removedFromFavorites(Object productName);

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to favorites'**
  String addedToFavorites(Object productName);

  /// No description provided for @favoriteOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Favorite operation failed: {error}'**
  String favoriteOperationFailed(Object error);

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet.'**
  String get noProductsYet;

  /// No description provided for @productLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load product: {error}'**
  String productLoadFailed(Object error);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @rateVendor.
  ///
  /// In en, this message translates to:
  /// **'Rate Vendor'**
  String get rateVendor;

  /// No description provided for @shareYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get shareYourThoughts;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @vendorReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Vendor review submitted!'**
  String get vendorReviewSubmitted;

  /// No description provided for @productReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Product review submitted!'**
  String get productReviewSubmitted;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryType;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String reviews(Object count);

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to review!'**
  String get noReviewsYet;

  /// No description provided for @seeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'See All Reviews'**
  String get seeAllReviews;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By {vendorName}'**
  String by(Object vendorName);

  /// No description provided for @orderCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your Order Has Been Created Successfully!'**
  String get orderCreatedSuccessfully;

  /// No description provided for @orderCode.
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get orderCode;

  /// No description provided for @orderPreparationStarted.
  ///
  /// In en, this message translates to:
  /// **'Your order has started being prepared. You can track your order status from the \"My Orders\" page.'**
  String get orderPreparationStarted;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePage;

  /// No description provided for @ordersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String ordersLoadFailed(Object error);

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @onWay.
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get onWay;

  /// No description provided for @unknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Vendor'**
  String get unknownVendor;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @cancelItem.
  ///
  /// In en, this message translates to:
  /// **'Cancel Item'**
  String get cancelItem;

  /// No description provided for @itemCancelled.
  ///
  /// In en, this message translates to:
  /// **'Item Cancelled'**
  String get itemCancelled;

  /// No description provided for @itemCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item cancelled successfully'**
  String get itemCancelSuccess;

  /// No description provided for @itemCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel item: {error}'**
  String itemCancelFailed(Object error);

  /// No description provided for @promotionalBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hungry?\nWe’ve got you covered!'**
  String get promotionalBannerTitle;

  /// No description provided for @promotionalBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free delivery, low fees & 10% cashback!'**
  String get promotionalBannerSubtitle;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoryNotFound;

  /// No description provided for @picksForYou.
  ///
  /// In en, this message translates to:
  /// **'Picks For You'**
  String get picksForYou;

  /// No description provided for @addressUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Address update failed: {error}'**
  String addressUpdateFailed(Object error);

  /// No description provided for @unreadNotificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread notifications'**
  String unreadNotificationsCount(Object count);

  /// No description provided for @campaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaigns;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsCount(Object count);

  /// No description provided for @campaignsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} campaigns'**
  String campaignsCount(Object count);

  /// No description provided for @vendorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} businesses'**
  String vendorsCount(Object count);

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// No description provided for @areYouHungry.
  ///
  /// In en, this message translates to:
  /// **'Are you Hungry?'**
  String get areYouHungry;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Request what you need, and we\'ll deliver it to you as fast as possible.\nOrdering with Talabi is now as easy as a single touch.'**
  String get onboardingDescription;

  /// No description provided for @unlockDescription.
  ///
  /// In en, this message translates to:
  /// **'Slide to Talabî!'**
  String get unlockDescription;

  /// No description provided for @addAddressToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add address to order'**
  String get addAddressToOrder;

  /// No description provided for @createCourierAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Courier Account'**
  String get createCourierAccount;

  /// No description provided for @startDeliveringToday.
  ///
  /// In en, this message translates to:
  /// **'Start delivering today and earn money'**
  String get startDeliveringToday;

  /// No description provided for @alreadyHaveCourierAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have a courier account? '**
  String get alreadyHaveCourierAccount;

  /// No description provided for @courierRegister.
  ///
  /// In en, this message translates to:
  /// **'Courier Register'**
  String get courierRegister;

  /// No description provided for @talabiCourier.
  ///
  /// In en, this message translates to:
  /// **'Talabi Courier'**
  String get talabiCourier;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @markAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get markAsPickedUp;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAccepted;

  /// No description provided for @orderMarkedAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order marked as picked up'**
  String get orderMarkedAsPickedUp;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get orderDelivered;

  /// No description provided for @actionCouldNotBeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Action could not be completed'**
  String get actionCouldNotBeCompleted;

  /// No description provided for @cannotChangeStatusWhileBusy.
  ///
  /// In en, this message translates to:
  /// **'Cannot change status while busy'**
  String get cannotChangeStatusWhileBusy;

  /// No description provided for @newOrderAssigned.
  ///
  /// In en, this message translates to:
  /// **'New order #{orderId} assigned!'**
  String newOrderAssigned(Object orderId);

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @availabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// No description provided for @checkNewOrderConditions.
  ///
  /// In en, this message translates to:
  /// **'Check new order receiving conditions here'**
  String get checkNewOrderConditions;

  /// No description provided for @navigationApp.
  ///
  /// In en, this message translates to:
  /// **'Navigation App'**
  String get navigationApp;

  /// No description provided for @selectPreferredNavigationApp.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred navigation app'**
  String get selectPreferredNavigationApp;

  /// No description provided for @noVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'No vehicle information'**
  String get noVehicleInfo;

  /// No description provided for @cannotChangeStatusWithActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Cannot change status with active orders'**
  String get cannotChangeStatusWithActiveOrders;

  /// No description provided for @cannotGoOfflineUntilOrdersCompleted.
  ///
  /// In en, this message translates to:
  /// **'Cannot go offline until active orders are completed'**
  String get cannotGoOfflineUntilOrdersCompleted;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @courierSettings.
  ///
  /// In en, this message translates to:
  /// **'Courier Settings'**
  String get courierSettings;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @maxActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Max Active Orders'**
  String get maxActiveOrders;

  /// No description provided for @useWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Use working hours'**
  String get useWorkingHours;

  /// No description provided for @onlyAvailableDuringSetHours.
  ///
  /// In en, this message translates to:
  /// **'You can only be \"Available\" during the hours you set'**
  String get onlyAvailableDuringSetHours;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @mustSelectStartAndEndTime.
  ///
  /// In en, this message translates to:
  /// **'You must select start and end time for working hours'**
  String get mustSelectStartAndEndTime;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @mustSelectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'You must select a vehicle type'**
  String get mustSelectVehicleType;

  /// No description provided for @selectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// No description provided for @selectVehicleTypeDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select the vehicle type you will use. This selection is required.'**
  String get selectVehicleTypeDescription;

  /// No description provided for @motorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @bicycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get bicycle;

  /// No description provided for @vehicleTypeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type updated successfully'**
  String get vehicleTypeUpdatedSuccessfully;

  /// No description provided for @failedToUpdateVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Failed to update vehicle type'**
  String get failedToUpdateVehicleType;

  /// No description provided for @selectLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Selection Required'**
  String get selectLocationRequired;

  /// No description provided for @selectLocationRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'Please select your location. This information is required to receive orders.'**
  String get selectLocationRequiredDescription;

  /// No description provided for @selectFromMap.
  ///
  /// In en, this message translates to:
  /// **'Select from Map'**
  String get selectFromMap;

  /// No description provided for @gettingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingCurrentLocation;

  /// No description provided for @locationServicesDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get locationServicesDisabledTitle;

  /// No description provided for @locationServicesDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable location services in settings.'**
  String get locationServicesDisabledMessage;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @assignCourierConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Courier Assignment'**
  String get assignCourierConfirmationTitle;

  /// No description provided for @assignCourierConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to assign this order to {courierName}?'**
  String assignCourierConfirmationMessage(String courierName);

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @courierAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Courier assigned successfully'**
  String get courierAssignedSuccessfully;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile update failed: {error}'**
  String profileUpdateFailed(Object error);

  /// No description provided for @availabilityConditions.
  ///
  /// In en, this message translates to:
  /// **'Availability Conditions'**
  String get availabilityConditions;

  /// No description provided for @whenConditionsMetCanReceiveOrders.
  ///
  /// In en, this message translates to:
  /// **'The following conditions must be met to receive new orders:'**
  String get whenConditionsMetCanReceiveOrders;

  /// No description provided for @statusMustBeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your status must be \"Available\"'**
  String get statusMustBeAvailable;

  /// No description provided for @activeOrdersBelowLimit.
  ///
  /// In en, this message translates to:
  /// **'Your active orders must be below your maximum limit ({current} / {max})'**
  String activeOrdersBelowLimit(Object current, Object max);

  /// No description provided for @courierAccountMustBeActive.
  ///
  /// In en, this message translates to:
  /// **'Your courier account must be active'**
  String get courierAccountMustBeActive;

  /// No description provided for @currentlyBlockingReasons.
  ///
  /// In en, this message translates to:
  /// **'Currently blocking reasons'**
  String get currentlyBlockingReasons;

  /// No description provided for @everythingLooksGood.
  ///
  /// In en, this message translates to:
  /// **'Everything looks good, new orders may arrive'**
  String get everythingLooksGood;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @todayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayEarnings;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @totalEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarningsLabel;

  /// No description provided for @avgPerDelivery.
  ///
  /// In en, this message translates to:
  /// **'Avg. per Delivery'**
  String get avgPerDelivery;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noEarningsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No earnings found for this period'**
  String get noEarningsForPeriod;

  /// No description provided for @navigationAppUpdated.
  ///
  /// In en, this message translates to:
  /// **'Navigation app updated'**
  String get navigationAppUpdated;

  /// No description provided for @navigationPreferenceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Navigation preference could not be saved: {error}'**
  String navigationPreferenceNotSaved(Object error);

  /// No description provided for @selectDefaultNavigationApp.
  ///
  /// In en, this message translates to:
  /// **'Select the default navigation app you want to use when going to delivery address'**
  String get selectDefaultNavigationApp;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @ifAppNotInstalledSystemWillOfferAlternative.
  ///
  /// In en, this message translates to:
  /// **'If the app you selected is not installed, the system will offer you a suitable alternative'**
  String get ifAppNotInstalledSystemWillOfferAlternative;

  /// No description provided for @preferenceOnlyForCourierAccount.
  ///
  /// In en, this message translates to:
  /// **'This preference is only valid for your courier account'**
  String get preferenceOnlyForCourierAccount;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any notifications yet.\nOrder movements will appear here'**
  String get noNotificationsYet;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification processing failed: {error}'**
  String notificationProcessingFailed(Object error);

  /// No description provided for @orderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetailTitle;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @deliveryProof.
  ///
  /// In en, this message translates to:
  /// **'Delivery Proof'**
  String get deliveryProof;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @leftAtFrontDoor.
  ///
  /// In en, this message translates to:
  /// **'Left at front door, etc.'**
  String get leftAtFrontDoor;

  /// No description provided for @submitProofAndCompleteDelivery.
  ///
  /// In en, this message translates to:
  /// **'Submit Proof & Complete Delivery'**
  String get submitProofAndCompleteDelivery;

  /// No description provided for @pleaseTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please take a photo of the delivery'**
  String get pleaseTakePhoto;

  /// No description provided for @pleaseObtainSignature.
  ///
  /// In en, this message translates to:
  /// **'Please obtain a signature'**
  String get pleaseObtainSignature;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noDeliveryHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No delivery history yet'**
  String get noDeliveryHistoryYet;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @couldNotLaunchMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not launch maps: {error}'**
  String couldNotLaunchMaps(Object error);
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

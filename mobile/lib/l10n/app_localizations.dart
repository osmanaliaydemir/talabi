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

  /// Free
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Talabi'**
  String get appTitle;

  /// Welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Currency
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Turkish
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Turkish Lira
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira'**
  String get turkishLira;

  /// Tether
  ///
  /// In en, this message translates to:
  /// **'Tether'**
  String get tether;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Product image
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get productResmi;

  /// Stars
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get yildiz;

  /// Add to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favorilereEkle;

  /// Remove from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favorilerdenCikar;

  /// Menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fiyat;

  /// Decrease quantity
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get adediAzalt;

  /// Quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get miktar;

  /// Increase quantity
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get adediArtir;

  /// Add to cart
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get sepeteEkle;

  /// Share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Go back
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get back;

  /// review
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get degerlendirme;

  /// Total amount
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @degerlendirmeSayisi.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String degerlendirmeSayisi(Object count);

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Products
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// Vendors
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// Cart
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Orders
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// Favorites
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Addresses
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Price
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Add to Cart
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// Total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Total Price
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// Checkout
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Secure Payment
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get checkoutSubtitle;

  /// Free delivery reached!
  ///
  /// In en, this message translates to:
  /// **'Free delivery reached!'**
  String get freeDeliveryReached;

  /// No description provided for @remainingForFreeDelivery.
  ///
  /// In en, this message translates to:
  /// **'{amount} more for free delivery'**
  String remainingForFreeDelivery(Object amount);

  /// Order Information
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// Order History
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// Order Detail
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetail;

  /// Delivery Tracking
  ///
  /// In en, this message translates to:
  /// **'Delivery Tracking'**
  String get deliveryTracking;

  /// Select Language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Select Currency
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// Currency selection
  ///
  /// In en, this message translates to:
  /// **'Currency selection'**
  String get selectCurrencyDescription;

  /// Regional Settings
  ///
  /// In en, this message translates to:
  /// **'Regional Settings'**
  String get regionalSettings;

  /// Date Format
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// Time Format
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// Time Zone
  ///
  /// In en, this message translates to:
  /// **'Time Zone'**
  String get timeZone;

  /// 24 Hour
  ///
  /// In en, this message translates to:
  /// **'24 Hour'**
  String get hour24;

  /// 12 Hour
  ///
  /// In en, this message translates to:
  /// **'12 Hour'**
  String get hour12;

  /// Discover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// My Favorites
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// My Cart
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// My Orders
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// My Account
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// My Profile
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// User
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Edit Profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Edit business name, address and contact informa...
  ///
  /// In en, this message translates to:
  /// **'Edit business name, address and contact information'**
  String get editProfileDescription;

  /// Edit name, phone, vehicle information and worki...
  ///
  /// In en, this message translates to:
  /// **'Edit name, phone, vehicle information and working hours'**
  String get editCourierProfileDescription;

  /// Change Password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Notification Settings
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// My Addresses
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// Favorite Products
  ///
  /// In en, this message translates to:
  /// **'Favorite Products'**
  String get favoriteProducts;

  /// Popular Products
  ///
  /// In en, this message translates to:
  /// **'Popular Products'**
  String get popularProducts;

  /// Popular Businesses
  ///
  /// In en, this message translates to:
  /// **'Popular Businesses'**
  String get popularVendors;

  /// View All
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Product Detail
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get productDetail;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Vendor
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Add to Favorites
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Remove from Favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// In Stock
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// Out of Stock
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// Sign In
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign Up
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Welcome!
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeBack;

  /// Sign in to place orders and track them in real-...
  ///
  /// In en, this message translates to:
  /// **'Sign in to place orders and track them in real-time'**
  String get loginDescription;

  /// Email Address
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Remember me?
  ///
  /// In en, this message translates to:
  /// **'Remember me?'**
  String get rememberMe;

  /// Recovery Password
  ///
  /// In en, this message translates to:
  /// **'Recovery Password'**
  String get recoveryPassword;

  /// Log in
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Or continue with
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Google
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Apple
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Facebook
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// Don't have an account?
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Create Account
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Sign up to get started with Talabi
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started with Talabi'**
  String get registerDescription;

  /// Full Name
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Already have an account?
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Email is required
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Please enter a valid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmail;

  /// Password is required
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Password must be at least 6 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// Full name is required
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// Login failed
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Registration failed
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registerFailed;

  /// Password Reset
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordReset;

  /// Forget Password
  ///
  /// In en, this message translates to:
  /// **'Forget Password'**
  String get forgetPassword;

  /// Enter your email account to reset password
  ///
  /// In en, this message translates to:
  /// **'Enter your email account to reset password'**
  String get forgetPasswordDescription;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Password reset email has been sent to your emai...
  ///
  /// In en, this message translates to:
  /// **'Password reset email has been sent to your email address'**
  String get passwordResetEmailSent;

  /// Failed to send password reset email
  ///
  /// In en, this message translates to:
  /// **'Failed to send password reset email'**
  String get passwordResetFailed;

  /// Email Verification
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// Check Your Email
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// We have sent a verification link to your email ...
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification link to your email address. Please check your inbox and click the link to verify your account.'**
  String get emailVerificationDescription;

  /// I Have Verified
  ///
  /// In en, this message translates to:
  /// **'I Have Verified'**
  String get iHaveVerified;

  /// Resend Email
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// Resend feature coming soon
  ///
  /// In en, this message translates to:
  /// **'Resend feature coming soon'**
  String get resendFeatureComingSoon;

  /// Verification email has been resent
  ///
  /// In en, this message translates to:
  /// **'Verification email has been resent'**
  String get verificationEmailResent;

  /// Please verify your email address.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address.'**
  String get pleaseVerifyEmail;

  /// Offline Mode
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Some features may be limited
  ///
  /// In en, this message translates to:
  /// **'Some features may be limited'**
  String get offlineModeDescription;

  /// Accessibility & Display
  ///
  /// In en, this message translates to:
  /// **'Accessibility & Display'**
  String get accessibilityTitle;

  /// Customize themes, contrast and text size for be...
  ///
  /// In en, this message translates to:
  /// **'Customize themes, contrast and text size for better readability'**
  String get accessibilityDescription;

  /// Display
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// Dark Mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Use dark theme for low light environments
  ///
  /// In en, this message translates to:
  /// **'Use dark theme for low light environments'**
  String get darkModeDescription;

  /// High Contrast
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get highContrast;

  /// Increase contrast for better visibility
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better visibility'**
  String get highContrastDescription;

  /// Text Size
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// Adjust text size for better readability
  ///
  /// In en, this message translates to:
  /// **'Adjust text size for better readability'**
  String get textSizeDescription;

  /// Preview Text
  ///
  /// In en, this message translates to:
  /// **'Preview Text'**
  String get textSizePreview;

  /// Your cart is empty
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyMessage;

  /// Enter your voucher code
  ///
  /// In en, this message translates to:
  /// **'Enter your voucher code'**
  String get cartVoucherPlaceholder;

  /// Subtotal
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get cartSubtotalLabel;

  /// Discount
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountTitle;

  /// Delivery Fee
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get cartDeliveryFeeLabel;

  /// Total Amount
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get cartTotalAmountLabel;

  /// Checkout
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// Add Order Note
  ///
  /// In en, this message translates to:
  /// **'Add Order Note'**
  String get addOrderNote;

  /// Order Note
  ///
  /// In en, this message translates to:
  /// **'Order Note'**
  String get orderNote;

  /// Enter your note for the order...
  ///
  /// In en, this message translates to:
  /// **'Enter your note for the order...'**
  String get enterOrderNoteHint;

  /// Coupon Applied
  ///
  /// In en, this message translates to:
  /// **'Coupon Applied'**
  String get couponApplied;

  /// Coupon Removed
  ///
  /// In en, this message translates to:
  /// **'Coupon Removed'**
  String get couponRemoved;

  /// Enter Coupon Code
  ///
  /// In en, this message translates to:
  /// **'Enter Coupon Code'**
  String get enterCouponCode;

  /// Apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No Active Campaigns
  ///
  /// In en, this message translates to:
  /// **'No Active Campaigns'**
  String get noCampaignsFound;

  /// There are no active campaigns at the moment. Pl...
  ///
  /// In en, this message translates to:
  /// **'There are no active campaigns at the moment. Please check back later or enter a coupon code.'**
  String get noCampaignsDescription;

  /// Confirm Order
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// All items in the cart must be from the same vendor
  ///
  /// In en, this message translates to:
  /// **'All items in the cart must be from the same vendor'**
  String get cartSameVendorWarning;

  /// Order Received!
  ///
  /// In en, this message translates to:
  /// **'Order Received!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order number: {orderId}\nTotal: {total}'**
  String orderPlacedMessage(Object orderId, Object total);

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// An account with this email address already exists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email address already exists.'**
  String get duplicateEmail;

  /// At least 6 characters
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordRuleChars;

  /// At least one digit (0-9)
  ///
  /// In en, this message translates to:
  /// **'At least one digit (0-9)'**
  String get passwordRuleDigit;

  /// At least one uppercase letter (A-Z)
  ///
  /// In en, this message translates to:
  /// **'At least one uppercase letter (A-Z)'**
  String get passwordRuleUpper;

  /// At least one lowercase letter (a-z)
  ///
  /// In en, this message translates to:
  /// **'At least one lowercase letter (a-z)'**
  String get passwordRuleLower;

  /// At least one special character (!@#$%^&* etc.)
  ///
  /// In en, this message translates to:
  /// **'At least one special character (!@#\$%^&* etc.)'**
  String get passwordRuleSpecial;

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

  /// Clear Cart
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCartTitle;

  /// Do you want to remove all items from the cart?
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove all items from the cart?'**
  String get clearCartMessage;

  /// No
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get clearCartNo;

  /// Yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get clearCartYes;

  /// Cart cleared successfully
  ///
  /// In en, this message translates to:
  /// **'Cart cleared successfully'**
  String get clearCartSuccess;

  /// Category Change
  ///
  /// In en, this message translates to:
  /// **'Category Change'**
  String get categoryChangeConfirmTitle;

  /// Changing category will clear your cart items.
  ///
  /// In en, this message translates to:
  /// **'Changing category will clear your cart items.'**
  String get categoryChangeConfirmMessage;

  /// Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get categoryChangeConfirmOk;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get categoryChangeConfirmCancel;

  /// No description provided for @productByVendor.
  ///
  /// In en, this message translates to:
  /// **'By {vendorName}'**
  String productByVendor(Object vendorName);

  /// Information
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get alreadyReviewedTitle;

  /// You have already reviewed this product.
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this product.'**
  String get alreadyReviewedMessage;

  /// Write a Review
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// Courier Login
  ///
  /// In en, this message translates to:
  /// **'Courier Login'**
  String get courierLogin;

  /// Welcome Back, Courier!
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Courier!'**
  String get courierWelcome;

  /// Sign in to manage your deliveries
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your deliveries'**
  String get courierSubtitle;

  /// Are you a courier?
  ///
  /// In en, this message translates to:
  /// **'Are you a courier?'**
  String get areYouCourier;

  /// Are you a vendor?
  ///
  /// In en, this message translates to:
  /// **'Are you a vendor? '**
  String get areYouVendor;

  /// Sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get courierSignIn;

  /// Courier Login
  ///
  /// In en, this message translates to:
  /// **'Courier Login'**
  String get courierLoginLink;

  /// Customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// Vendor
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get roleVendor;

  /// Courier
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get roleCourier;

  /// Admin
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Active Deliveries
  ///
  /// In en, this message translates to:
  /// **'Active Deliveries'**
  String get activeDeliveries;

  /// Delivery History
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// Earnings
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// Deliveries
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No active deliveries
  ///
  /// In en, this message translates to:
  /// **'No active deliveries'**
  String get noActiveDeliveries;

  /// Courier profile not found
  ///
  /// In en, this message translates to:
  /// **'Courier profile not found'**
  String get courierProfileNotFound;

  /// Profile updated successfully
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// Invalid status. Valid values: Offline, Availabl...
  ///
  /// In en, this message translates to:
  /// **'Invalid status. Valid values: Offline, Available, Busy, Break, Assigned'**
  String get invalidStatus;

  /// Cannot go available outside working hours
  ///
  /// In en, this message translates to:
  /// **'Cannot go available outside working hours'**
  String get cannotGoAvailableOutsideWorkingHours;

  /// Cannot go offline with active orders
  ///
  /// In en, this message translates to:
  /// **'Cannot go offline with active orders'**
  String get cannotGoOfflineWithActiveOrders;

  /// Status updated
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// Location updated successfully
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdatedSuccessfully;

  /// Invalid latitude
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude'**
  String get invalidLatitude;

  /// Invalid longitude
  ///
  /// In en, this message translates to:
  /// **'Invalid longitude'**
  String get invalidLongitude;

  /// Order accepted successfully
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully'**
  String get orderAcceptedSuccessfully;

  /// Order rejected successfully
  ///
  /// In en, this message translates to:
  /// **'Order rejected successfully'**
  String get orderRejectedSuccessfully;

  /// Order picked up successfully
  ///
  /// In en, this message translates to:
  /// **'Order picked up successfully'**
  String get orderPickedUpSuccessfully;

  /// Order delivered successfully
  ///
  /// In en, this message translates to:
  /// **'Order delivered successfully'**
  String get orderDeliveredSuccessfully;

  /// Delivery proof submitted successfully
  ///
  /// In en, this message translates to:
  /// **'Delivery proof submitted successfully'**
  String get deliveryProofSubmittedSuccessfully;

  /// Order not found or not assigned to you
  ///
  /// In en, this message translates to:
  /// **'Order not found or not assigned to you'**
  String get orderNotFoundOrNotAssigned;

  /// Order must be delivered before submitting proof
  ///
  /// In en, this message translates to:
  /// **'Order must be delivered before submitting proof'**
  String get orderMustBeDeliveredBeforeSubmittingProof;

  /// Failed to accept order. It might be already tak...
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order. It might be already taken or cancelled'**
  String get failedToAcceptOrder;

  /// Failed to reject order
  ///
  /// In en, this message translates to:
  /// **'Failed to reject order'**
  String get failedToRejectOrder;

  /// Failed to pick up order
  ///
  /// In en, this message translates to:
  /// **'Failed to pick up order'**
  String get failedToPickUpOrder;

  /// Failed to deliver order
  ///
  /// In en, this message translates to:
  /// **'Failed to deliver order'**
  String get failedToDeliverOrder;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load courier profile: {error}'**
  String failedToLoadProfile(Object error);

  /// Failed to update status
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// Failed to update location
  ///
  /// In en, this message translates to:
  /// **'Failed to update location'**
  String get failedToUpdateLocation;

  /// Failed to load statistics
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics'**
  String get failedToLoadStatistics;

  /// Failed to load active orders
  ///
  /// In en, this message translates to:
  /// **'Failed to load active orders'**
  String get failedToLoadActiveOrders;

  /// Failed to load order detail
  ///
  /// In en, this message translates to:
  /// **'Failed to load order detail'**
  String get failedToLoadOrderDetail;

  /// Failed to load today earnings
  ///
  /// In en, this message translates to:
  /// **'Failed to load today earnings'**
  String get failedToLoadTodayEarnings;

  /// Failed to load weekly earnings
  ///
  /// In en, this message translates to:
  /// **'Failed to load weekly earnings'**
  String get failedToLoadWeeklyEarnings;

  /// Failed to load monthly earnings
  ///
  /// In en, this message translates to:
  /// **'Failed to load monthly earnings'**
  String get failedToLoadMonthlyEarnings;

  /// Failed to load earnings history
  ///
  /// In en, this message translates to:
  /// **'Failed to load earnings history'**
  String get failedToLoadEarningsHistory;

  /// Failed to submit proof
  ///
  /// In en, this message translates to:
  /// **'Failed to submit proof'**
  String get failedToSubmitProof;

  /// Failed to update profile
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// Failed to upload image
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No file uploaded
  ///
  /// In en, this message translates to:
  /// **'No file uploaded'**
  String get noFileUploaded;

  /// Internal server error during upload
  ///
  /// In en, this message translates to:
  /// **'Internal server error during upload'**
  String get internalServerErrorDuringUpload;

  /// Check Availability
  ///
  /// In en, this message translates to:
  /// **'Check Availability'**
  String get checkAvailability;

  /// Business Settings
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettings;

  /// Business Active
  ///
  /// In en, this message translates to:
  /// **'Business Active'**
  String get businessActive;

  /// Customers can place orders
  ///
  /// In en, this message translates to:
  /// **'Customers can place orders'**
  String get customersCanPlaceOrders;

  /// Order taking is closed
  ///
  /// In en, this message translates to:
  /// **'Order taking is closed'**
  String get orderTakingClosed;

  /// Business Operations
  ///
  /// In en, this message translates to:
  /// **'Business Operations'**
  String get businessOperations;

  /// Minimum Order Amount
  ///
  /// In en, this message translates to:
  /// **'Minimum Order Amount'**
  String get minimumOrderAmount;

  /// Estimated Delivery Time (minutes)
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery Time (minutes)'**
  String get estimatedDeliveryTime;

  /// Enter a valid amount
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// Enter a valid time
  ///
  /// In en, this message translates to:
  /// **'Enter a valid time'**
  String get enterValidTime;

  /// Optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Delivery Fee
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// Address Required
  ///
  /// In en, this message translates to:
  /// **'Address Required'**
  String get addressRequiredTitle;

  /// You need to add a delivery address before placi...
  ///
  /// In en, this message translates to:
  /// **'You need to add a delivery address before placing an order.'**
  String get addressRequiredMessage;

  /// You must add at least one address to place orde...
  ///
  /// In en, this message translates to:
  /// **'You must add at least one address to place orders. Please add your address.'**
  String get addressRequiredDescription;

  /// Add Address
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// Legal Documents
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get legalDocuments;

  /// Terms of Use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Refund Policy
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get refundPolicy;

  /// Distance Sales Agreement
  ///
  /// In en, this message translates to:
  /// **'Distance Sales Agreement'**
  String get distanceSalesAgreement;

  /// Loading content...
  ///
  /// In en, this message translates to:
  /// **'Loading content...'**
  String get loadingContent;

  /// Content not available
  ///
  /// In en, this message translates to:
  /// **'Content not available'**
  String get contentNotAvailable;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Profile updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Update your personal information
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// Phone Number
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Profile Image URL
  ///
  /// In en, this message translates to:
  /// **'Profile Image URL'**
  String get profileImageUrl;

  /// Date of Birth
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// Not selected
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String profileLoadFailed(Object error);

  /// Failed to update settings
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings'**
  String get settingsUpdateFailed;

  /// Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Push Notifications
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Promotional Notifications
  ///
  /// In en, this message translates to:
  /// **'Promotional Notifications'**
  String get promotionalNotifications;

  /// New Products
  ///
  /// In en, this message translates to:
  /// **'New Products'**
  String get newProducts;

  /// More
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Accessibility & Display
  ///
  /// In en, this message translates to:
  /// **'Accessibility & Display'**
  String get accessibilityAndDisplay;

  /// Help Center
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// How can we help you?
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// FAQ
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// Frequently asked questions
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get frequentlyAskedQuestions;

  /// Contact Support
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Call Us
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// Live Chat
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// Available 24/7
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get available24x7;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// Are you sure you want to logout from your account?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get logoutConfirmMessage;

  /// Passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Password changed successfully
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// Enter your current password and choose a new one
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get changePasswordDescription;

  /// Current Password
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Current password is required
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// New Password
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// New password is required
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// Confirm Password
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmNewPassword;

  /// Password confirmation is required
  ///
  /// In en, this message translates to:
  /// **'Password confirmation is required'**
  String get confirmPasswordRequired;

  /// Secure your account
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureYourAccount;

  /// Failed to load addresses
  ///
  /// In en, this message translates to:
  /// **'Failed to load addresses'**
  String get addressesLoadFailed;

  /// Delete Address
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddressTitle;

  /// Are you sure you want to delete this address?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get deleteAddressConfirm;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Address deleted
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// Default address updated
  ///
  /// In en, this message translates to:
  /// **'Default address updated'**
  String get defaultAddressUpdated;

  /// Manage your delivery addresses
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery addresses'**
  String get manageDeliveryAddresses;

  /// No addresses yet
  ///
  /// In en, this message translates to:
  /// **'No addresses yet'**
  String get noAddressesYet;

  /// Tap + button to add a new address
  ///
  /// In en, this message translates to:
  /// **'Tap + button to add a new address'**
  String get tapToAddAddress;

  /// Default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Set as Default
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// 1 address
  ///
  /// In en, this message translates to:
  /// **'1 address'**
  String get addressCountSingular;

  /// No description provided for @addressCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} addresses'**
  String addressCountPlural(Object count);

  /// Location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// Please select a location
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectLocation;

  /// Selected Location
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// Address Title (Optional)
  ///
  /// In en, this message translates to:
  /// **'Address Title (Optional)'**
  String get addressTitleOptional;

  /// Can be left empty
  ///
  /// In en, this message translates to:
  /// **'Can be left empty'**
  String get canBeLeftEmpty;

  /// Address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// City
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// District
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// Select a location on the map or drag the marker
  ///
  /// In en, this message translates to:
  /// **'Select a location on the map or drag the marker'**
  String get selectOrDragMarkerOnMap;

  /// Save Address
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddressButton;

  /// Select Address
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddress;

  /// Select location from map
  ///
  /// In en, this message translates to:
  /// **'Select location from map'**
  String get selectLocationFromMap;

  /// Address added
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// Address updated
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// Edit Address
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// Add New Address
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// Update your address information
  ///
  /// In en, this message translates to:
  /// **'Update your address information'**
  String get updateAddressInfo;

  /// Enter your delivery address details
  ///
  /// In en, this message translates to:
  /// **'Enter your delivery address details'**
  String get enterDeliveryAddressDetails;

  /// Address Title (Home, Work, etc.)
  ///
  /// In en, this message translates to:
  /// **'Address Title (Home, Work, etc.)'**
  String get addressTitleHint;

  /// Title is required
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// Select Address from Map
  ///
  /// In en, this message translates to:
  /// **'Select Address from Map'**
  String get selectAddressFromMap;

  /// Full Address
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// Address is required
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// City is required
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// District is required
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// Postal Code (Optional)
  ///
  /// In en, this message translates to:
  /// **'Postal Code (Optional)'**
  String get postalCodeOptional;

  /// Update Address
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get updateAddressButton;

  /// Update address details
  ///
  /// In en, this message translates to:
  /// **'Update address details'**
  String get updateAddressDetails;

  /// Create new address
  ///
  /// In en, this message translates to:
  /// **'Create new address'**
  String get createNewAddress;

  /// Order Updates
  ///
  /// In en, this message translates to:
  /// **'Order Updates'**
  String get orderUpdates;

  /// Get notified when your order status changes
  ///
  /// In en, this message translates to:
  /// **'Get notified when your order status changes'**
  String get orderUpdatesDescription;

  /// Promotions
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// Special offers and promotions
  ///
  /// In en, this message translates to:
  /// **'Special offers and promotions'**
  String get promotionsDescription;

  /// Get notified when new products are added
  ///
  /// In en, this message translates to:
  /// **'Get notified when new products are added'**
  String get newProductsDescription;

  /// Settings saved
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// Date and time settings
  ///
  /// In en, this message translates to:
  /// **'Date and time settings'**
  String get regionalSettingsDescription;

  /// e.g., Europe/Istanbul, America/New_York
  ///
  /// In en, this message translates to:
  /// **'e.g., Europe/Istanbul, America/New_York'**
  String get timeZoneHint;

  /// Manage your notification preferences
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get manageNotificationPreferences;

  /// View your past orders
  ///
  /// In en, this message translates to:
  /// **'View your past orders'**
  String get orderHistoryDescription;

  /// Manage your delivery addresses
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery addresses'**
  String get myAddressesDescription;

  /// My Favorite Products
  ///
  /// In en, this message translates to:
  /// **'My Favorite Products'**
  String get myFavoriteProducts;

  /// View and manage your favorite products
  ///
  /// In en, this message translates to:
  /// **'View and manage your favorite products'**
  String get myFavoriteProductsDescription;

  /// Change your password and enhance security
  ///
  /// In en, this message translates to:
  /// **'Change your password and enhance security'**
  String get changePasswordSubtitle;

  /// Manage your notification preferences
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get notificationSettingsDescription;

  /// Change application language
  ///
  /// In en, this message translates to:
  /// **'Change application language'**
  String get selectLanguageDescription;

  /// Choose your preferred language
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get selectLanguageSubtitle;

  /// Language changed
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @languagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} languages'**
  String languagesCount(Object count);

  /// Terms of use and policies
  ///
  /// In en, this message translates to:
  /// **'Terms of use and policies'**
  String get legalDocumentsDescription;

  /// FAQ and support line
  ///
  /// In en, this message translates to:
  /// **'FAQ and support line'**
  String get helpCenterDescription;

  /// Sign out from your account
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get logoutDescription;

  /// Vendor Registration
  ///
  /// In en, this message translates to:
  /// **'Vendor Registration'**
  String get vendorRegister;

  /// Talabi Business
  ///
  /// In en, this message translates to:
  /// **'Talabi Business'**
  String get talabiBusiness;

  /// Create Business Account
  ///
  /// In en, this message translates to:
  /// **'Create Business Account'**
  String get createBusinessAccount;

  /// Create your store and start selling
  ///
  /// In en, this message translates to:
  /// **'Create your store and start selling'**
  String get createYourStoreAndStartSelling;

  /// Business Name
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Business name is required
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// Phone number is required
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// Create Vendor Account
  ///
  /// In en, this message translates to:
  /// **'Create Vendor Account'**
  String get createVendorAccount;

  /// Already have a vendor account?
  ///
  /// In en, this message translates to:
  /// **'Already have a vendor account? '**
  String get alreadyHaveVendorAccount;

  /// Customer account?
  ///
  /// In en, this message translates to:
  /// **'Customer account? '**
  String get isCustomerAccount;

  /// An account with this email already exists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get emailAlreadyExists;

  /// Please enter the 4-digit code
  ///
  /// In en, this message translates to:
  /// **'Please enter the 4-digit code'**
  String get enterFourDigitCode;

  /// Email address verified successfully
  ///
  /// In en, this message translates to:
  /// **'Email address verified successfully'**
  String get emailVerifiedSuccess;

  /// Email verified but auto-login failed. Please lo...
  ///
  /// In en, this message translates to:
  /// **'Email verified but auto-login failed. Please login manually.'**
  String get emailVerifiedLoginFailed;

  /// Verification failed
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// Verification code resent
  ///
  /// In en, this message translates to:
  /// **'Verification code resent'**
  String get verificationCodeResent;

  /// Failed to send code
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get codeSendFailed;

  /// 4-Digit Verification Code
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

  /// Resend Code
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @settingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String settingsLoadError(Object error);

  /// Settings updated
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// Review approved
  ///
  /// In en, this message translates to:
  /// **'Review approved'**
  String get reviewApproved;

  /// No description provided for @reviewApproveError.
  ///
  /// In en, this message translates to:
  /// **'Error approving review: {error}'**
  String reviewApproveError(Object error);

  /// Reject Review
  ///
  /// In en, this message translates to:
  /// **'Reject Review'**
  String get rejectReview;

  /// Are you sure you want to reject this review? Th...
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this review? This cannot be undone.'**
  String get rejectReviewConfirmation;

  /// Reject
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Review rejected
  ///
  /// In en, this message translates to:
  /// **'Review rejected'**
  String get reviewRejected;

  /// No description provided for @reviewRejectError.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting review: {error}'**
  String reviewRejectError(Object error);

  /// Review Detail
  ///
  /// In en, this message translates to:
  /// **'Review Detail'**
  String get reviewDetail;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String userId(Object id);

  /// Rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Comment
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No comment
  ///
  /// In en, this message translates to:
  /// **'No comment'**
  String get noComment;

  /// Date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Approve
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// Verify
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Place Order
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// Delivery Address
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// Change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAddress;

  /// Payment Method
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Cash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Credit Card
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// Mobile Payment
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment'**
  String get mobilePayment;

  /// Coming Soon
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Add note for courier (optional)
  ///
  /// In en, this message translates to:
  /// **'Add note for courier (optional)'**
  String get orderNotePlaceholder;

  /// Estimated Delivery
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// minutes
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Order Summary
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// Please select a delivery address
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery address'**
  String get pleaseSelectAddress;

  /// Please select a payment method
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// Your order has been created successfully!
  ///
  /// In en, this message translates to:
  /// **'Your order has been created successfully!'**
  String get orderCreatedSuccess;

  /// No address found
  ///
  /// In en, this message translates to:
  /// **'No address found'**
  String get noAddressFound;

  /// You can pay cash to the courier at the door.
  ///
  /// In en, this message translates to:
  /// **'You can pay cash to the courier at the door.'**
  String get cashDescription;

  /// This payment method will be available soon.
  ///
  /// In en, this message translates to:
  /// **'This payment method will be available soon.'**
  String get paymentComingSoonDescription;

  /// Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Get Started
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Delicious Meals At Your Door In Minutes
  ///
  /// In en, this message translates to:
  /// **'Delicious Meals\nAt Your Door In Minutes'**
  String get onboardingTitle1;

  /// Order your favorite meals from top restaurants ...
  ///
  /// In en, this message translates to:
  /// **'Order your favorite meals from top restaurants and enjoy them warm.'**
  String get onboardingDesc1;

  /// Grocery Shopping At Your Door In Minutes
  ///
  /// In en, this message translates to:
  /// **'Grocery Shopping\nAt Your Door In Minutes'**
  String get onboardingTitle2;

  /// Fresh vegetables, fruits, and daily needs deliv...
  ///
  /// In en, this message translates to:
  /// **'Fresh vegetables, fruits, and daily needs delivered fast.'**
  String get onboardingDesc2;

  /// Best Prices & Offers
  ///
  /// In en, this message translates to:
  /// **'Best Prices & Offers'**
  String get onboardingTitle3;

  /// Enjoy exclusive deals and competitive prices ev...
  ///
  /// In en, this message translates to:
  /// **'Enjoy exclusive deals and competitive prices every day'**
  String get onboardingDesc3;

  /// Pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Preparing
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// Ready
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// Out for Delivery
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// Delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Assigned
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// Accepted
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Picked Up
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// Courier Information
  ///
  /// In en, this message translates to:
  /// **'Courier Information'**
  String get courierInformation;

  /// Assigned At
  ///
  /// In en, this message translates to:
  /// **'Assigned At'**
  String get assignedAt;

  /// Accepted At
  ///
  /// In en, this message translates to:
  /// **'Accepted At'**
  String get acceptedAt;

  /// Picked Up At
  ///
  /// In en, this message translates to:
  /// **'Picked Up At'**
  String get pickedUpAt;

  /// Out for Delivery At
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery At'**
  String get outForDeliveryAt;

  /// Vendor Orders
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

  /// No orders found
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// Order
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// Customer
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// Vendor Dashboard
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

  /// Today's Orders
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todayOrders;

  /// Pending Orders
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// Today's Revenue
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todayRevenue;

  /// Weekly Revenue
  ///
  /// In en, this message translates to:
  /// **'Weekly Revenue'**
  String get weeklyRevenue;

  /// Quick Actions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Logo updated
  ///
  /// In en, this message translates to:
  /// **'Logo updated'**
  String get logoUpdated;

  /// No description provided for @logoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Logo upload failed: {error}'**
  String logoUploadFailed(Object error);

  /// Location Selected (Change)
  ///
  /// In en, this message translates to:
  /// **'Location Selected (Change)'**
  String get locationSelectedChange;

  /// Select Location from Map *
  ///
  /// In en, this message translates to:
  /// **'Select Location from Map *'**
  String get selectLocationFromMapRequired;

  /// Location selection from map is required
  ///
  /// In en, this message translates to:
  /// **'Location selection from map is required'**
  String get locationSelectionRequired;

  /// Address selected from map is auto-filled, you c...
  ///
  /// In en, this message translates to:
  /// **'Address selected from map is auto-filled, you can edit manually'**
  String get addressAutoFillHint;

  /// You must select a location from map first
  ///
  /// In en, this message translates to:
  /// **'You must select a location from map first'**
  String get selectLocationFirst;

  /// Vendor Login
  ///
  /// In en, this message translates to:
  /// **'Vendor Login'**
  String get vendorLogin;

  /// Welcome Back, Vendor!
  ///
  /// In en, this message translates to:
  /// **'Welcome Back, Vendor!'**
  String get welcomeBackVendor;

  /// Sign in to manage your store and orders
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your store and orders'**
  String get vendorLoginDescription;

  /// Are you a customer?
  ///
  /// In en, this message translates to:
  /// **'Are you a customer?'**
  String get areYouCustomer;

  /// Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get vendorNotificationsTitle;

  /// You have no notifications yet.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet.'**
  String get vendorNotificationsEmptyMessage;

  /// An error occurred while loading notifications.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading notifications.'**
  String get vendorNotificationsErrorMessage;

  /// My Products
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get vendorProductsTitle;

  /// Search products...
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

  /// Delete Product
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

  /// No products found
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get vendorProductsEmpty;

  /// Add Your First Product
  ///
  /// In en, this message translates to:
  /// **'Add Your First Product'**
  String get vendorProductsAddFirst;

  /// New Product
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get vendorProductsAddNew;

  /// Edit Product
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get vendorProductFormEditTitle;

  /// New Product
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get vendorProductFormNewTitle;

  /// Image uploaded
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get vendorProductFormImageUploaded;

  /// No description provided for @vendorProductFormImageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}'**
  String vendorProductFormImageUploadError(Object error);

  /// Camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get vendorProductFormSourceCamera;

  /// Gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get vendorProductFormSourceGallery;

  /// Product created
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get vendorProductFormCreateSuccess;

  /// Product updated
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get vendorProductFormUpdateSuccess;

  /// No description provided for @vendorProductFormError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String vendorProductFormError(Object error);

  /// Product Name *
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get vendorProductFormNameLabel;

  /// Product name is required
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get vendorProductFormNameRequired;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get vendorProductFormDescriptionLabel;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get vendorProductFormCategoryLabel;

  /// Price *
  ///
  /// In en, this message translates to:
  /// **'Price *'**
  String get vendorProductFormPriceLabel;

  /// Price is required
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get vendorProductFormPriceRequired;

  /// Please enter a valid price
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get vendorProductFormPriceInvalid;

  /// Stock Quantity
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get vendorProductFormStockLabel;

  /// Please enter a valid number
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get vendorProductFormInvalidNumber;

  /// Preparation Time (minutes)
  ///
  /// In en, this message translates to:
  /// **'Preparation Time (minutes)'**
  String get vendorProductFormPreparationTimeLabel;

  /// In Stock
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get vendorProductFormInStockLabel;

  /// The product will be visible to customers
  ///
  /// In en, this message translates to:
  /// **'The product will be visible to customers'**
  String get vendorProductFormInStockDescription;

  /// The product will be marked as out of stock
  ///
  /// In en, this message translates to:
  /// **'The product will be marked as out of stock'**
  String get vendorProductFormOutOfStockDescription;

  /// Update
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateButton;

  /// Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// Add Image
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get vendorProductFormAddImage;

  /// My Vendor Profile
  ///
  /// In en, this message translates to:
  /// **'My Vendor Profile'**
  String get vendorProfileTitle;

  /// Vendor
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorFallbackSubtitle;

  /// Business Information
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInfo;

  /// Address
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// General Settings
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// Business Settings
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettingsTitle;

  /// Minimum order, delivery fee, and other settings
  ///
  /// In en, this message translates to:
  /// **'Minimum order, delivery fee, and other settings'**
  String get businessSettingsSubtitle;

  /// Turkish
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageNameTr;

  /// English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// Arabic
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageNameAr;

  /// Business Name
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessNameFallback;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Mark as Read
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// Pending Reviews
  ///
  /// In en, this message translates to:
  /// **'Pending Reviews'**
  String get pendingReviews;

  /// No pending reviews
  ///
  /// In en, this message translates to:
  /// **'No pending reviews'**
  String get noPendingReviews;

  /// No description provided for @reviewsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews: {error}'**
  String reviewsLoadError(Object error);

  /// Sales Reports
  ///
  /// In en, this message translates to:
  /// **'Sales Reports'**
  String get salesReports;

  /// Select Date Range
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// Daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Weekly
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No report found
  ///
  /// In en, this message translates to:
  /// **'No report found'**
  String get noReportFound;

  /// Total Orders
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// Total Revenue
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledOrders;

  /// Daily Sales
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get dailySales;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String orderCount(Object count);

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Cancel Order
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// Reorder
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// Order cancelled
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Cancel reason'**
  String get cancelReason;

  /// Please specify your cancellation reason (at lea...
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

  /// Reject Order
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// Order Rejection
  ///
  /// In en, this message translates to:
  /// **'Order Rejection'**
  String get rejectOrderTitle;

  /// Rejection reason
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get rejectReason;

  /// Please enter the rejection reason (at least 1 c...
  ///
  /// In en, this message translates to:
  /// **'Please enter the rejection reason (at least 1 character):'**
  String get rejectReasonDescription;

  /// Rejection reason...
  ///
  /// In en, this message translates to:
  /// **'Rejection reason...'**
  String get rejectReasonHint;

  /// Are you sure you want to reject this order?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this order?'**
  String get rejectOrderConfirmation;

  /// Order rejected
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// pieces
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get pieces;

  /// Order not found
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// Products added to cart, redirecting to cart...
  ///
  /// In en, this message translates to:
  /// **'Products added to cart, redirecting to cart...'**
  String get productsAddedToCart;

  /// No description provided for @reorderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String reorderFailed(Object error);

  /// Location permission denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// Location permission permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionDeniedForever;

  /// No description provided for @vendorsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load vendors: {error}'**
  String vendorsLoadFailed(Object error);

  /// Your Location
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// Location Permission Required
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionTitle;

  /// We need your location permission to show nearby...
  ///
  /// In en, this message translates to:
  /// **'We need your location permission to show nearby restaurants and track your orders.'**
  String get locationPermissionMessage;

  /// Allow
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Location Management
  ///
  /// In en, this message translates to:
  /// **'Location Management'**
  String get locationManagement;

  /// Current Location Information
  ///
  /// In en, this message translates to:
  /// **'Current Location Information'**
  String get currentLocationInfo;

  /// Latitude
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// Longitude
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// Last Update
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastLocationUpdate;

  /// No location data available
  ///
  /// In en, this message translates to:
  /// **'No location data available'**
  String get noLocationData;

  /// Select Location on Map
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get selectLocationOnMap;

  /// Use Current Location
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// Update Location
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateLocation;

  /// Location sharing is required to receive orders ...
  ///
  /// In en, this message translates to:
  /// **'Location sharing is required to receive orders from nearby restaurants. Your location is automatically shared when your status is \"Available\".'**
  String get locationSharingInfo;

  /// View and update your current location
  ///
  /// In en, this message translates to:
  /// **'View and update your current location'**
  String get locationManagementDescription;

  /// Vendors Map
  ///
  /// In en, this message translates to:
  /// **'Vendors Map'**
  String get vendorsMap;

  /// Find My Location
  ///
  /// In en, this message translates to:
  /// **'Find My Location'**
  String get findMyLocation;

  /// View Products
  ///
  /// In en, this message translates to:
  /// **'View Products'**
  String get viewProducts;

  /// Getting location...
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

  /// Filters
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Select category
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// Price Range
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// Min Price
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// Max Price
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// Select city
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get selectCity;

  /// Minimum Rating
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// Maximum Distance (km)
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance (km)'**
  String get maximumDistance;

  /// Distance (km)
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// Sort By
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Select sort by
  ///
  /// In en, this message translates to:
  /// **'Select sort by'**
  String get selectSortBy;

  /// Price (Low to High)
  ///
  /// In en, this message translates to:
  /// **'Price (Low to High)'**
  String get priceLowToHigh;

  /// Price (High to Low)
  ///
  /// In en, this message translates to:
  /// **'Price (High to Low)'**
  String get priceHighToLow;

  /// Sort by Name
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// Newest
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Rating (High to Low)
  ///
  /// In en, this message translates to:
  /// **'Rating (High to Low)'**
  String get ratingHighToLow;

  /// Popularity
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// Distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Apply Filters
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Search products or vendors...
  ///
  /// In en, this message translates to:
  /// **'Search products or vendors...'**
  String get searchProductsOrVendors;

  /// Suggestions
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// Product
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// Search History
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get searchHistory;

  /// Type in the box above to search
  ///
  /// In en, this message translates to:
  /// **'Type in the box above to search'**
  String get typeToSearch;

  /// Recent Searches
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No results found
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

  /// Popular Searches
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get popularSearches;

  /// Delivery Zones
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// Manage cities and districts you deliver to
  ///
  /// In en, this message translates to:
  /// **'Manage cities and districts you deliver to'**
  String get deliveryZonesDescription;

  /// Delivery zones updated successfully
  ///
  /// In en, this message translates to:
  /// **'Delivery zones updated successfully'**
  String get deliveryZonesUpdated;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'{productName} removed from favorites'**
  String removedFromFavorites(Object productName);

  /// No favorite products found
  ///
  /// In en, this message translates to:
  /// **'No favorite products found'**
  String get noFavoritesFound;

  /// You can view your favorite products here by add...
  ///
  /// In en, this message translates to:
  /// **'You can view your favorite products here by adding them to favorites.'**
  String get favoritesEmptyMessage;

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

  /// No products yet.
  ///
  /// In en, this message translates to:
  /// **'No products yet.'**
  String get noProductsYet;

  /// No description provided for @productLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load product: {error}'**
  String productLoadFailed(Object error);

  /// Product not found
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// Rate Vendor
  ///
  /// In en, this message translates to:
  /// **'Rate Vendor'**
  String get rateVendor;

  /// Share your thoughts...
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get shareYourThoughts;

  /// Submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Vendor review submitted!
  ///
  /// In en, this message translates to:
  /// **'Vendor review submitted!'**
  String get vendorReviewSubmitted;

  /// Product review submitted!
  ///
  /// In en, this message translates to:
  /// **'Product review submitted!'**
  String get productReviewSubmitted;

  /// No description available.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescription;

  /// Read more
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// Show less
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// Delivery Time
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// Delivery Type
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryType;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews ({count})'**
  String reviews(Object count);

  /// No reviews yet. Be the first to review!
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first to review!'**
  String get noReviewsYet;

  /// See All Reviews
  ///
  /// In en, this message translates to:
  /// **'See All Reviews'**
  String get seeAllReviews;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By {vendorName}'**
  String by(Object vendorName);

  /// Your Order Has Been Created Successfully!
  ///
  /// In en, this message translates to:
  /// **'Your Order Has Been Created Successfully!'**
  String get orderCreatedSuccessfully;

  /// Order Code
  ///
  /// In en, this message translates to:
  /// **'Order Code'**
  String get orderCode;

  /// Your order has started being prepared. You can ...
  ///
  /// In en, this message translates to:
  /// **'Your order has started being prepared. You can track your order status from the \"My Orders\" page.'**
  String get orderPreparationStarted;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePage;

  /// No description provided for @ordersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String ordersLoadFailed(Object error);

  /// No orders yet
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// On the Way
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get onWay;

  /// Unknown Vendor
  ///
  /// In en, this message translates to:
  /// **'Unknown Vendor'**
  String get unknownVendor;

  /// Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Cancel Item
  ///
  /// In en, this message translates to:
  /// **'Cancel Item'**
  String get cancelItem;

  /// Item Cancelled
  ///
  /// In en, this message translates to:
  /// **'Item Cancelled'**
  String get itemCancelled;

  /// Item cancelled successfully
  ///
  /// In en, this message translates to:
  /// **'Item cancelled successfully'**
  String get itemCancelSuccess;

  /// No description provided for @itemCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel item: {error}'**
  String itemCancelFailed(Object error);

  /// Hungry? We’ve got you covered!
  ///
  /// In en, this message translates to:
  /// **'Hungry?\nWe’ve got you covered!'**
  String get promotionalBannerTitle;

  /// Free delivery, low fees & 10% cashback!
  ///
  /// In en, this message translates to:
  /// **'Free delivery, low fees & 10% cashback!'**
  String get promotionalBannerSubtitle;

  /// Order Now
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// Categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No categories found
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoryNotFound;

  /// Picks For You
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

  /// Campaigns
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

  /// Similar Products
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// Are you Hungry?
  ///
  /// In en, this message translates to:
  /// **'Are you Hungry?'**
  String get areYouHungry;

  /// Request what you need, and we'll deliver it to ...
  ///
  /// In en, this message translates to:
  /// **'Request what you need, and we\'ll deliver it to you as fast as possible.\nOrdering with Talabi is now as easy as a single touch.'**
  String get onboardingDescription;

  /// Slide to Talabî!
  ///
  /// In en, this message translates to:
  /// **'Slide to Talabî!'**
  String get unlockDescription;

  /// Add address to order
  ///
  /// In en, this message translates to:
  /// **'Add address to order'**
  String get addAddressToOrder;

  /// Create Courier Account
  ///
  /// In en, this message translates to:
  /// **'Create Courier Account'**
  String get createCourierAccount;

  /// Start delivering today and earn money
  ///
  /// In en, this message translates to:
  /// **'Start delivering today and earn money'**
  String get startDeliveringToday;

  /// Already have a courier account?
  ///
  /// In en, this message translates to:
  /// **'Already have a courier account? '**
  String get alreadyHaveCourierAccount;

  /// Courier Register
  ///
  /// In en, this message translates to:
  /// **'Courier Register'**
  String get courierRegister;

  /// Talabi Courier
  ///
  /// In en, this message translates to:
  /// **'Talabi Courier'**
  String get talabiCourier;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// All time
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// Accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Mark as Picked Up
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get markAsPickedUp;

  /// Mark as Delivered
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// Order accepted
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAccepted;

  /// Order marked as picked up
  ///
  /// In en, this message translates to:
  /// **'Order marked as picked up'**
  String get orderMarkedAsPickedUp;

  /// Order delivered
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get orderDelivered;

  /// Action could not be completed
  ///
  /// In en, this message translates to:
  /// **'Action could not be completed'**
  String get actionCouldNotBeCompleted;

  /// Cannot change status while busy
  ///
  /// In en, this message translates to:
  /// **'Cannot change status while busy'**
  String get cannotChangeStatusWhileBusy;

  /// No description provided for @newOrderAssigned.
  ///
  /// In en, this message translates to:
  /// **'New order #{orderId} assigned!'**
  String newOrderAssigned(Object orderId);

  /// Current Status
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// Performance
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// Availability Status
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// Check new order receiving conditions here
  ///
  /// In en, this message translates to:
  /// **'Check new order receiving conditions here'**
  String get checkNewOrderConditions;

  /// Navigation App
  ///
  /// In en, this message translates to:
  /// **'Navigation App'**
  String get navigationApp;

  /// Select your preferred navigation app
  ///
  /// In en, this message translates to:
  /// **'Select your preferred navigation app'**
  String get selectPreferredNavigationApp;

  /// No vehicle information
  ///
  /// In en, this message translates to:
  /// **'No vehicle information'**
  String get noVehicleInfo;

  /// Cannot change status with active orders
  ///
  /// In en, this message translates to:
  /// **'Cannot change status with active orders'**
  String get cannotChangeStatusWithActiveOrders;

  /// Cannot go offline until active orders are compl...
  ///
  /// In en, this message translates to:
  /// **'Cannot go offline until active orders are completed'**
  String get cannotGoOfflineUntilOrdersCompleted;

  /// Points
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// Total Earnings
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// Are you sure you want to logout?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// Personal Information
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// Courier Settings
  ///
  /// In en, this message translates to:
  /// **'Courier Settings'**
  String get courierSettings;

  /// Vehicle Type
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// Max Active Orders
  ///
  /// In en, this message translates to:
  /// **'Max Active Orders'**
  String get maxActiveOrders;

  /// Use working hours
  ///
  /// In en, this message translates to:
  /// **'Use working hours'**
  String get useWorkingHours;

  /// You can only be "Available" during the hours yo...
  ///
  /// In en, this message translates to:
  /// **'You can only be \"Available\" during the hours you set'**
  String get onlyAvailableDuringSetHours;

  /// Start Time
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// End Time
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// You must select start and end time for working ...
  ///
  /// In en, this message translates to:
  /// **'You must select start and end time for working hours'**
  String get mustSelectStartAndEndTime;

  /// Saving...
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// You must select a vehicle type
  ///
  /// In en, this message translates to:
  /// **'You must select a vehicle type'**
  String get mustSelectVehicleType;

  /// Select Vehicle Type
  ///
  /// In en, this message translates to:
  /// **'Select Vehicle Type'**
  String get selectVehicleType;

  /// Please select the vehicle type you will use. Th...
  ///
  /// In en, this message translates to:
  /// **'Please select the vehicle type you will use. This selection is required.'**
  String get selectVehicleTypeDescription;

  /// Motorcycle
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// Car
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// Bicycle
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get bicycle;

  /// Vehicle type updated successfully
  ///
  /// In en, this message translates to:
  /// **'Vehicle type updated successfully'**
  String get vehicleTypeUpdatedSuccessfully;

  /// Failed to update vehicle type
  ///
  /// In en, this message translates to:
  /// **'Failed to update vehicle type'**
  String get failedToUpdateVehicleType;

  /// Location Selection Required
  ///
  /// In en, this message translates to:
  /// **'Location Selection Required'**
  String get selectLocationRequired;

  /// Please select your location. This information i...
  ///
  /// In en, this message translates to:
  /// **'Please select your location. This information is required to receive orders.'**
  String get selectLocationRequiredDescription;

  /// Select from Map
  ///
  /// In en, this message translates to:
  /// **'Select from Map'**
  String get selectFromMap;

  /// Getting your location...
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingCurrentLocation;

  /// Location Services Disabled
  ///
  /// In en, this message translates to:
  /// **'Location Services Disabled'**
  String get locationServicesDisabledTitle;

  /// Location services are disabled. Please enable l...
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable location services in settings.'**
  String get locationServicesDisabledMessage;

  /// Open Settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Confirm Courier Assignment
  ///
  /// In en, this message translates to:
  /// **'Confirm Courier Assignment'**
  String get assignCourierConfirmationTitle;

  /// No description provided for @assignCourierConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to assign this order to {courierName}?'**
  String assignCourierConfirmationMessage(String courierName);

  /// Assign
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// Courier assigned successfully
  ///
  /// In en, this message translates to:
  /// **'Courier assigned successfully'**
  String get courierAssignedSuccessfully;

  /// Enter a valid number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile update failed: {error}'**
  String profileUpdateFailed(Object error);

  /// Availability Conditions
  ///
  /// In en, this message translates to:
  /// **'Availability Conditions'**
  String get availabilityConditions;

  /// The following conditions must be met to receive...
  ///
  /// In en, this message translates to:
  /// **'The following conditions must be met to receive new orders:'**
  String get whenConditionsMetCanReceiveOrders;

  /// Your status must be "Available"
  ///
  /// In en, this message translates to:
  /// **'Your status must be \"Available\"'**
  String get statusMustBeAvailable;

  /// No description provided for @activeOrdersBelowLimit.
  ///
  /// In en, this message translates to:
  /// **'Your active orders must be below your maximum limit ({current} / {max})'**
  String activeOrdersBelowLimit(Object current, Object max);

  /// Your courier account must be active
  ///
  /// In en, this message translates to:
  /// **'Your courier account must be active'**
  String get courierAccountMustBeActive;

  /// Currently blocking reasons
  ///
  /// In en, this message translates to:
  /// **'Currently blocking reasons'**
  String get currentlyBlockingReasons;

  /// Everything looks good, new orders may arrive
  ///
  /// In en, this message translates to:
  /// **'Everything looks good, new orders may arrive'**
  String get everythingLooksGood;

  /// Available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Not Available
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Earnings
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// Today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayEarnings;

  /// This Week
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// This Month
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Total Earnings
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarningsLabel;

  /// Avg. per Delivery
  ///
  /// In en, this message translates to:
  /// **'Avg. per Delivery'**
  String get avgPerDelivery;

  /// History
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No earnings found for this period
  ///
  /// In en, this message translates to:
  /// **'No earnings found for this period'**
  String get noEarningsForPeriod;

  /// Navigation app updated
  ///
  /// In en, this message translates to:
  /// **'Navigation app updated'**
  String get navigationAppUpdated;

  /// No description provided for @navigationPreferenceNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Navigation preference could not be saved: {error}'**
  String navigationPreferenceNotSaved(Object error);

  /// Select the default navigation app you want to u...
  ///
  /// In en, this message translates to:
  /// **'Select the default navigation app you want to use when going to delivery address'**
  String get selectDefaultNavigationApp;

  /// Note
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// If the app you selected is not installed, the s...
  ///
  /// In en, this message translates to:
  /// **'If the app you selected is not installed, the system will offer you a suitable alternative'**
  String get ifAppNotInstalledSystemWillOfferAlternative;

  /// This preference is only valid for your courier ...
  ///
  /// In en, this message translates to:
  /// **'This preference is only valid for your courier account'**
  String get preferenceOnlyForCourierAccount;

  /// Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// You don't have any notifications yet. Order mov...
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any notifications yet.\nOrder movements will appear here'**
  String get noNotificationsYet;

  /// Notifications could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded'**
  String get notificationsLoadFailed;

  /// No description provided for @notificationProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification processing failed: {error}'**
  String notificationProcessingFailed(Object error);

  /// Order Detail
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get orderDetailTitle;

  /// Pickup Location
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// Delivery Location
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// Order Items
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// View Map
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// Delivery Proof
  ///
  /// In en, this message translates to:
  /// **'Delivery Proof'**
  String get deliveryProof;

  /// Take Photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Signature
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// Notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Notes (Optional)
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// Left at front door, etc.
  ///
  /// In en, this message translates to:
  /// **'Left at front door, etc.'**
  String get leftAtFrontDoor;

  /// Submit Proof & Complete Delivery
  ///
  /// In en, this message translates to:
  /// **'Submit Proof & Complete Delivery'**
  String get submitProofAndCompleteDelivery;

  /// Please take a photo of the delivery
  ///
  /// In en, this message translates to:
  /// **'Please take a photo of the delivery'**
  String get pleaseTakePhoto;

  /// Please obtain a signature
  ///
  /// In en, this message translates to:
  /// **'Please obtain a signature'**
  String get pleaseObtainSignature;

  /// Try Again
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No delivery history yet
  ///
  /// In en, this message translates to:
  /// **'No delivery history yet'**
  String get noDeliveryHistoryYet;

  /// Pickup
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Delivery
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Talabi
  ///
  /// In en, this message translates to:
  /// **'Talabi'**
  String get talabi;

  /// Navigate
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @couldNotLaunchMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not launch maps: {error}'**
  String couldNotLaunchMaps(Object error);

  /// Market Shopping at Your Door
  ///
  /// In en, this message translates to:
  /// **'Market Shopping\nat Your Door'**
  String get marketBannerTitle;

  /// Select Country
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// Locality / Neighborhood
  ///
  /// In en, this message translates to:
  /// **'Locality / Neighborhood'**
  String get localityNeighborhood;

  /// Please select City and District from dropdowns ...
  ///
  /// In en, this message translates to:
  /// **'Please select City and District from dropdowns to confirm.'**
  String get selectCityDistrictWarning;

  /// Password reset successfully
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// Verification Code
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// Please enter the verification code sent to
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code sent to'**
  String get verificationCodeSentDesc;

  /// Create New Password
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createPassword;

  /// Please enter a new password for your account
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password for your account'**
  String get createPasswordDesc;

  /// This field is required
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Reset Password
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// The code has expired.
  ///
  /// In en, this message translates to:
  /// **'The code has expired.'**
  String get codeExpired;

  /// Business Type
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// Business type is required
  ///
  /// In en, this message translates to:
  /// **'Business type is required'**
  String get businessTypeRequired;

  /// Restaurant
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// Market
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// An error occurred
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get defaultError;

  /// ******
  ///
  /// In en, this message translates to:
  /// **'******'**
  String get passwordPlaceholder;

  /// Vehicle Type is required
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type is required'**
  String get vehicleTypeRequired;

  /// Cannot login to customer screens with a vendor ...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to customer screens with a vendor account.'**
  String get errorLoginVendorToCustomer;

  /// Cannot login to customer screens with a courier...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to customer screens with a courier account.'**
  String get errorLoginCourierToCustomer;

  /// Cannot login to vendor screens with a customer ...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to vendor screens with a customer account.'**
  String get errorLoginCustomerToVendor;

  /// Cannot login to vendor screens with a courier a...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to vendor screens with a courier account.'**
  String get errorLoginCourierToVendor;

  /// Cannot login to courier screens with a customer...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to courier screens with a customer account.'**
  String get errorLoginCustomerToCourier;

  /// Cannot login to courier screens with a vendor a...
  ///
  /// In en, this message translates to:
  /// **'Cannot login to courier screens with a vendor account.'**
  String get errorLoginVendorToCourier;

  /// token expired
  ///
  /// In en, this message translates to:
  /// **'token expired'**
  String get keywordTokenExpired;

  /// Account Pending Approval
  ///
  /// In en, this message translates to:
  /// **'Account Pending Approval'**
  String get accountPendingApprovalTitle;

  /// Your account is currently under review. Access ...
  ///
  /// In en, this message translates to:
  /// **'Your account is currently under review. Access will be granted once your account is approved.'**
  String get accountPendingApprovalMessage;

  /// Normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get vendorStatusNormal;

  /// Busy
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get vendorStatusBusy;

  /// Overloaded
  ///
  /// In en, this message translates to:
  /// **'Overloaded'**
  String get vendorStatusOverloaded;

  /// Standard time
  ///
  /// In en, this message translates to:
  /// **'Standard time'**
  String get vendorStatusNormalDesc;

  /// +15 min
  ///
  /// In en, this message translates to:
  /// **'+15 min'**
  String get vendorStatusBusyDesc;

  /// +45 min
  ///
  /// In en, this message translates to:
  /// **'+45 min'**
  String get vendorStatusOverloadedDesc;

  /// Store Status
  ///
  /// In en, this message translates to:
  /// **'Store Status'**
  String get storeStatus;

  /// Working Hours Required
  ///
  /// In en, this message translates to:
  /// **'Working Hours Required'**
  String get workingHoursRequired;

  /// Please set your working hours to start receivin...
  ///
  /// In en, this message translates to:
  /// **'Please set your working hours to start receiving orders.'**
  String get workingHoursRequiredDescription;

  /// Start Time
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get workingHoursStart;

  /// End Time
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get workingHoursEnd;

  /// Select Time
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// Working hours updated successfully
  ///
  /// In en, this message translates to:
  /// **'Working hours updated successfully'**
  String get workingHoursUpdatedSuccessfully;

  /// Failed to update working hours
  ///
  /// In en, this message translates to:
  /// **'Failed to update working hours'**
  String get failedToUpdateWorkingHours;

  /// Working Hours
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// Working Days
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// Closed
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// Open 24 Hours
  ///
  /// In en, this message translates to:
  /// **'Open 24 Hours'**
  String get open24Hours;

  /// Hours
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// Manage your business opening days and hours here.
  ///
  /// In en, this message translates to:
  /// **'Manage your business opening days and hours here.'**
  String get workingHoursDescription;

  /// No description provided for @workingHoursSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving working hours: {error}'**
  String workingHoursSaveError(Object error);

  /// Sham Cash Account Number
  ///
  /// In en, this message translates to:
  /// **'Sham Cash Account Number'**
  String get shamCashAccountNumber;
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

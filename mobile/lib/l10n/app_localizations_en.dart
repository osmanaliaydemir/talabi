// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myWallet => 'My Wallet';

  @override
  String get viewBalanceAndHistory => 'View balance and transaction history';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get topUpBalance => 'Top Up Balance';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get noTransactionsYet => 'No transactions yet.';

  @override
  String get topUp => 'Top Up';

  @override
  String get amountToTopUp => 'Amount to Top Up';

  @override
  String get makePayment => 'Make Payment';

  @override
  String get topUpSuccessful => 'Top up successful!';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get withdrawBalance => 'Withdraw Balance';

  @override
  String get iban => 'IBAN';

  @override
  String get withdrawSuccessful => 'Withdrawal request created successfully';

  @override
  String get insufficientBalance => 'Insufficient balance';

  @override
  String get enterValidIban => 'Please enter a valid IBAN';

  @override
  String get bestSeller => 'Best Seller';

  @override
  String upsellMessage(String amount) {
    return 'Add $amount more to get the discount!';
  }

  @override
  String get campaignApplied => 'Campaign Applied';

  @override
  String get free => 'Free';

  @override
  String get appTitle => 'Talabi';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get turkishLira => 'Turkish Lira';

  @override
  String get tether => 'Tether';

  @override
  String get save => 'Save';

  @override
  String get productResmi => 'Product image';

  @override
  String get yildiz => 'Stars';

  @override
  String get favorilereEkle => 'Add to favorites';

  @override
  String get favorilerdenCikar => 'Remove from favorites';

  @override
  String get menu => 'Menu';

  @override
  String get fiyat => 'Price';

  @override
  String get adediAzalt => 'Decrease quantity';

  @override
  String get miktar => 'Quantity';

  @override
  String get adediArtir => 'Increase quantity';

  @override
  String get sepeteEkle => 'Add to cart';

  @override
  String get share => 'Share';

  @override
  String get back => 'Go back';

  @override
  String get degerlendirme => 'review';

  @override
  String get totalAmount => 'Total amount';

  @override
  String degerlendirmeSayisi(Object count) {
    return '$count reviews';
  }

  @override
  String get yourOrderFeedback => 'Your Order Feedback';

  @override
  String orderNumberWithId(String id) {
    return 'Order number $id';
  }

  @override
  String get pendingApproval => 'Pending Approval';

  @override
  String get approved => 'Approved';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get beTheFirstToReview => 'Be the first to review';

  @override
  String get writeAReview => 'Write a review';

  @override
  String get mustOrderToReview =>
      'You must have ordered this product to leave a review.';

  @override
  String get reviewCreatedSuccessfully => 'Review created successfully';

  @override
  String get send => 'Send';

  @override
  String characterLimitInfo(int min, int max, int current) {
    return 'Character limit: $min-$max (Current: $current)';
  }

  @override
  String get myReviews => 'My Reviews';

  @override
  String get myReviewsDescription => 'See all reviews you have made';

  @override
  String commentTooShort(int min) {
    return 'Comment too short (min $min characters)';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get products => 'Products';

  @override
  String get vendors => 'Vendors';

  @override
  String get cart => 'Cart';

  @override
  String get orders => 'Orders';

  @override
  String get notificationAll => 'All';

  @override
  String get notificationOrders => 'Orders';

  @override
  String get notificationReviews => 'Reviews';

  @override
  String get notificationSystem => 'System';

  @override
  String get favorites => 'Favorites';

  @override
  String get addresses => 'Addresses';

  @override
  String get search => 'Search';

  @override
  String get price => 'Price';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get total => 'Total';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get checkout => 'Checkout';

  @override
  String get checkoutSubtitle => 'Secure Payment';

  @override
  String get orderInformation => 'Order Information';

  @override
  String get orderHistory => 'Order History';

  @override
  String get orderDetail => 'Order Detail';

  @override
  String get deliveryTracking => 'Delivery Tracking';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectCurrency => 'Select Currency';

  @override
  String get selectCurrencyDescription => 'Currency selection';

  @override
  String get regionalSettings => 'Regional Settings';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timeZone => 'Time Zone';

  @override
  String get hour24 => '24 Hour';

  @override
  String get hour12 => '12 Hour';

  @override
  String get discover => 'Discover';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get myCart => 'My Cart';

  @override
  String get myOrders => 'My Orders';

  @override
  String get myAccount => 'My Account';

  @override
  String get myProfile => 'My Profile';

  @override
  String get user => 'User';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileDescription =>
      'Edit business name, address and contact information';

  @override
  String get editCourierProfileDescription =>
      'Edit name, phone, vehicle information and working hours';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get myAddresses => 'My Addresses';

  @override
  String get favoriteProducts => 'Favorite Products';

  @override
  String get popularProducts => 'Popular Products';

  @override
  String get popularVendors => 'Popular Businesses';

  @override
  String get viewAll => 'View All';

  @override
  String get productDetail => 'Product Detail';

  @override
  String get description => 'Description';

  @override
  String get vendor => 'Vendor';

  @override
  String get category => 'Category';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get inStock => 'In Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get welcomeBack => 'Welcome!';

  @override
  String get loginDescription =>
      'Sign in to place orders and track them in real-time';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get rememberMe => 'Remember me?';

  @override
  String get recoveryPassword => 'Recovery Password';

  @override
  String get logIn => 'Log in';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get facebook => 'Facebook';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createAccount => 'Create Account';

  @override
  String get registerDescription => 'Sign up to get started with Talabi';

  @override
  String get fullName => 'Full Name';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmail => 'Please enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get registerFailed => 'Registration failed';

  @override
  String get passwordReset => 'Password Reset';

  @override
  String get forgetPassword => 'Forget Password';

  @override
  String get forgetPasswordDescription =>
      'Enter your email account to reset password';

  @override
  String get continueButton => 'Continue';

  @override
  String get passwordResetEmailSent =>
      'Password reset email has been sent to your email address';

  @override
  String get passwordResetFailed => 'Failed to send password reset email';

  @override
  String get emailVerification => 'Email Verification';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String get emailVerificationDescription =>
      'We have sent a verification link to your email address. Please check your inbox and click the link to verify your account.';

  @override
  String get iHaveVerified => 'I Have Verified';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get resendFeatureComingSoon => 'Resend feature coming soon';

  @override
  String get verificationEmailResent => 'Verification email has been resent';

  @override
  String get pleaseVerifyEmail => 'Please verify your email address.';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get offlineModeDescription => 'Some features may be limited';

  @override
  String get accessibilityTitle => 'Accessibility & Display';

  @override
  String get accessibilityDescription =>
      'Customize themes, contrast and text size for better readability';

  @override
  String get displaySettings => 'Display';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDescription => 'Use dark theme for low light environments';

  @override
  String get highContrast => 'High Contrast';

  @override
  String get highContrastDescription =>
      'Increase contrast for better visibility';

  @override
  String get textSize => 'Text Size';

  @override
  String get textSizeDescription => 'Adjust text size for better readability';

  @override
  String get textSizePreview => 'Preview Text';

  @override
  String get cartEmptyMessage => 'Your cart is empty';

  @override
  String get cartEmptySubMessage =>
      'There are no products in your cart.\nStart shopping now!';

  @override
  String get startShopping => 'Start Shopping';

  @override
  String get recommendedForYou => 'Recommended For You';

  @override
  String get cartVoucherPlaceholder => 'Enter your voucher code';

  @override
  String get cartSubtotalLabel => 'Subtotal';

  @override
  String get discountTitle => 'Discount';

  @override
  String get cartDeliveryFeeLabel => 'Delivery Fee';

  @override
  String get freeDeliveryReached => 'Free delivery reached!';

  @override
  String remainingForFreeDelivery(String amount) {
    return '$amount more for free delivery';
  }

  @override
  String get freeDeliveryDescription =>
      'Add more items to your cart to get free delivery!';

  @override
  String get cartTotalAmountLabel => 'Total Amount';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get addOrderNote => 'Add Order Note';

  @override
  String get orderNote => 'Order Note';

  @override
  String get enterOrderNoteHint => 'Enter your note for the order...';

  @override
  String get couponApplied => 'Coupon Applied';

  @override
  String get couponRemoved => 'Coupon Removed';

  @override
  String get enterCouponCode => 'Enter Coupon Code';

  @override
  String get apply => 'Apply';

  @override
  String get noCampaignsFound => 'No Active Campaigns';

  @override
  String get noCampaignsDescription =>
      'There are no active campaigns at the moment. Please check back later or enter a coupon code.';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get cartSameVendorWarning =>
      'All items in the cart must be from the same vendor';

  @override
  String get orderPlacedTitle => 'Order Received!';

  @override
  String orderPlacedMessage(Object orderId, Object total) {
    return 'Your order number: $orderId\nTotal: $total';
  }

  @override
  String get ok => 'OK';

  @override
  String get duplicateEmail =>
      'An account with this email address already exists.';

  @override
  String get passwordRuleChars => 'At least 6 characters';

  @override
  String get passwordRuleDigit => 'At least one digit (0-9)';

  @override
  String get passwordRuleUpper => 'At least one uppercase letter (A-Z)';

  @override
  String get passwordRuleLower => 'At least one lowercase letter (a-z)';

  @override
  String get passwordRuleSpecial =>
      'At least one special character (!@#\$%^&* etc.)';

  @override
  String googleLoginFailed(Object error) {
    return 'Google login failed: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Apple login failed: $error';
  }

  @override
  String get attentionRequired => 'Attention Required';

  @override
  String criticalStockAlert(int count) {
    return '$count products at critical stock level';
  }

  @override
  String delayedOrdersAlert(int count) {
    return '$count orders are delayed';
  }

  @override
  String unansweredReviewsAlert(int count) {
    return '$count unanswered reviews';
  }

  @override
  String get hourlySalesToday => 'Hourly Sales (Today)';

  @override
  String facebookLoginFailed(Object error) {
    return 'Facebook login failed: $error';
  }

  @override
  String errorWithMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String get clearCartTitle => 'Clear Cart';

  @override
  String get clearCartMessage =>
      'Do you want to remove all items from the cart?';

  @override
  String get clearCartNo => 'No';

  @override
  String get clearCartYes => 'Yes';

  @override
  String get clearCartSuccess => 'Cart cleared successfully';

  @override
  String get categoryChangeConfirmTitle => 'Category Change';

  @override
  String get categoryChangeConfirmMessage =>
      'Changing category will clear your cart items.';

  @override
  String get categoryChangeConfirmOk => 'Confirm';

  @override
  String get categoryChangeConfirmCancel => 'Cancel';

  @override
  String productByVendor(Object vendorName) {
    return 'By $vendorName';
  }

  @override
  String get alreadyReviewedTitle => 'Information';

  @override
  String get alreadyReviewedMessage =>
      'You have already reviewed this product.';

  @override
  String get writeReview => 'Write a Review';

  @override
  String get courierLogin => 'Courier Login';

  @override
  String get courierWelcome => 'Welcome Back, Courier!';

  @override
  String get courierSubtitle => 'Sign in to manage your deliveries';

  @override
  String get areYouCourier => 'Are you a courier?';

  @override
  String get areYouVendor => 'Are you a vendor? ';

  @override
  String get courierSignIn => 'Sign in';

  @override
  String get courierLoginLink => 'Courier Login';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleVendor => 'Vendor';

  @override
  String get roleCourier => 'Courier';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get activeDeliveries => 'Active Deliveries';

  @override
  String get deliveryHistory => 'Delivery History';

  @override
  String get earnings => 'Earnings';

  @override
  String get deliveries => 'Deliveries';

  @override
  String get noActiveDeliveries => 'No active deliveries';

  @override
  String get courierProfileNotFound => 'Courier profile not found';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get invalidStatus =>
      'Invalid status. Valid values: Offline, Available, Busy, Break, Assigned';

  @override
  String get cannotGoAvailableOutsideWorkingHours =>
      'Cannot go available outside working hours';

  @override
  String get cannotGoOfflineWithActiveOrders =>
      'Cannot go offline with active orders';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get locationUpdatedSuccessfully => 'Location updated successfully';

  @override
  String get invalidLatitude => 'Invalid latitude';

  @override
  String get invalidLongitude => 'Invalid longitude';

  @override
  String get orderAcceptedSuccessfully => 'Order accepted successfully';

  @override
  String get orderRejectedSuccessfully => 'Order rejected successfully';

  @override
  String get orderPickedUpSuccessfully => 'Order picked up successfully';

  @override
  String get orderDeliveredSuccessfully => 'Order delivered successfully';

  @override
  String get deliveryProofSubmittedSuccessfully =>
      'Delivery proof submitted successfully';

  @override
  String get orderNotFoundOrNotAssigned =>
      'Order not found or not assigned to you';

  @override
  String get orderMustBeDeliveredBeforeSubmittingProof =>
      'Order must be delivered before submitting proof';

  @override
  String get failedToAcceptOrder =>
      'Failed to accept order. It might be already taken or cancelled';

  @override
  String get failedToRejectOrder => 'Failed to reject order';

  @override
  String get failedToPickUpOrder => 'Failed to pick up order';

  @override
  String get failedToDeliverOrder => 'Failed to deliver order';

  @override
  String failedToLoadProfile(Object error) {
    return 'Failed to load courier profile: $error';
  }

  @override
  String get failedToUpdateStatus => 'Failed to update status';

  @override
  String get failedToUpdateLocation => 'Failed to update location';

  @override
  String get failedToLoadStatistics => 'Failed to load statistics';

  @override
  String get failedToLoadActiveOrders => 'Failed to load active orders';

  @override
  String get failedToLoadOrderDetail => 'Failed to load order detail';

  @override
  String get failedToLoadTodayEarnings => 'Failed to load today earnings';

  @override
  String get failedToLoadWeeklyEarnings => 'Failed to load weekly earnings';

  @override
  String get failedToLoadMonthlyEarnings => 'Failed to load monthly earnings';

  @override
  String get failedToLoadEarningsHistory => 'Failed to load earnings history';

  @override
  String get failedToSubmitProof => 'Failed to submit proof';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get failedToUploadImage => 'Failed to upload image';

  @override
  String get noFileUploaded => 'No file uploaded';

  @override
  String get internalServerErrorDuringUpload =>
      'Internal server error during upload';

  @override
  String get checkAvailability => 'Check Availability';

  @override
  String get businessSettings => 'Business Settings';

  @override
  String get businessActive => 'Business Active';

  @override
  String get customersCanPlaceOrders => 'Customers can place orders';

  @override
  String get orderTakingClosed => 'Order taking is closed';

  @override
  String get businessOperations => 'Business Operations';

  @override
  String get minimumOrderAmount => 'Minimum Order Amount';

  @override
  String get estimatedDeliveryTime => 'Estimated Delivery Time (minutes)';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get enterValidTime => 'Enter a valid time';

  @override
  String get optional => 'Optional';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get addressRequiredTitle => 'Address Required';

  @override
  String get addressRequiredMessage =>
      'You need to add a delivery address before placing an order.';

  @override
  String get addressRequiredDescription =>
      'You must add at least one address to place orders. Please add your address.';

  @override
  String get addAddress => 'Add Address';

  @override
  String get legalDocuments => 'Legal Documents';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get refundPolicy => 'Refund Policy';

  @override
  String get distanceSalesAgreement => 'Distance Sales Agreement';

  @override
  String get loadingContent => 'Loading content...';

  @override
  String get contentNotAvailable => 'Content not available';

  @override
  String get error => 'Error';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get updatePersonalInfo => 'Update your personal information';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get profileImageUrl => 'Profile Image URL';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get notSelected => 'Not selected';

  @override
  String profileLoadFailed(Object error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get settingsUpdateFailed => 'Failed to update settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get promotionalNotifications => 'Promotional Notifications';

  @override
  String get newProducts => 'New Products';

  @override
  String get more => 'More';

  @override
  String get accessibilityAndDisplay => 'Accessibility & Display';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get howCanWeHelpYou => 'How can we help you?';

  @override
  String get faq => 'FAQ';

  @override
  String get frequentlyAskedQuestions => 'Frequently asked questions';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get callUs => 'Call Us';

  @override
  String get liveChat => 'Live Chat';

  @override
  String get available24x7 => 'Available 24/7';

  @override
  String get close => 'Close';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage =>
      'Are you sure you want to logout from your account?';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get changePasswordDescription =>
      'Enter your current password and choose a new one';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordRequired => 'New password is required';

  @override
  String get confirmNewPassword => 'Confirm Password';

  @override
  String get confirmPasswordRequired => 'Password confirmation is required';

  @override
  String get secureYourAccount => 'Secure your account';

  @override
  String get addressesLoadFailed => 'Failed to load addresses';

  @override
  String get deleteAddressTitle => 'Delete Address';

  @override
  String get deleteAddressConfirm =>
      'Are you sure you want to delete this address?';

  @override
  String get delete => 'Delete';

  @override
  String get addressDeleted => 'Address deleted';

  @override
  String get defaultAddressUpdated => 'Default address updated';

  @override
  String get manageDeliveryAddresses => 'Manage your delivery addresses';

  @override
  String get noAddressesYet => 'No addresses yet';

  @override
  String get tapToAddAddress => 'Tap + button to add a new address';

  @override
  String get defaultLabel => 'Default';

  @override
  String get edit => 'Edit';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get addressCountSingular => '1 address';

  @override
  String addressCountPlural(Object count) {
    return '$count addresses';
  }

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get pleaseSelectLocation => 'Please select a location';

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get addressTitleOptional => 'Address Title (Optional)';

  @override
  String get canBeLeftEmpty => 'Can be left empty';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get district => 'District';

  @override
  String get selectOrDragMarkerOnMap =>
      'Select a location on the map or drag the marker';

  @override
  String get saveAddressButton => 'Save Address';

  @override
  String get selectAddress => 'Select Address';

  @override
  String get selectLocationFromMap => 'Select location from map';

  @override
  String get addressAdded => 'Address added';

  @override
  String get addressUpdated => 'Address updated';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get updateAddressInfo => 'Update your address information';

  @override
  String get enterDeliveryAddressDetails =>
      'Enter your delivery address details';

  @override
  String get addressTitleHint => 'Address Title (Home, Work, etc.)';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get selectAddressFromMap => 'Select Address from Map';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get cityRequired => 'City is required';

  @override
  String get districtRequired => 'District is required';

  @override
  String get postalCodeOptional => 'Postal Code (Optional)';

  @override
  String get updateAddressButton => 'Update Address';

  @override
  String get updateAddressDetails => 'Update address details';

  @override
  String get createNewAddress => 'Create new address';

  @override
  String get orderUpdates => 'Order Updates';

  @override
  String get orderUpdatesDescription =>
      'Get notified when your order status changes';

  @override
  String get promotions => 'Promotions';

  @override
  String get promotionsDescription => 'Special offers and promotions';

  @override
  String get newProductsDescription =>
      'Get notified when new products are added';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get regionalSettingsDescription => 'Date and time settings';

  @override
  String get timeZoneHint => 'e.g., Europe/Istanbul, America/New_York';

  @override
  String get manageNotificationPreferences =>
      'Manage your notification preferences';

  @override
  String get orderHistoryDescription => 'View your past orders';

  @override
  String get myAddressesDescription => 'Manage your delivery addresses';

  @override
  String get myFavoriteProducts => 'My Favorite Products';

  @override
  String get myFavoriteProductsDescription =>
      'View and manage your favorite products';

  @override
  String get changePasswordSubtitle =>
      'Change your password and enhance security';

  @override
  String get notificationSettingsDescription =>
      'Manage your notification preferences';

  @override
  String get selectLanguageDescription => 'Change application language';

  @override
  String get selectLanguageSubtitle => 'Choose your preferred language';

  @override
  String get languageChanged => 'Language changed';

  @override
  String languagesCount(Object count) {
    return '$count languages';
  }

  @override
  String get legalDocumentsDescription => 'Terms of use and policies';

  @override
  String get helpCenterDescription => 'FAQ and support line';

  @override
  String get logoutDescription => 'Sign out from your account';

  @override
  String get vendorRegister => 'Vendor Registration';

  @override
  String get talabiBusiness => 'Talabi Business';

  @override
  String get createBusinessAccount => 'Create Business Account';

  @override
  String get createYourStoreAndStartSelling =>
      'Create your store and start selling';

  @override
  String get businessName => 'Business Name';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get createVendorAccount => 'Create Vendor Account';

  @override
  String get alreadyHaveVendorAccount => 'Already have a vendor account? ';

  @override
  String get isCustomerAccount => 'Customer account? ';

  @override
  String get emailAlreadyExists => 'An account with this email already exists.';

  @override
  String get enterFourDigitCode => 'Please enter the 4-digit code';

  @override
  String get emailVerifiedSuccess => 'Email address verified successfully';

  @override
  String get emailVerifiedLoginFailed =>
      'Email verified but auto-login failed. Please login manually.';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get verificationCodeResent => 'Verification code resent';

  @override
  String get codeSendFailed => 'Failed to send code';

  @override
  String get fourDigitVerificationCode => '4-Digit Verification Code';

  @override
  String enterCodeSentToEmail(Object email) {
    return 'Enter the 4-digit code sent to $email';
  }

  @override
  String codeExpiresIn(Object time) {
    return 'Code will expire in $time';
  }

  @override
  String get resendCode => 'Resend Code';

  @override
  String settingsLoadError(Object error) {
    return 'Failed to load settings: $error';
  }

  @override
  String get settingsUpdated => 'Settings updated';

  @override
  String get reviewApproved => 'Review approved';

  @override
  String reviewApproveError(Object error) {
    return 'Error approving review: $error';
  }

  @override
  String get rejectReview => 'Reject Review';

  @override
  String get rejectReviewConfirmation =>
      'Are you sure you want to reject this review? This cannot be undone.';

  @override
  String get reject => 'Reject';

  @override
  String get reviewRejected => 'Review rejected';

  @override
  String reviewRejectError(Object error) {
    return 'Error rejecting review: $error';
  }

  @override
  String userId(Object id) {
    return 'User ID: $id';
  }

  @override
  String get rating => 'Rating';

  @override
  String get comment => 'Comment';

  @override
  String get noComment => 'No comment';

  @override
  String get date => 'Date';

  @override
  String get approve => 'Approve';

  @override
  String get verify => 'Verify';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get changeAddress => 'Change';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get mobilePayment => 'Mobile Payment';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get orderNotePlaceholder => 'Add note for courier (optional)';

  @override
  String get estimatedDelivery => 'Estimated Delivery';

  @override
  String get minutes => 'minutes';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get pleaseSelectAddress => 'Please select a delivery address';

  @override
  String get pleaseSelectPaymentMethod => 'Please select a payment method';

  @override
  String get orderCreatedSuccess => 'Your order has been created successfully!';

  @override
  String get noAddressFound => 'No address found';

  @override
  String get cashDescription => 'You can pay cash to the courier at the door.';

  @override
  String get paymentComingSoonDescription =>
      'This payment method will be available soon.';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingTitle1 => 'Delicious Meals\nAt Your Door In Minutes';

  @override
  String get onboardingDesc1 =>
      'Order your favorite meals from top restaurants and enjoy them warm.';

  @override
  String get onboardingTitle2 => 'Grocery Shopping\nAt Your Door In Minutes';

  @override
  String get onboardingDesc2 =>
      'Fresh vegetables, fruits, and daily needs delivered fast.';

  @override
  String get onboardingTitle3 => 'Best Prices & Offers';

  @override
  String get onboardingDesc3 =>
      'Enjoy exclusive deals and competitive prices every day';

  @override
  String get pending => 'Pending';

  @override
  String get preparing => 'Preparing';

  @override
  String get ready => 'Ready';

  @override
  String get outForDelivery => 'Out for Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get assigned => 'Assigned';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get pickedUp => 'Picked Up';

  @override
  String get courierInformation => 'Courier Information';

  @override
  String get assignedAt => 'Assigned At';

  @override
  String get acceptedAt => 'Accepted At';

  @override
  String get pickedUpAt => 'Picked Up At';

  @override
  String get outForDeliveryAt => 'Out for Delivery At';

  @override
  String get vendorOrders => 'Vendor Orders';

  @override
  String pendingOrdersCount(int count) {
    return '$count pending orders';
  }

  @override
  String preparingOrdersCount(int count) {
    return '$count preparing orders';
  }

  @override
  String readyOrdersCount(int count) {
    return '$count ready orders';
  }

  @override
  String deliveredOrdersCount(int count) {
    return '$count orders delivered';
  }

  @override
  String get noOrdersFound => 'No orders found';

  @override
  String get order => 'Order';

  @override
  String get customer => 'Customer';

  @override
  String get vendorDashboard => 'Vendor Dashboard';

  @override
  String summaryLoadError(Object error) {
    return 'Failed to load summary: $error';
  }

  @override
  String welcomeVendor(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get todayOrders => 'Today\'s Orders';

  @override
  String get pendingOrders => 'Pending Orders';

  @override
  String get todayRevenue => 'Today\'s Revenue';

  @override
  String get weeklyRevenue => 'Weekly Revenue';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get reports => 'Reports';

  @override
  String get logoUpdated => 'Logo updated';

  @override
  String logoUploadFailed(Object error) {
    return 'Logo upload failed: $error';
  }

  @override
  String get locationSelectedChange => 'Location Selected (Change)';

  @override
  String get selectLocationFromMapRequired => 'Select Location from Map *';

  @override
  String get locationSelectionRequired =>
      'Location selection from map is required';

  @override
  String get addressAutoFillHint =>
      'Address selected from map is auto-filled, you can edit manually';

  @override
  String get selectLocationFirst => 'You must select a location from map first';

  @override
  String get vendorLogin => 'Vendor Login';

  @override
  String get welcomeBackVendor => 'Welcome Back, Vendor!';

  @override
  String get vendorLoginDescription =>
      'Sign in to manage your store and orders';

  @override
  String get areYouCustomer => 'Are you a customer?';

  @override
  String get vendorNotificationsTitle => 'Notifications';

  @override
  String get vendorNotificationsEmptyMessage =>
      'You have no notifications yet.';

  @override
  String get vendorNotificationsErrorMessage =>
      'An error occurred while loading notifications.';

  @override
  String get vendorProductsTitle => 'My Products';

  @override
  String get vendorProductsSearchHint => 'Search products...';

  @override
  String vendorProductsLoadError(Object error) {
    return 'Failed to load products: $error';
  }

  @override
  String vendorProductsSetOutOfStock(Object productName) {
    return '$productName set to out of stock';
  }

  @override
  String vendorProductsSetInStock(Object productName) {
    return '$productName is in stock';
  }

  @override
  String get vendorProductsDeleteTitle => 'Delete Product';

  @override
  String vendorProductsDeleteConfirmation(Object productName) {
    return 'Are you sure you want to delete $productName?';
  }

  @override
  String vendorProductsDeleteSuccess(Object productName) {
    return '$productName has been deleted';
  }

  @override
  String get vendorProductsEmpty => 'No products found';

  @override
  String get vendorProductsAddFirst => 'Add Your First Product';

  @override
  String get vendorProductsAddNew => 'New Product';

  @override
  String get vendorProductFormEditTitle => 'Edit Product';

  @override
  String get vendorProductFormNewTitle => 'New Product';

  @override
  String get vendorProductFormImageUploaded => 'Image uploaded';

  @override
  String vendorProductFormImageUploadError(Object error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get vendorProductFormSourceCamera => 'Camera';

  @override
  String get vendorProductFormSourceGallery => 'Gallery';

  @override
  String get vendorProductFormCreateSuccess => 'Product created';

  @override
  String get vendorProductFormUpdateSuccess => 'Product updated';

  @override
  String vendorProductFormError(Object error) {
    return 'Error: $error';
  }

  @override
  String get vendorProductFormNameLabel => 'Product Name *';

  @override
  String get vendorProductFormNameRequired => 'Product name is required';

  @override
  String get vendorProductFormDescriptionLabel => 'Description';

  @override
  String get vendorProductFormCategoryLabel => 'Category';

  @override
  String get vendorProductFormPriceLabel => 'Price *';

  @override
  String get vendorProductFormPriceRequired => 'Price is required';

  @override
  String get vendorProductFormPriceInvalid => 'Please enter a valid price';

  @override
  String get vendorProductFormStockLabel => 'Stock Quantity';

  @override
  String get vendorProductFormInvalidNumber => 'Please enter a valid number';

  @override
  String get vendorProductFormPreparationTimeLabel =>
      'Preparation Time (minutes)';

  @override
  String get vendorProductFormInStockLabel => 'In Stock';

  @override
  String get vendorProductFormInStockDescription =>
      'The product will be visible to customers';

  @override
  String get vendorProductFormOutOfStockDescription =>
      'The product will be marked as out of stock';

  @override
  String get updateButton => 'Update';

  @override
  String get createButton => 'Create';

  @override
  String get vendorProductFormAddImage => 'Add Image';

  @override
  String get vendorProfileTitle => 'My Vendor Profile';

  @override
  String get vendorFallbackSubtitle => 'Vendor';

  @override
  String get businessInfo => 'Business Information';

  @override
  String get addressLabel => 'Address';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get businessSettingsTitle => 'Business Settings';

  @override
  String get businessSettingsSubtitle =>
      'Minimum order, delivery fee, and other settings';

  @override
  String get languageNameTr => 'Turkish';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameAr => 'Arabic';

  @override
  String get businessNameFallback => 'Business Name';

  @override
  String get retry => 'Retry';

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get pendingReviews => 'Pending Reviews';

  @override
  String get noPendingReviews => 'No pending reviews';

  @override
  String reviewsLoadError(Object error) {
    return 'Failed to load reviews: $error';
  }

  @override
  String get salesReports => 'Sales Reports';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get noReportFound => 'No report found';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get completed => 'Completed';

  @override
  String get cancelledOrders => 'Cancelled';

  @override
  String get dailySales => 'Daily Sales';

  @override
  String orderCount(Object count) {
    return '$count orders';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get reorder => 'Reorder';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get cancelReason => 'Cancel reason';

  @override
  String get cancelReasonDescription =>
      'Please specify your cancellation reason (at least 10 characters):';

  @override
  String get acceptOrderTitle => 'Accept Order';

  @override
  String get acceptOrderConfirmation =>
      'Are you sure you want to accept this order?';

  @override
  String get acceptOrder => 'Accept';

  @override
  String get updateOrderStatusTitle => 'Update Order Status';

  @override
  String get markAsReadyConfirmation =>
      'Are you sure you want to mark this order as \"Ready\"?';

  @override
  String get markAsReady => 'Mark as Ready';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get rejectOrderTitle => 'Order Rejection';

  @override
  String get rejectReason => 'Rejection reason';

  @override
  String get rejectReasonDescription =>
      'Please enter the rejection reason (at least 1 character):';

  @override
  String get rejectReasonHint => 'Rejection reason...';

  @override
  String get rejectOrderConfirmation =>
      'Are you sure you want to reject this order?';

  @override
  String get orderRejected => 'Order rejected';

  @override
  String get pieces => 'pieces';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get productsAddedToCart =>
      'Products added to cart, redirecting to cart...';

  @override
  String reorderFailed(Object error) {
    return 'Failed to reorder: $error';
  }

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission permanently denied';

  @override
  String vendorsLoadFailed(Object error) {
    return 'Failed to load vendors: $error';
  }

  @override
  String get yourLocation => 'Your Location';

  @override
  String get locationPermissionTitle => 'Location Permission Required';

  @override
  String get locationPermissionMessage =>
      'We need your location permission to show nearby restaurants and track your orders.';

  @override
  String get allow => 'Allow';

  @override
  String get locationManagement => 'Location Management';

  @override
  String get currentLocationInfo => 'Current Location Information';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get lastLocationUpdate => 'Last Update';

  @override
  String get noLocationData => 'No location data available';

  @override
  String get selectLocationOnMap => 'Select Location on Map';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get updateLocation => 'Update Location';

  @override
  String get locationSharingInfo =>
      'Location sharing is required to receive orders from nearby restaurants. Your location is automatically shared when your status is \"Available\".';

  @override
  String get locationManagementDescription =>
      'View and update your current location';

  @override
  String get vendorsMap => 'Vendors Map';

  @override
  String get findMyLocation => 'Find My Location';

  @override
  String get viewProducts => 'View Products';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String searchError(Object error) {
    return 'Search error: $error';
  }

  @override
  String productAddedToCart(Object productName) {
    return '$productName added to cart';
  }

  @override
  String get filters => 'Filters';

  @override
  String get clear => 'Clear';

  @override
  String get selectCategory => 'Select category';

  @override
  String get priceRange => 'Price Range';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get selectCity => 'Select city';

  @override
  String get minimumRating => 'Minimum Rating';

  @override
  String get maximumDistance => 'Maximum Distance (km)';

  @override
  String get distanceKm => 'Distance (km)';

  @override
  String get sortBy => 'Sort By';

  @override
  String get selectSortBy => 'Select sort by';

  @override
  String get priceLowToHigh => 'Price (Low to High)';

  @override
  String get priceHighToLow => 'Price (High to Low)';

  @override
  String get sortByName => 'Sort by Name';

  @override
  String get newest => 'Newest';

  @override
  String get ratingHighToLow => 'Rating (High to Low)';

  @override
  String get popularity => 'Popularity';

  @override
  String get distance => 'Distance';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get searchProductsOrVendors => 'Search products or vendors...';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get product => 'Product';

  @override
  String get searchHistory => 'Search History';

  @override
  String get typeToSearch => 'Type in the box above to search';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get noResultsFound => 'No results found';

  @override
  String cityLabel(Object city) {
    return 'City: $city';
  }

  @override
  String distanceLabel(Object distance) {
    return 'Distance: $distance km';
  }

  @override
  String get popularSearches => 'Popular Searches';

  @override
  String get deliveryZones => 'Delivery Zones';

  @override
  String get deliveryZonesDescription =>
      'Manage cities and districts you deliver to';

  @override
  String get deliveryZonesUpdated => 'Delivery zones updated successfully';

  @override
  String removedFromFavorites(Object productName) {
    return '$productName removed from favorites';
  }

  @override
  String get noFavoritesFound => 'No favorite products found';

  @override
  String get favoritesEmptyMessage =>
      'You can view your favorite products here by adding them to favorites.';

  @override
  String addedToFavorites(Object productName) {
    return '$productName added to favorites';
  }

  @override
  String favoriteOperationFailed(Object error) {
    return 'Favorite operation failed: $error';
  }

  @override
  String get noProductsYet => 'No products yet.';

  @override
  String productLoadFailed(Object error) {
    return 'Failed to load product: $error';
  }

  @override
  String get productNotFound => 'Product not found';

  @override
  String get rateVendor => 'Rate Vendor';

  @override
  String get shareYourThoughts => 'Share your thoughts...';

  @override
  String get submit => 'Submit';

  @override
  String get vendorReviewSubmitted => 'Vendor review submitted!';

  @override
  String get productReviewSubmitted => 'Product review submitted!';

  @override
  String get noDescription => 'No description available.';

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String get deliveryTime => 'Delivery Time';

  @override
  String get deliveryType => 'Delivery Type';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String reviews(Object count) {
    return 'Reviews ($count)';
  }

  @override
  String get noReviewsYet => 'No reviews yet. Be the first to review!';

  @override
  String get seeAllReviews => 'See All Reviews';

  @override
  String by(Object vendorName) {
    return 'By $vendorName';
  }

  @override
  String get orderCreatedSuccessfully =>
      'Your Order Has Been Created Successfully!';

  @override
  String get orderCode => 'Order Code';

  @override
  String get orderPreparationStarted =>
      'Your order has started being prepared. You can track your order status from the \"My Orders\" page.';

  @override
  String get homePage => 'Home';

  @override
  String ordersLoadFailed(Object error) {
    return 'Failed to load orders: $error';
  }

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get onWay => 'On the Way';

  @override
  String get unknownVendor => 'Unknown Vendor';

  @override
  String get unknown => 'Unknown';

  @override
  String get cancelItem => 'Cancel Item';

  @override
  String get itemCancelled => 'Item Cancelled';

  @override
  String get itemCancelSuccess => 'Item cancelled successfully';

  @override
  String itemCancelFailed(Object error) {
    return 'Failed to cancel item: $error';
  }

  @override
  String get promotionalBannerTitle => 'Hungry?\nWe’ve got you covered!';

  @override
  String get promotionalBannerSubtitle =>
      'Free delivery, low fees & 10% cashback!';

  @override
  String get orderNow => 'Order Now';

  @override
  String get categories => 'Categories';

  @override
  String get categoryNotFound => 'No categories found';

  @override
  String get picksForYou => 'Picks For You';

  @override
  String addressUpdateFailed(Object error) {
    return 'Address update failed: $error';
  }

  @override
  String unreadNotificationsCount(Object count) {
    return '$count unread notifications';
  }

  @override
  String get campaigns => 'Campaigns';

  @override
  String productsCount(Object count) {
    return '$count products';
  }

  @override
  String campaignsCount(Object count) {
    return '$count campaigns';
  }

  @override
  String vendorsCount(Object count) {
    return '$count businesses';
  }

  @override
  String get similarProducts => 'Similar Products';

  @override
  String get areYouHungry => 'Are you Hungry?';

  @override
  String get onboardingDescription =>
      'Request what you need, and we\'ll deliver it to you as fast as possible.\nOrdering with Talabi is now as easy as a single touch.';

  @override
  String get unlockDescription => 'Slide to Talabî!';

  @override
  String get addAddressToOrder => 'Add address to order';

  @override
  String get createCourierAccount => 'Create Courier Account';

  @override
  String get startDeliveringToday => 'Start delivering today and earn money';

  @override
  String get alreadyHaveCourierAccount => 'Already have a courier account? ';

  @override
  String get courierRegister => 'Courier Register';

  @override
  String get talabiCourier => 'Talabi Courier';

  @override
  String get today => 'Today';

  @override
  String get allTime => 'All time';

  @override
  String get accept => 'Accept';

  @override
  String get markAsPickedUp => 'Mark as Picked Up';

  @override
  String get markAsDelivered => 'Mark as Delivered';

  @override
  String get orderAccepted => 'Order accepted';

  @override
  String get orderMarkedAsPickedUp => 'Order marked as picked up';

  @override
  String get orderDelivered => 'Order delivered';

  @override
  String get actionCouldNotBeCompleted => 'Action could not be completed';

  @override
  String get cannotChangeStatusWhileBusy => 'Cannot change status while busy';

  @override
  String newOrderAssigned(Object orderId) {
    return 'New order #$orderId assigned!';
  }

  @override
  String get currentStatus => 'Current Status';

  @override
  String get performance => 'Performance';

  @override
  String get availabilityStatus => 'Availability Status';

  @override
  String get checkNewOrderConditions =>
      'Check new order receiving conditions here';

  @override
  String get navigationApp => 'Navigation App';

  @override
  String get selectPreferredNavigationApp =>
      'Select your preferred navigation app';

  @override
  String get noVehicleInfo => 'No vehicle information';

  @override
  String get cannotChangeStatusWithActiveOrders =>
      'Cannot change status with active orders';

  @override
  String get cannotGoOfflineUntilOrdersCompleted =>
      'Cannot go offline until active orders are completed';

  @override
  String get points => 'Points';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get courierSettings => 'Courier Settings';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get maxActiveOrders => 'Max Active Orders';

  @override
  String get useWorkingHours => 'Use working hours';

  @override
  String get onlyAvailableDuringSetHours =>
      'You can only be \"Available\" during the hours you set';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get mustSelectStartAndEndTime =>
      'You must select start and end time for working hours';

  @override
  String get saving => 'Saving...';

  @override
  String get mustSelectVehicleType => 'You must select a vehicle type';

  @override
  String get selectVehicleType => 'Select Vehicle Type';

  @override
  String get selectVehicleTypeDescription =>
      'Please select the vehicle type you will use. This selection is required.';

  @override
  String get motorcycle => 'Motorcycle';

  @override
  String get car => 'Car';

  @override
  String get bicycle => 'Bicycle';

  @override
  String get vehicleTypeUpdatedSuccessfully =>
      'Vehicle type updated successfully';

  @override
  String get failedToUpdateVehicleType => 'Failed to update vehicle type';

  @override
  String get selectLocationRequired => 'Location Selection Required';

  @override
  String get selectLocationRequiredDescription =>
      'Please select your location. This information is required to receive orders.';

  @override
  String get selectFromMap => 'Select from Map';

  @override
  String get gettingCurrentLocation => 'Getting your location...';

  @override
  String get locationServicesDisabledTitle => 'Location Services Disabled';

  @override
  String get locationServicesDisabledMessage =>
      'Location services are disabled. Please enable location services in settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get assignCourierConfirmationTitle => 'Confirm Courier Assignment';

  @override
  String assignCourierConfirmationMessage(String courierName) {
    return 'Are you sure you want to assign this order to $courierName?';
  }

  @override
  String get assign => 'Assign';

  @override
  String get courierAssignedSuccessfully => 'Courier assigned successfully';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String profileUpdateFailed(Object error) {
    return 'Profile update failed: $error';
  }

  @override
  String get availabilityConditions => 'Availability Conditions';

  @override
  String get whenConditionsMetCanReceiveOrders =>
      'The following conditions must be met to receive new orders:';

  @override
  String get statusMustBeAvailable => 'Your status must be \"Available\"';

  @override
  String activeOrdersBelowLimit(Object current, Object max) {
    return 'Your active orders must be below your maximum limit ($current / $max)';
  }

  @override
  String get courierAccountMustBeActive =>
      'Your courier account must be active';

  @override
  String get currentlyBlockingReasons => 'Currently blocking reasons';

  @override
  String get everythingLooksGood =>
      'Everything looks good, new orders may arrive';

  @override
  String get available => 'Available';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get earningsTitle => 'Earnings';

  @override
  String get todayEarnings => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get totalEarningsLabel => 'Total Earnings';

  @override
  String get avgPerDelivery => 'Avg. per Delivery';

  @override
  String get history => 'History';

  @override
  String get noEarningsForPeriod => 'No earnings found for this period';

  @override
  String get navigationAppUpdated => 'Navigation app updated';

  @override
  String navigationPreferenceNotSaved(Object error) {
    return 'Navigation preference could not be saved: $error';
  }

  @override
  String get selectDefaultNavigationApp =>
      'Select the default navigation app you want to use when going to delivery address';

  @override
  String get note => 'Note';

  @override
  String get ifAppNotInstalledSystemWillOfferAlternative =>
      'If the app you selected is not installed, the system will offer you a suitable alternative';

  @override
  String get preferenceOnlyForCourierAccount =>
      'This preference is only valid for your courier account';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotificationsYet =>
      'You don\'t have any notifications yet.\nOrder movements will appear here';

  @override
  String get notificationsLoadFailed => 'Notifications could not be loaded';

  @override
  String notificationProcessingFailed(Object error) {
    return 'Notification processing failed: $error';
  }

  @override
  String get orderDetailTitle => 'Order Detail';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get deliveryLocation => 'Delivery Location';

  @override
  String get orderItems => 'Order Items';

  @override
  String get viewMap => 'View Map';

  @override
  String get deliveryProof => 'Delivery Proof';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get signature => 'Signature';

  @override
  String get notes => 'Notes';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get leftAtFrontDoor => 'Left at front door, etc.';

  @override
  String get submitProofAndCompleteDelivery =>
      'Submit Proof & Complete Delivery';

  @override
  String get pleaseTakePhoto => 'Please take a photo of the delivery';

  @override
  String get pleaseObtainSignature => 'Please obtain a signature';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noDeliveryHistoryYet => 'No delivery history yet';

  @override
  String get pickup => 'Pickup';

  @override
  String get delivery => 'Delivery';

  @override
  String get talabi => 'Talabi';

  @override
  String get navigate => 'Navigate';

  @override
  String couldNotLaunchMaps(Object error) {
    return 'Could not launch maps: $error';
  }

  @override
  String get marketBannerTitle => 'Market Shopping\nat Your Door';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get localityNeighborhood => 'Locality / Neighborhood';

  @override
  String get selectCityDistrictWarning =>
      'Please select City and District from dropdowns to confirm.';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get verificationCodeSentDesc =>
      'Please enter the verification code sent to';

  @override
  String get createPassword => 'Create New Password';

  @override
  String get createPasswordDesc =>
      'Please enter a new password for your account';

  @override
  String get requiredField => 'This field is required';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get codeExpired => 'The code has expired.';

  @override
  String get businessType => 'Business Type';

  @override
  String get businessTypeRequired => 'Business type is required';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get market => 'Market';

  @override
  String get defaultError => 'An error occurred';

  @override
  String get passwordPlaceholder => '******';

  @override
  String get vehicleTypeRequired => 'Vehicle Type is required';

  @override
  String get errorLoginVendorToCustomer =>
      'Cannot login to customer screens with a vendor account.';

  @override
  String get errorLoginCourierToCustomer =>
      'Cannot login to customer screens with a courier account.';

  @override
  String get errorLoginCustomerToVendor =>
      'Cannot login to vendor screens with a customer account.';

  @override
  String get errorLoginCourierToVendor =>
      'Cannot login to vendor screens with a courier account.';

  @override
  String get errorLoginCustomerToCourier =>
      'Cannot login to courier screens with a customer account.';

  @override
  String get errorLoginVendorToCourier =>
      'Cannot login to courier screens with a vendor account.';

  @override
  String get keywordTokenExpired => 'token expired';

  @override
  String get accountPendingApprovalTitle => 'Account Pending Approval';

  @override
  String get accountPendingApprovalMessage =>
      'Your account is currently under review. Access will be granted once your account is approved.';

  @override
  String get vendorStatusNormal => 'Normal';

  @override
  String get vendorStatusBusy => 'Busy';

  @override
  String get vendorStatusOverloaded => 'Overloaded';

  @override
  String get vendorStatusNormalDesc => 'Standard time';

  @override
  String get vendorStatusBusyDesc => '+15 min';

  @override
  String get vendorStatusOverloadedDesc => '+45 min';

  @override
  String get storeStatus => 'Store Status';

  @override
  String get workingHoursRequired => 'Working Hours Required';

  @override
  String get workingHoursRequiredDescription =>
      'Please set your working hours to start receiving orders.';

  @override
  String get workingHoursStart => 'Start Time';

  @override
  String get workingHoursEnd => 'End Time';

  @override
  String get selectTime => 'Select Time';

  @override
  String get workingHoursUpdatedSuccessfully =>
      'Working hours updated successfully';

  @override
  String get failedToUpdateWorkingHours => 'Failed to update working hours';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get workingDays => 'Working Days';

  @override
  String get closed => 'Closed';

  @override
  String get open24Hours => 'Open 24 Hours';

  @override
  String get hours => 'Hours';

  @override
  String get workingHoursDescription =>
      'Manage your business opening days and hours here.';

  @override
  String workingHoursSaveError(Object error) {
    return 'Error saving working hours: $error';
  }

  @override
  String get shamCashAccountNumber => 'Sham Cash Account Number';

  @override
  String get newOffers => 'NEW OFFERS';

  @override
  String get activeDeliveriesSectionTitle => 'ACTIVE DELIVERIES';

  @override
  String get newOrderOffer => 'New Order Offer!';

  @override
  String get viewableAfterAcceptance => 'Viewable after acceptance';

  @override
  String get rejectReasonLabel => 'Please specify the reason for rejection:';

  @override
  String get pleaseEnterReason => 'Please enter a reason';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPickedUp => 'Picked Up';

  @override
  String get statusOutForDelivery => 'Out for Delivery';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get rateOrder => 'Rate Order';

  @override
  String get rateCourier => 'Courier Rating';

  @override
  String get feedbackSubmittedSuccessfully => 'Feedback submitted successfully';

  @override
  String get orderNotDelivered => 'Order not delivered';

  @override
  String get orderAlreadyReviewed => 'Order already reviewed';

  @override
  String get popupTitle => 'Rate Order';

  @override
  String get popupMessage =>
      'How was your last order? Would you like to share your experience?';

  @override
  String get notNow => 'Not Now';

  @override
  String get viewReviews => 'View My Reviews';

  @override
  String get reviewDetail => 'Review Detail';

  @override
  String get status => 'Status';

  @override
  String get transactionDeposit => 'Deposit';

  @override
  String get transactionWithdrawal => 'Withdrawal';

  @override
  String get transactionPayment => 'Payment';

  @override
  String get transactionRefund => 'Refund';

  @override
  String get transactionEarning => 'Earning';

  @override
  String get transactionDetail => 'Transaction Detail';

  @override
  String get viewOrder => 'View Order';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get referenceNo => 'Reference No';

  @override
  String get dateLabel => 'Date';

  @override
  String get amountToWithdraw => 'Amount to Withdraw';

  @override
  String get all => 'All';

  @override
  String get balance => 'Balance';

  @override
  String get savedAccounts => 'Saved Accounts';

  @override
  String get addAccount => 'Add Account';

  @override
  String get accountName => 'Account Name';

  @override
  String get ibanOrAccountNumber => 'IBAN or Account Number';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get selectAccount => 'Select Account';

  @override
  String get accountNameRequired => 'Account name is required';

  @override
  String get ibanRequired => 'IBAN/Account Number is required';

  @override
  String get noSavedAccounts => 'No saved accounts yet';
}

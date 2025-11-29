import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/courier/courier_login_screen.dart';
import 'package:mobile/screens/shared/auth/email_code_verification_screen.dart';
import 'package:mobile/screens/shared/auth/register_screen.dart';
import 'package:mobile/screens/vendor/vendor_login_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';

class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    TapLogger.logButtonPress(
      'Vendor Register',
      context: 'VendorRegisterScreen',
    );

    if (!_formKey.currentState!.validate()) {
      TapLogger.logButtonPress(
        'Vendor Register',
        context: 'VendorRegisterScreen - Validation Failed',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final businessName = _businessNameController.text.trim();
      final phone = _phoneController.text.trim();

      print('🟡 [VENDOR_REGISTER] Calling vendorRegister API');
      print('🟡 [VENDOR_REGISTER] Email: $email');
      print('🟡 [VENDOR_REGISTER] BusinessName: $businessName');
      print('🟡 [VENDOR_REGISTER] FullName: $fullName');
      print('🟡 [VENDOR_REGISTER] Phone: $phone');

      // Get user's language preference
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      final languageCode = localizationProvider.locale.languageCode;

      final apiService = ApiService();
      // Vendor kaydı için API çağrısı - User ve Vendor tablolarına kayıt yapar
      await apiService.vendorRegister(
        email: email,
        password: password,
        fullName: fullName,
        businessName: businessName,
        phone: phone,
        language: languageCode,
      );

      print('🟢 [VENDOR_REGISTER] Register successful!');

      if (mounted) {
        // Email kod doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                EmailCodeVerificationScreen(email: email, password: password),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🔴 [VENDOR_REGISTER] Register error: $e');
      print('🔴 [VENDOR_REGISTER] Stack trace: $stackTrace');

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;

        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;

          if (responseData is Map) {
            if (responseData.containsKey('errors') &&
                responseData['errors'] is List) {
              final errors = responseData['errors'] as List;
              final duplicateError = errors.firstWhere(
                (error) =>
                    error is Map &&
                    (error['code'] == 'DuplicateEmail' ||
                        error['code'] == 'DuplicateUserName'),
                orElse: () => null,
              );

              if (duplicateError != null) {
                errorMessage = localizations.emailAlreadyExists;
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'].toString();
              }
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
            }
          }
        }

        final displayMessage = errorMessage.isNotEmpty
            ? errorMessage
            : localizations.registerFailed;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: localizations.ok,
              textColor: AppTheme.textOnPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.vendorLight,
              AppTheme.vendorPrimary,
              AppTheme.vendorDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Purple Header for Vendor
              Container(
                height: 160,
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -80,
                      right: -60,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.textOnPrimary.withOpacity(0.15),
                              AppTheme.textOnPrimary.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.textOnPrimary.withOpacity(0.12),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content - Row layout
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.textOnPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium + 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person_add_rounded,
                                  size: 24,
                                  color: AppTheme.textOnPrimary,
                                ),
                              ),
                            ),
                            // Center Title
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localizations.vendorRegister,
                                  style: AppTheme.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textOnPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                AppTheme.verticalSpace(0.25),
                                Text(
                                  localizations.talabiBusiness,
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textOnPrimary.withOpacity(
                                      0.85,
                                    ),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            // Right App Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.textOnPrimary,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium + 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.shadowColor,
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.store_rounded,
                                  size: 24,
                                  color: AppTheme.vendorPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // White Card Content
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: AppTheme.spacingLarge - AppTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          AppTheme.radiusXLarge + AppTheme.spacingSmall,
                        ),
                        topRight: Radius.circular(
                          AppTheme.radiusXLarge + AppTheme.spacingSmall,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingLarge),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Welcome Message
                            Row(
                              children: [
                                Icon(
                                  Icons.business_center,
                                  color: AppTheme.vendorPrimary,
                                  size: 32,
                                ),
                                AppTheme.horizontalSpace(0.75),
                                Expanded(
                                  child: Text(
                                    localizations.createBusinessAccount,
                                    style: AppTheme.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppTheme.verticalSpace(0.5),
                            Text(
                              localizations.createYourStoreAndStartSelling,
                              style: AppTheme.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            AppTheme.verticalSpace(1.5),
                            // Business Name Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: TextFormField(
                                controller: _businessNameController,
                                decoration: InputDecoration(
                                  hintText: localizations.businessName,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.store_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.businessNameRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Full Name Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: TextFormField(
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  hintText: localizations.fullName,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.fullNameRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Email Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: localizations.emailAddress,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.emailRequired;
                                  }
                                  if (!value.contains('@')) {
                                    return localizations.validEmail;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Phone Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  hintText: localizations.phoneNumber,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.phoneNumberRequired;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: localizations.password,
                                  hintStyle: AppTheme.poppins(
                                    color: AppTheme.textHint,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppTheme.textSecondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingMedium,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return localizations.passwordRequired;
                                  }
                                  if (value.length < 6) {
                                    return localizations.passwordMinLength;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            AppTheme.verticalSpace(1.5),
                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _register,
                                icon: Icon(
                                  Icons.store,
                                  color: AppTheme.textOnPrimary,
                                  size: 20,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.vendorPrimary,
                                  foregroundColor: AppTheme.textOnPrimary,
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  elevation: AppTheme.elevationNone,
                                ),
                                label: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: AppTheme.textOnPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        localizations.createVendorAccount,
                                        style: AppTheme.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            AppTheme.verticalSpace(1.5),
                            // Already have account
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localizations.alreadyHaveVendorAccount,
                                    style: AppTheme.poppins(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      TapLogger.logButtonPress(
                                        'Vendor Login',
                                        context: 'VendorRegisterScreen',
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VendorLoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      localizations.signIn,
                                      style: AppTheme.poppins(
                                        color: AppTheme.vendorPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Customer Register Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localizations.isCustomerAccount,
                                    style: AppTheme.poppins(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      TapLogger.logButtonPress(
                                        'Customer Register',
                                        context: 'VendorRegisterScreen',
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      localizations.signUp,
                                      style: AppTheme.poppins(
                                        color: AppTheme.primaryOrange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppTheme.verticalSpace(1),
                            // Courier Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localizations.areYouCourier + ' ',
                                    style: AppTheme.poppins(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      TapLogger.logButtonPress(
                                        'Courier Login',
                                        context: 'VendorRegisterScreen',
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CourierLoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      localizations.courierLoginLink,
                                      style: AppTheme.poppins(
                                        color: AppTheme.courierPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

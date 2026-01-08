import 'package:mobile/utils/custom_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/features/auth/presentation/screens/courier/login_screen.dart';
// Todo: Email verification screen OAA
import 'package:mobile/features/onboarding/presentation/screens/auth/email_code_verification_screen.dart';
import 'package:mobile/features/auth/presentation/screens/customer/register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/vendor/login_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';

import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/password_validation_widget.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/widgets/agreement_checkbox.dart';

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
  int _selectedVendorType =
      1; // 1 = Restaurant, 2 = Market (default: Restaurant)
  bool _acceptedAgreement = false;
  bool _acceptedKvkk = false;
  bool _acceptedMarketing = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isPasswordValid(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
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

    final password = _passwordController.text;

    if (!_isPasswordValid(password)) {
      TapLogger.logButtonPress(
        'Vendor Register',
        context: 'VendorRegisterScreen - Password Validation Failed',
      );
      // Show error toast
      final localizations = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: localizations.passwordMinLength,
        isSuccess: false,
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

      LoggerService().debug('🟡 [VENDOR_REGISTER] Calling vendorRegister API');
      LoggerService().debug('🟡 [VENDOR_REGISTER] Email: $email');
      LoggerService().debug('🟡 [VENDOR_REGISTER] BusinessName: $businessName');
      LoggerService().debug('🟡 [VENDOR_REGISTER] FullName: $fullName');
      LoggerService().debug('🟡 [VENDOR_REGISTER] Phone: $phone');

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
        vendorType: _selectedVendorType,
      );

      LoggerService().debug('🟢 [VENDOR_REGISTER] Register successful!');

      if (mounted) {
        // Email kod doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(
            builder: (context) => EmailCodeVerificationScreen(
              email: email,
              password: password,
              userRole: 'Vendor',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        '🔴 [VENDOR_REGISTER] Register error',
        e,
        stackTrace,
      );

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

        ToastMessage.show(
          context,
          message: displayMessage,
          isSuccess: false,
          duration: const Duration(seconds: 7),
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
        decoration: const BoxDecoration(
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
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAuthHeaderDelegate(
                expandedHeight: 150 + MediaQuery.of(context).padding.top,
                collapsedHeight:
                    kToolbarHeight + MediaQuery.of(context).padding.top,
                paddingTop: MediaQuery.of(context).padding.top,
                title: localizations.vendorRegister,
                icon: Icons.store,
                onBack: () {
                  Navigator.pushReplacement(
                    context,
                    NoSlidePageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                margin: const EdgeInsets.only(top: AppTheme.spacingSmall),

                decoration: const BoxDecoration(
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
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Message
                        Row(
                          children: [
                            const Icon(
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
                              prefixIcon: const Icon(
                                Icons.store_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
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
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
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
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.emailRequired;
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return localizations.validEmail;
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
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: localizations.password,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppTheme.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.passwordRequired;
                              }
                              // We use strict validaton in button press, here we check length only to be nice
                              if (value.length < 6) {
                                return localizations.passwordMinLength;
                              }
                              return null;
                            },
                          ),
                        ),
                        AppTheme.verticalSpace(1),
                        // Password Validation Widget
                        if (_passwordController.text.isNotEmpty &&
                            !_isPasswordValid(_passwordController.text))
                          PasswordValidationWidget(
                            password: _passwordController.text,
                          ),
                        AppTheme.verticalSpace(1),
                        // Business Type Selection
                        Text(
                          localizations.businessType,
                          style: AppTheme.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        AppTheme.verticalSpace(0.5),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedVendorType = 1; // Restaurant
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.spacingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedVendorType == 1
                                        ? AppTheme.vendorPrimary.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: _selectedVendorType == 1
                                          ? AppTheme.vendorPrimary
                                          : AppTheme.borderColor,
                                      width: _selectedVendorType == 1 ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant,
                                        color: _selectedVendorType == 1
                                            ? AppTheme.vendorPrimary
                                            : AppTheme.textSecondary,
                                        size: 24,
                                      ),
                                      AppTheme.horizontalSpace(0.5),
                                      Text(
                                        localizations.restaurant,
                                        style: AppTheme.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedVendorType == 1
                                              ? AppTheme.vendorPrimary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            AppTheme.horizontalSpace(1),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedVendorType = 2; // Market
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppTheme.spacingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedVendorType == 2
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: _selectedVendorType == 2
                                          ? Colors.green
                                          : AppTheme.borderColor,
                                      width: _selectedVendorType == 2 ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_basket,
                                        color: _selectedVendorType == 2
                                            ? Colors.green
                                            : AppTheme.textSecondary,
                                        size: 24,
                                      ),
                                      AppTheme.horizontalSpace(0.5),
                                      Text(
                                        localizations.market,
                                        style: AppTheme.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedVendorType == 2
                                              ? Colors.green
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
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
                        AppTheme.verticalSpace(1.5),
                        // Agreements
                        AgreementCheckbox(
                          value: _acceptedAgreement,
                          onChanged: (val) {
                            setState(() => _acceptedAgreement = val ?? false);
                          },
                          agreementKey: 'VendorMembershipAgreement',
                          agreementTitle: localizations.membershipAgreement,
                          linkText: localizations.membershipAgreement,
                          suffixText: localizations.iReadAndAccept,
                          validator: (val) {
                            if (val != true) {
                              return localizations.pleaseAcceptAgreement;
                            }
                            return null;
                          },
                        ),
                        AppTheme.verticalSpace(1),
                        AgreementCheckbox(
                          value: _acceptedKvkk,
                          onChanged: (val) {
                            setState(() => _acceptedKvkk = val ?? false);
                          },
                          agreementKey: 'KvkkDisclosureText',
                          agreementTitle: localizations.kvkkAgreement,
                          linkText: localizations.kvkkAgreement,
                          validator: (val) {
                            if (val != true) {
                              return localizations.pleaseAcceptKvkk;
                            }
                            return null;
                          },
                        ),
                        AppTheme.verticalSpace(1),
                        AgreementCheckbox(
                          value: _acceptedMarketing,
                          onChanged: (val) {
                            setState(() => _acceptedMarketing = val ?? false);
                          },
                          agreementKey: 'MarketingPermissionText',
                          agreementTitle: localizations.marketingPermission,
                          linkText: localizations.marketingPermission,
                          isMandatory: false,
                        ),
                        AppTheme.verticalSpace(2),
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: AppTheme.primaryButtonVendor,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.textOnPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    localizations.createVendorAccount,
                                    style: AppTheme.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textOnPrimary,
                                    ),
                                  ),
                          ),
                        ),
                        AppTheme.verticalSpace(1.5),
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.alreadyHaveVendorAccount,
                              style: AppTheme.poppins(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                TapLogger.logNavigation(
                                  'VendorRegister',
                                  'VendorLogin',
                                );
                                Navigator.pushReplacement(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (context) =>
                                        const VendorLoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                localizations.vendorLogin,
                                style: AppTheme.poppins(
                                  color: AppTheme.vendorPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Switch to Customer Account - Modern Design
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryOrange.withValues(alpha: 0.1),
                                AppTheme.lightOrange.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              onTap: () {
                                TapLogger.logNavigation(
                                  'VendorRegister',
                                  'CustomerRegister',
                                );
                                Navigator.pushReplacement(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMedium,
                                  vertical: AppTheme.spacingSmall + 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: AppTheme.primaryOrange,
                                      size: 20,
                                    ),
                                    AppTheme.horizontalSpace(0.5),
                                    Text(
                                      localizations.isCustomerAccount,
                                      style: AppTheme.poppins(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.25),
                                    Text(
                                      localizations.createAccount,
                                      style: AppTheme.poppins(
                                        color: AppTheme.primaryOrange,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.25),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppTheme.primaryOrange,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Switch to Courier Account - Modern Design
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.courierPrimary.withValues(alpha: 0.1),
                                AppTheme.courierLight.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color: AppTheme.courierPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              onTap: () {
                                TapLogger.logNavigation(
                                  'VendorRegister',
                                  'CourierLogin',
                                );
                                Navigator.pushReplacement(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (context) =>
                                        const CourierLoginScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMedium,
                                  vertical: AppTheme.spacingSmall + 4,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.delivery_dining_rounded,
                                      color: AppTheme.courierPrimary,
                                      size: 20,
                                    ),
                                    AppTheme.horizontalSpace(0.5),
                                    Text(
                                      localizations.areYouCourier,
                                      style: AppTheme.poppins(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.25),
                                    Text(
                                      localizations.courierLoginLink,
                                      style: AppTheme.poppins(
                                        color: AppTheme.courierPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.25),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppTheme.courierPrimary,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAuthHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SliverAuthHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.paddingTop,
    required this.title,
    required this.icon,
    this.onBack,
  });

  final double expandedHeight;
  final double collapsedHeight;
  final double paddingTop;
  final String title;
  final IconData icon;
  final VoidCallback? onBack;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double progress = shrinkOffset / (expandedHeight - collapsedHeight);
    final bool showSticky = progress > 0.8;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sticky Background Gradient (Fades in)
          Opacity(
            opacity: showSticky
                ? ((progress - 0.8) * 5.0).clamp(0.0, 1.0)
                : 0.0,
            child: Container(
              decoration: const BoxDecoration(
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
            ),
          ),

          // Modern Abstract Shapes (Scales/Fades out)
          // Top Right - Large Faded Circle
          Positioned(
            top: -100 - (shrinkOffset * 0.5),
            right: -100 - (shrinkOffset * 0.5),
            child: Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          // Expanded Content (Title + Icon) - Fades out
          Center(
            child: Opacity(
              opacity: (1 - (progress * 1.5)).clamp(0.0, 1.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: AppTheme.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky/Pinned Elements (Always visible but may adapt)
          // Back Button
          if (onBack != null)
            Positioned(
              top: paddingTop + 4,
              left: AppTheme.spacingMedium,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          // Language Selector (Top Right)
          Positioned(
            top: paddingTop + 4,
            right: AppTheme.spacingMedium,
            child: Consumer<LocalizationProvider>(
              builder: (context, provider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerTheme: DividerThemeData(
                        color: Colors.grey.withValues(alpha: 0.2),
                        space: 1,
                        thickness: 1,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      constraints: const BoxConstraints.tightFor(width: 60),
                      elevation: 2,
                      color: Colors.white.withValues(alpha: 0.90),
                      surfaceTintColor: Colors.white,
                      icon: Text(
                        provider.locale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (String code) {
                        provider.setLanguage(code);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'tr',
                              height: 35,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  'TR',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: provider.locale.languageCode == 'tr'
                                        ? const Color(0xFFCE181B)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem<String>(
                              value: 'en',
                              height: 35,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  'EN',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: provider.locale.languageCode == 'en'
                                        ? const Color(0xFFCE181B)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem<String>(
                              value: 'ar',
                              height: 35,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Text(
                                  'AR',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: provider.locale.languageCode == 'ar'
                                        ? const Color(0xFFCE181B)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _SliverAuthHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        paddingTop != oldDelegate.paddingTop ||
        title != oldDelegate.title ||
        icon != oldDelegate.icon;
  }
}

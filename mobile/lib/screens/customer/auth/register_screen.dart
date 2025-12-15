import 'package:mobile/utils/custom_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/screens/customer/auth/email_code_verification_screen.dart';
import 'package:mobile/screens/vendor/auth/register_screen.dart';
import 'package:mobile/screens/courier/auth/register_screen.dart';
import 'package:mobile/services/social_auth_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/password_validation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    TapLogger.logButtonPress('Register', context: 'RegisterScreen');

    if (!_formKey.currentState!.validate()) {
      TapLogger.logButtonPress(
        'Register',
        context: 'RegisterScreen - Validation Failed',
      );
      return;
    }

    final password = _passwordController.text;
    final hasMinLength = password.length >= 6;
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasMinLength ||
        !hasDigit ||
        !hasUppercase ||
        !hasLowercase ||
        !hasSpecialChar) {
      TapLogger.logButtonPress(
        'Register',
        context: 'RegisterScreen - Password Validation Failed',
      );
      // Show error toast
      final localizations = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: localizations
            .passwordMinLength, // Or a more generic "Invalid password" message
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

      LoggerService().debug(
        '🟡 [REGISTER_SCREEN] Calling authProvider.register',
      );
      LoggerService().debug('🟡 [REGISTER_SCREEN] Email: $email');
      LoggerService().debug('🟡 [REGISTER_SCREEN] FullName: $fullName');
      LoggerService().debug(
        '🟡 [REGISTER_SCREEN] Password length: ${password.length}',
      );

      // Get user's language preference
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      final languageCode = localizationProvider.locale.languageCode;

      final apiService = ApiService();
      await apiService.register(
        email,
        password,
        fullName,
        language: languageCode,
      );

      LoggerService().debug('🟢 [REGISTER_SCREEN] Register successful!');

      if (mounted) {
        // Email kod doğrulama ekranına yönlendir (password ile otomatik login için)
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(
            builder: (context) => EmailCodeVerificationScreen(
              email: email,
              password: password, // Otomatik login için password geçiliyor
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        '🔴 [REGISTER_SCREEN] Register error',
        e,
        stackTrace,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;

        // Hata mesajını parse et
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;

          // Duplicate email/username hatası için özel mesaj
          if (responseData is Map) {
            String? specificError;

            // 1. Check for 'errors' object
            if (responseData.containsKey('errors')) {
              final errors = responseData['errors'];

              // Case A: Errors is a List (e.g. DuplicateEmail)
              if (errors is List) {
                final duplicateError = errors.firstWhere(
                  (error) =>
                      error is Map &&
                      (error['code'] == 'DuplicateEmail' ||
                          error['code'] == 'DuplicateUserName'),
                  orElse: () => null,
                );

                if (duplicateError != null) {
                  specificError = localizations.duplicateEmail;
                }
              }
              // Case B: Errors is a Map (Validation errors)
              else if (errors is Map) {
                // Check for 'Password' or 'password' key
                final passwordErrors = errors['Password'] ?? errors['password'];

                if (passwordErrors != null) {
                  if (passwordErrors is List) {
                    specificError = passwordErrors.join('\n');
                  } else {
                    specificError = passwordErrors.toString();
                  }
                }

                // If no password specific error, look for other errors
                if (specificError == null && errors.isNotEmpty) {
                  final List<String> errorMessages = [];
                  errors.forEach((key, value) {
                    if (value is List) {
                      errorMessages.addAll(value.map((e) => e.toString()));
                    } else {
                      errorMessages.add(value.toString());
                    }
                  });
                  if (errorMessages.isNotEmpty) {
                    specificError = errorMessages.join('\n');
                  }
                }
              }
            }

            // 2. Set errorMessage
            if (specificError != null) {
              errorMessage = specificError;
            } else if (responseData.containsKey('message')) {
              // Fallback to generic message if no specific error found
              errorMessage = responseData['message'].toString();
            }
          }
        }

        // Hata mesajını göster - kod ekranına yönlendirme YOK
        final displayMessage = errorMessage.isNotEmpty
            ? errorMessage
            : localizations.registerFailed;

        ToastMessage.show(
          context,
          message: displayMessage,
          isSuccess: false,
          duration: const Duration(seconds: 7),
        );

        // Hata durumunda ekranda kal - kod giriş ekranına yönlendirme YOK
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final socialAuthService = SocialAuthService();
      final response = await socialAuthService.signInWithGoogle();

      if (response == null) {
        // User cancelled
        return;
      }

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('refreshToken', response['refreshToken']);
      await prefs.setString('userId', response['userId']);
      await prefs.setString('userRole', response['role']);

      if (mounted) {
        // Update auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setAuthData(
          response['token'],
          response['refreshToken'],
          response['userId'],
          response['role'],
        );

        if (!mounted) return;

        // Navigate based on role
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e, stackTrace) {
      LoggerService().error('🔴 [GOOGLE_LOGIN] Error', e, stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.googleLoginFailed(e.toString()),
          isSuccess: false,
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

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final socialAuthService = SocialAuthService();
      final response = await socialAuthService.signInWithFacebook();

      if (response == null) {
        // User cancelled
        return;
      }

      // Save tokens
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('refreshToken', response['refreshToken']);
      await prefs.setString('userId', response['userId']);
      await prefs.setString('userRole', response['role']);

      if (mounted) {
        // Update auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.setAuthData(
          response['token'],
          response['refreshToken'],
          response['userId'],
          response['role'],
        );

        if (!mounted) return;

        // Navigate based on role
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e, stackTrace) {
      LoggerService().error('🔴 [FACEBOOK_LOGIN] Error', e, stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.facebookLoginFailed(e.toString()),
          isSuccess: false,
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
              AppTheme.lightOrange,
              AppTheme.primaryOrange,
              AppTheme.darkOrange,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with modern decorative shapes
            AuthHeader(
              title: localizations.signUp,
              icon: Icons.shopping_bag_outlined,
            ),
            // White Card Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Container(
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
                                Text(
                                  localizations.createAccount,
                                  style: AppTheme.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  localizations.registerDescription,
                                  style: AppTheme.poppins(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText: localizations.fullName,
                                      hintStyle: AppTheme.poppins(
                                        color: AppTheme.textHint,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      prefixIconColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.error,
                                                )
                                                ? AppTheme.error
                                                : AppTheme.textSecondary,
                                          ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                const SizedBox(height: 10),
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
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      hintText: localizations.emailAddress,
                                      hintStyle: AppTheme.poppins(
                                        color: AppTheme.textHint,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      prefixIconColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.error,
                                                )
                                                ? AppTheme.error
                                                : AppTheme.textSecondary,
                                          ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
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
                                      ),
                                      prefixIconColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.error,
                                                )
                                                ? AppTheme.error
                                                : AppTheme.textSecondary,
                                          ),
                                      suffixIconColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.error,
                                                )
                                                ? AppTheme.error
                                                : AppTheme.textSecondary,
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
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                const SizedBox(height: 12),
                                // Password Validation Widget
                                if (_passwordController.text.isNotEmpty)
                                  PasswordValidationWidget(
                                    password: _passwordController.text,
                                  ),
                                const SizedBox(height: 12),
                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? () {} : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryOrange,
                                      foregroundColor: AppTheme.textOnPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spacingMedium,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMedium,
                                        ),
                                      ),
                                      elevation: AppTheme.elevationNone,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: AppTheme.textOnPrimary,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            localizations.signUp,
                                            style: AppTheme.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Or continue with separator
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: AppTheme.dividerColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingMedium,
                                      ),
                                      child: Text(
                                        localizations.orContinueWith,
                                        style: AppTheme.poppins(
                                          color: AppTheme.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: AppTheme.dividerColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Social Login Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSocialButton(
                                        icon: Icons.g_mobiledata,
                                        label: localizations.google,
                                        onPressed: _signInWithGoogle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSocialButton(
                                        icon: Icons.facebook,
                                        label: localizations.facebook,
                                        onPressed: _signInWithFacebook,
                                        isFacebook: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSocialButton(
                                        icon: Icons.store,
                                        label: localizations.vendor,
                                        onPressed: () {
                                          TapLogger.logButtonPress(
                                            'Vendor Register',
                                            context: 'RegisterScreen',
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            NoSlidePageRoute(
                                              builder: (context) =>
                                                  const VendorRegisterScreen(),
                                            ),
                                          );
                                        },
                                        isVendor: true,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSocialButton(
                                        icon: Icons.motorcycle,
                                        label: localizations.roleCourier,
                                        onPressed: () {
                                          TapLogger.logButtonPress(
                                            'Courier Register',
                                            context: 'RegisterScreen',
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            NoSlidePageRoute(
                                              builder: (context) =>
                                                  const CourierRegisterScreen(),
                                            ),
                                          );
                                        },
                                        isCourier: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Login Link - Modern Design
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryOrange.withValues(
                                          alpha: 0.1,
                                        ),
                                        AppTheme.lightOrange.withValues(
                                          alpha: 0.05,
                                        ),
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
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingMedium,
                                          vertical: AppTheme.spacingMedium,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.login_rounded,
                                              color: AppTheme.primaryOrange,
                                              size: 20,
                                            ),
                                            AppTheme.horizontalSpace(0.5),
                                            Text(
                                              localizations.alreadyHaveAccount,
                                              style: AppTheme.poppins(
                                                color: AppTheme.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            AppTheme.horizontalSpace(0.25),
                                            Text(
                                              localizations.signIn,
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
                                AppTheme.verticalSpace(1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isFacebook = false,
    bool isVendor = false,
    bool isCourier = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSmall + 4,
        ),
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        backgroundColor: AppTheme.cardColor,
      ),
      child: isFacebook
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'f',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTheme.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : isVendor
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.store,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTheme.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : isCourier
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon, // Icons.motorcycle passed in
                  color: AppTheme.courierPrimary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTheme.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon == Icons.g_mobiledata)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4285F4),
                              Color(0xFF34A853),
                              Color(0xFFFBBC05),
                              Color(0xFFEA4335),
                            ],
                            stops: [0.0, 0.33, 0.66, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(icon, color: AppTheme.textPrimary, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTheme.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

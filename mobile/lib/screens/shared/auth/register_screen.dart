import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/screens/shared/auth/email_code_verification_screen.dart';
import 'package:mobile/screens/vendor/vendor_register_screen.dart';
import 'package:mobile/services/social_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();

      print('🟡 [REGISTER_SCREEN] Calling authProvider.register');
      print('🟡 [REGISTER_SCREEN] Email: $email');
      print('🟡 [REGISTER_SCREEN] FullName: $fullName');
      print('🟡 [REGISTER_SCREEN] Password length: ${password.length}');

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

      print('🟢 [REGISTER_SCREEN] Register successful!');

      if (mounted) {
        // Email kod doğrulama ekranına yönlendir (password ile otomatik login için)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailCodeVerificationScreen(
              email: email,
              password: password, // Otomatik login için password geçiliyor
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🔴 [REGISTER_SCREEN] Register error: $e');
      print('🔴 [REGISTER_SCREEN] Stack trace: $stackTrace');

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;

        // Hata mesajını parse et
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;

          // Duplicate email/username hatası için özel mesaj
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
                errorMessage =
                    'Bu email adresi ile zaten bir hesap bulunmaktadır.';
              } else if (responseData.containsKey('message')) {
                errorMessage = responseData['message'].toString();
              }
            } else if (responseData.containsKey('message')) {
              errorMessage = responseData['message'].toString();
            }
          }
        }

        // Hata mesajını göster - kod ekranına yönlendirme YOK
        final displayMessage = errorMessage.isNotEmpty
            ? errorMessage
            : localizations.registerFailed;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
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

        // Navigate based on role
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('🔴 [GOOGLE_LOGIN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google login failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
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

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final socialAuthService = SocialAuthService();
      final response = await socialAuthService.signInWithApple();

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

        // Navigate based on role
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('🔴 [APPLE_LOGIN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple login failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
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

        // Navigate based on role
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('🔴 [FACEBOOK_LOGIN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook login failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
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
              AppTheme.lightOrange,
              AppTheme.primaryOrange,
              AppTheme.darkOrange,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with decorative shapes
              Container(
                height: 180,
                child: Stack(
                  children: [
                    // Decorative shape in top right
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.lightOrange.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Decorative shape on left side (rounded pill shape)
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(
                              AppTheme.radiusXLarge * 2,
                            ),
                            bottomRight: Radius.circular(
                              AppTheme.radiusXLarge * 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Title - Centered
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: AppTheme.spacingXLarge + AppTheme.spacingSmall,
                        ),
                        child: Text(
                          localizations.signUp,
                          style: AppTheme.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textOnPrimary,
                          ),
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
                            Text(
                              localizations.createAccount,
                              style: AppTheme.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            AppTheme.verticalSpace(0.5),
                            Text(
                              localizations.registerDescription,
                              style: AppTheme.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            AppTheme.verticalSpace(2),
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
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryOrange,
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
                                child: _isLoading
                                    ? SizedBox(
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
                            AppTheme.verticalSpace(2),
                            // Or continue with separator
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: AppTheme.dividerColor),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
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
                                Expanded(
                                  child: Divider(color: AppTheme.dividerColor),
                                ),
                              ],
                            ),
                            AppTheme.verticalSpace(1.5),
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
                                    icon: Icons.apple,
                                    label: localizations.apple,
                                    onPressed: _signInWithApple,
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
                                    label: 'Vendor',
                                    onPressed: () {
                                      TapLogger.logButtonPress(
                                        'Vendor Register',
                                        context: 'RegisterScreen',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VendorRegisterScreen(),
                                        ),
                                      );
                                    },
                                    isVendor: true,
                                  ),
                                ),
                              ],
                            ),
                            AppTheme.verticalSpace(2),
                            // Login Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localizations.alreadyHaveAccount,
                                    style: AppTheme.poppins(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      localizations.signIn,
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isFacebook = false,
    bool isVendor = false,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall + 4),
        side: BorderSide(color: AppTheme.borderColor),
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
                Icon(Icons.store, color: AppTheme.primaryOrange, size: 20),
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

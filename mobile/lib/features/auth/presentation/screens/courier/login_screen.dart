import 'package:mobile/utils/custom_routes.dart';
import 'package:mobile/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/presentation/screens/courier_dashboard_screen.dart';
import 'package:mobile/features/auth/presentation/screens/courier/register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/customer/login_screen.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:mobile/utils/role_mismatch_exception.dart';
import 'package:mobile/widgets/toast_message.dart';

class CourierLoginScreen extends StatefulWidget {
  const CourierLoginScreen({super.key});

  @override
  State<CourierLoginScreen> createState() => _CourierLoginScreenState();
}

class _CourierLoginScreenState extends State<CourierLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    TapLogger.logButtonPress('Courier Login', context: 'CourierLoginScreen');
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        requiredRole: 'Courier',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(
            builder: (context) => const CourierDashboardScreen(),
          ),
        );
      }
    } on RoleMismatchException catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          String message = localizations.defaultError;
          final actualRole = e.actualRole.toLowerCase();

          if (actualRole.contains('vendor')) {
            message = localizations.errorLoginVendorToCourier;
          } else if (actualRole.contains('customer')) {
            message = localizations.errorLoginCustomerToCourier;
          } else {
            message = '$message (${e.actualRole})';
          }

          ToastMessage.show(context, message: message, isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ToastMessage.show(
          context,
          message: '${localizations?.loginFailed ?? "Login Failed"}: $e',
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
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.courierLight,
              AppTheme.courierPrimary,
              AppTheme.courierDark,
            ],
          ),
        ),
        child: Column(
          children: [
            // Courier Header (Teal/Turkuaz)
            AuthHeader(
              title: localizations?.courierLogin ?? 'Courier Login',
              icon: Icons.delivery_dining,
              useCircleBackButton: true,
              onBack: () {
                Navigator.pushReplacement(
                  context,
                  NoSlidePageRoute(builder: (context) => const LoginScreen()),
                );
              },
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
                        margin: const EdgeInsets.only(
                          top: AppTheme.spacingLarge - AppTheme.spacingXSmall,
                        ),
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
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Message
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.two_wheeler,
                                      color: AppTheme.courierPrimary,
                                      size: 32,
                                    ),
                                    AppTheme.horizontalSpace(0.75),
                                    Expanded(
                                      child: Text(
                                        localizations?.courierWelcome ??
                                            'Welcome Back, Courier!',
                                        style: AppTheme.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppTheme.verticalSpace(0.5),
                                Text(
                                  localizations?.courierSubtitle ??
                                      'Sign in to manage your deliveries',
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                AppTheme.verticalSpace(2),
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
                                      hintText:
                                          localizations?.emailAddress ??
                                          'Email Address',
                                      hintStyle: AppTheme.poppins(
                                        color: AppTheme.textHint,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: AppTheme.textSecondary,
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
                                        return localizations?.emailRequired ??
                                            'Email is required';
                                      }
                                      final emailRegex = RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      );
                                      if (!emailRegex.hasMatch(value)) {
                                        return localizations?.validEmail ??
                                            'Please enter a valid email';
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
                                      hintText:
                                          localizations?.password ?? 'Password',
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
                                        return localizations
                                                ?.passwordRequired ??
                                            'Password is required';
                                      }
                                      if (value.length < 6) {
                                        return localizations
                                                ?.passwordMinLength ??
                                            'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                AppTheme.verticalSpace(1),
                                // Remember me and Recovery Password
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: AppTheme.courierPrimary,
                                        ),
                                        Text(
                                          localizations?.rememberMe ??
                                              'Remember me?',
                                          style: AppTheme.poppins(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/courier/forgot-password',
                                        );
                                      },
                                      child: Text(
                                        localizations?.recoveryPassword ??
                                            'Recovery Password',
                                        style: AppTheme.poppins(
                                          color: AppTheme.courierPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                AppTheme.verticalSpace(1.5),
                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _login,
                                    icon: const Icon(
                                      Icons.delivery_dining,
                                      color: AppTheme.textOnPrimary,
                                      size: 20,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.courierPrimary,
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
                                    label: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: AppTheme.textOnPrimary,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            localizations?.courierSignIn ??
                                                'Courier Sign In',
                                            style: AppTheme.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                AppTheme.verticalSpace(1.5),
                                // Register Link - Modern Design
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.courierPrimary.withValues(
                                          alpha: 0.1,
                                        ),
                                        AppTheme.courierLight.withValues(
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
                                        TapLogger.logButtonPress(
                                          'Courier Register',
                                          context: 'CourierLoginScreen',
                                        );
                                        TapLogger.logNavigation(
                                          'CourierLoginScreen',
                                          'CourierRegisterScreen',
                                        );
                                        Navigator.push(
                                          context,
                                          NoSlidePageRoute(
                                            builder: (context) =>
                                                const CourierRegisterScreen(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingMedium,
                                          vertical: AppTheme.spacingSmall + 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person_add_outlined,
                                              color: AppTheme.courierPrimary,
                                              size: 20,
                                            ),
                                            AppTheme.horizontalSpace(0.5),
                                            Text(
                                              localizations?.dontHaveAccount ??
                                                  "Don't have an account? ",
                                              style: AppTheme.poppins(
                                                color: AppTheme.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              localizations?.register ??
                                                  'Register',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

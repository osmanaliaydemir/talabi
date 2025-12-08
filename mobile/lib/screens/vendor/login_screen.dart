import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/customer/auth/login_screen.dart';
import 'package:mobile/screens/vendor/dashboard_screen.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
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

    TapLogger.logButtonPress('Vendor Login', context: 'VendorLoginScreen');
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const VendorDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();

        // Hata mesajını temizle
        if (e is DioException) {
          errorMessage = e.message ?? e.error?.toString() ?? 'Bir hata oluştu';
        } else if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), // Direkt hatayı göster
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
      extendBody: false,
      bottomNavigationBar: null,
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
              // Vendor Header (Purple/Mor)
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    // Back Button - Sol üst köşe
                    Positioned(
                      top: AppTheme.spacingMedium,
                      left: AppTheme.spacingMedium,
                      child: _buildCircleButton(
                        icon: Icons.arrow_back,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    // Decorative shape in top right
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.vendorLight.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Decorative shape on left side
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.vendorPrimary,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store,
                              color: AppTheme.textOnPrimary,
                              size: 36,
                            ),
                            AppTheme.horizontalSpace(0.75),
                            Text(
                              localizations.vendorLogin,
                              style: AppTheme.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textOnPrimary,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
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
                                          localizations.welcomeBackVendor,
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
                                    localizations.vendorLoginDescription,
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
                                        hintText: localizations.emailAddress,
                                        hintStyle: AppTheme.poppins(
                                          color: AppTheme.textHint,
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.business_outlined,
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
                                              _obscurePassword =
                                                  !_obscurePassword;
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
                                          return localizations
                                              .passwordMinLength;
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
                                            activeColor: AppTheme.vendorPrimary,
                                          ),
                                          Text(
                                            localizations.rememberMe,
                                            style: AppTheme.poppins(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Forgot password for vendors
                                        },
                                        child: Text(
                                          localizations.recoveryPassword,
                                          style: AppTheme.poppins(
                                            color: AppTheme.vendorPrimary,
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
                                              localizations.vendorLogin,
                                              style: AppTheme.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  AppTheme.verticalSpace(1.5),
                                  // Customer Login Link - Modern Design
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
                                        color: AppTheme.primaryOrange
                                            .withValues(alpha: 0.3),
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
                                            'Customer Login',
                                            context: 'VendorLoginScreen',
                                          );
                                          TapLogger.logNavigation(
                                            'VendorLoginScreen',
                                            'LoginScreen',
                                          );
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const LoginScreen(),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingMedium,
                                            vertical: AppTheme.spacingSmall + 4,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.shopping_bag_outlined,
                                                color: AppTheme.primaryOrange,
                                                size: 20,
                                              ),
                                              AppTheme.horizontalSpace(0.5),
                                              Text(
                                                '${localizations.areYouCustomer} ',
                                                style: AppTheme.poppins(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                localizations.signIn,
                                                style: AppTheme.poppins(
                                                  color: AppTheme.primaryOrange,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              AppTheme.horizontalSpace(0.25),
                                              Icon(
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
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

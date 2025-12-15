import 'package:mobile/utils/custom_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/courier/auth/login_screen.dart';
import 'package:mobile/screens/customer/auth/email_code_verification_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:mobile/screens/customer/auth/register_screen.dart';

class CourierRegisterScreen extends StatefulWidget {
  const CourierRegisterScreen({super.key});

  @override
  State<CourierRegisterScreen> createState() => _CourierRegisterScreenState();
}

class _CourierRegisterScreenState extends State<CourierRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  int? _selectedVehicleType;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    TapLogger.logButtonPress(
      'Courier Register',
      context: 'CourierRegisterScreen',
    );

    if (!_formKey.currentState!.validate()) {
      TapLogger.logButtonPress(
        'Courier Register',
        context: 'CourierRegisterScreen - Validation Failed',
      );
      return;
    }

    if (_selectedVehicleType == null) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.vehicleTypeRequired),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();

      LoggerService().debug(
        '🟡 [COURIER_REGISTER] Calling courierRegister API',
      );
      LoggerService().debug('🟡 [COURIER_REGISTER] Email: $email');
      LoggerService().debug('🟡 [COURIER_REGISTER] FullName: $fullName');
      LoggerService().debug('🟡 [COURIER_REGISTER] Phone: $phone');
      LoggerService().debug(
        '🟡 [COURIER_REGISTER] VehicleType: $_selectedVehicleType',
      );

      // Get user's language preference
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      final languageCode = localizationProvider.locale.languageCode;

      final apiService = ApiService();
      // Courier kaydı için API çağrısı - User ve Courier tablolarına kayıt yapar
      await apiService.courierRegister(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        vehicleType: _selectedVehicleType!,
        language: languageCode,
      );

      LoggerService().debug('🟢 [COURIER_REGISTER] Register successful!');

      if (mounted) {
        // Email kod doğrulama ekranına yönlendir
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(
            builder: (context) =>
                EmailCodeVerificationScreen(email: email, password: password),
          ),
        );
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        '🔴 [COURIER_REGISTER] Register error',
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
            SizedBox(
              height: 180 + MediaQuery.of(context).padding.top,
              child: Stack(
                children: [
                  // Modern Abstract Shapes
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
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
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: AppTheme.spacingMedium,
                    child: _buildCircleButton(
                      icon: Icons.arrow_back,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          NoSlidePageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  // Title Content
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            localizations.courierRegister,
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
                                        localizations.createCourierAccount,
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
                                  localizations.startDeliveringToday,
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                AppTheme.verticalSpace(1.5),
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
                                      if (value.length < 6) {
                                        return localizations.passwordMinLength;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                AppTheme.verticalSpace(1),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingMedium,
                                            vertical: AppTheme.spacingMedium,
                                          ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return localizations
                                            .phoneNumberRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                AppTheme.verticalSpace(1.5),

                                // Vehicle Type Selection
                                Text(
                                  localizations.vehicleType,
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
                                      child: _buildVehicleOption(
                                        icon: Icons.two_wheeler,
                                        label: localizations.motorcycle,
                                        value: 1,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.5),
                                    Expanded(
                                      child: _buildVehicleOption(
                                        icon: Icons.directions_car,
                                        label: localizations.car,
                                        value: 2,
                                      ),
                                    ),
                                    AppTheme.horizontalSpace(0.5),
                                    Expanded(
                                      child: _buildVehicleOption(
                                        icon: Icons.pedal_bike,
                                        label: localizations.bicycle,
                                        value: 3,
                                      ),
                                    ),
                                  ],
                                ),
                                AppTheme.verticalSpace(2),
                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _register,
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
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppTheme.textOnPrimary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            localizations.createCourierAccount,
                                            style: AppTheme.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
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
                                      localizations.alreadyHaveCourierAccount,
                                      style: AppTheme.poppins(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        TapLogger.logNavigation(
                                          'CourierRegister',
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
                                      child: Text(
                                        localizations.courierSignIn,
                                        style: AppTheme.poppins(
                                          color: AppTheme.courierPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildVehicleOption({
    required IconData icon,
    required String label,
    required int value,
  }) {
    final isSelected = _selectedVehicleType == value;
    final color = isSelected ? AppTheme.courierPrimary : AppTheme.textSecondary;
    final bgColor = isSelected
        ? AppTheme.courierPrimary.withValues(alpha: 0.1)
        : AppTheme.backgroundColor;
    final borderColor = isSelected
        ? AppTheme.courierPrimary
        : AppTheme.borderColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
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

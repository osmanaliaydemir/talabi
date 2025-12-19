import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/widgets/password_validation_widget.dart';
import 'package:mobile/widgets/auth_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  final String email;
  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCodeExpired = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

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
      final localizations = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: localizations.passwordMinLength,
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.resetPassword(
        widget.email,
        widget.token,
        _passwordController.text,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.passwordResetSuccess,
          isSuccess: true,
        );

        // Navigate to login screen and remove all previous routes
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        // Check for expiration keywords
        if (errorMsg.toLowerCase().contains('expire') ||
            errorMsg.toLowerCase().contains(
              'süresi',
            ) || // Turkish 'duration/time' often used in 'expired' contexts
            errorMsg.contains('410') || // Gone
            errorMsg.toLowerCase().contains('invalid token')) {
          setState(() {
            _isCodeExpired = true;
          });
        }

        ToastMessage.show(
          context,
          message: errorMsg.replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            // Header
            AuthHeader(
              title: localizations.createPassword,
              icon: Icons.lock_reset,
              onBack: () => Navigator.pop(context),
              useCircleBackButton: true,
            ),
            // White Card Content
            Expanded(
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
                child: SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Description
                        Text(
                          localizations.createPasswordDesc,
                          style: AppTheme.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

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
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: localizations.newPassword,
                              labelStyle: AppTheme.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              hintText: localizations.passwordPlaceholder,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              prefixIconColor: WidgetStateColor.resolveWith(
                                (states) => states.contains(WidgetState.error)
                                    ? AppTheme.error
                                    : AppTheme.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.requiredField;
                              }
                              if (value.length < 6) {
                                return localizations.passwordMinLength;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_passwordController.text.isNotEmpty)
                          PasswordValidationWidget(
                            password: _passwordController.text,
                          ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: localizations.confirmNewPassword,
                              labelStyle: AppTheme.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                              hintText: localizations.passwordPlaceholder,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                              prefixIconColor: WidgetStateColor.resolveWith(
                                (states) => states.contains(WidgetState.error)
                                    ? AppTheme.error
                                    : AppTheme.textSecondary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.requiredField;
                              }
                              if (value != _passwordController.text) {
                                return localizations.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submit Button or Expired Message
                        if (_isCodeExpired)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  localizations.codeExpired,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: AppTheme.textOnPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
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
                                      localizations.resetPassword,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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

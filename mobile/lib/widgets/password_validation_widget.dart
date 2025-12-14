import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

class PasswordValidationWidget extends StatelessWidget {
  final String password;

  const PasswordValidationWidget({super.key, required this.password});

  bool get _hasMinLength => password.length >= 6;
  bool get _hasDigit => password.contains(RegExp(r'[0-9]'));
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasSpecialChar =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRuleItem(
            label: localizations.passwordRuleChars,
            isValid: _hasMinLength,
          ),
          const SizedBox(height: 4),
          _buildRuleItem(
            label: localizations.passwordRuleDigit,
            isValid: _hasDigit,
          ),
          const SizedBox(height: 4),
          _buildRuleItem(
            label: localizations.passwordRuleUpper,
            isValid: _hasUppercase,
          ),
          const SizedBox(height: 4),
          _buildRuleItem(
            label: localizations.passwordRuleLower,
            isValid: _hasLowercase,
          ),
          const SizedBox(height: 4),
          _buildRuleItem(
            label: localizations.passwordRuleSpecial,
            isValid: _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({required String label, required bool isValid}) {
    // If password is empty, show red (invalid) as per user request to start red?
    // User said: "klavyeden yazdığında kurallara uyuyorsa uyguğu bölüm yeşil olsun uymadıkları kırmızı kalsın"
    // (When typing, if it complies turn green, if not stay red).
    // This implies starting red is acceptable or expected.

    final color = isValid ? AppTheme.success : AppTheme.error;
    final icon = isValid ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTheme.poppins(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}

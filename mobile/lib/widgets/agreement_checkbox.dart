import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';

class AgreementCheckbox extends StatelessWidget {
  const AgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.agreementKey,
    required this.agreementTitle,
    this.prefixText,
    required this.linkText,
    this.suffixText,
    this.isMandatory = true,
    this.validator,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String agreementKey;
  final String agreementTitle;
  final String? prefixText;
  final String linkText;
  final String? suffixText;
  final bool isMandatory;
  final FormFieldValidator<bool>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: value,
      validator:
          validator ??
          (val) {
            if (isMandatory && (val != true)) {
              return AppLocalizations.of(context)!.pleaseAcceptAgreement;
            }
            return null;
          },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: Checkbox(
                    value: value,
                    onChanged: (val) {
                      onChanged(val);
                      state.didChange(val);
                    },
                    activeColor: AppTheme.primaryOrange,
                    side: const BorderSide(
                      color: AppTheme.borderColor,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.poppins(
                        fontSize: 11,
                        color: AppTheme.textPrimary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      children: [
                        if (prefixText != null) TextSpan(text: '$prefixText '),
                        TextSpan(
                          text: linkText,
                          style: AppTheme.poppins(
                            fontSize: 11,
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _showAgreementDialog(context, state),
                        ),
                        if (suffixText != null) TextSpan(text: ' $suffixText'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 4),
                child: Text(
                  state.errorText!,
                  style: AppTheme.poppins(fontSize: 12, color: AppTheme.error),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAgreementDialog(
    BuildContext context,
    FormFieldState<bool> state,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _AgreementDialog(agreementKey: agreementKey, title: agreementTitle),
    );

    if (accepted == true) {
      onChanged(true);
      state.didChange(true);
    }
  }
}

class _AgreementDialog extends StatefulWidget {
  const _AgreementDialog({required this.agreementKey, required this.title});
  final String agreementKey;
  final String title;
  @override
  State<_AgreementDialog> createState() => _AgreementDialogState();
}

class _AgreementDialogState extends State<_AgreementDialog> {
  String? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final apiService = ApiService();
      final content = await apiService.getSystemSetting(widget.agreementKey);
      if (mounted) {
        setState(() {
          _content = content ?? 'İçerik Bulunamadı.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getAcceptButtonText(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    // Temizleme işlemi (eğer başlık "okudum ve kabul ediyorum" gibi ekler içeriyorsa)
    String cleanTitle = widget.title;
    if (lang == 'tr') {
      cleanTitle = cleanTitle
          .replaceAll('\'ni okudum', '')
          .replaceAll('\'ı okudum', '')
          .replaceAll(' okudum', '')
          .replaceAll(' okudum ve kabul ediyorum', '')
          .trim();
      return "$cleanTitle'nı Kabul Et";
    }

    return '${localizations.accept} $cleanTitle';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTheme.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : SingleChildScrollView(
                      child: Text(
                        _content!,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  _getAcceptButtonText(context),
                  textAlign: TextAlign.center,
                  style: AppTheme.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

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
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: value,
                    onChanged: (val) {
                      onChanged(val);
                      state.didChange(val);
                    },
                    activeColor: AppTheme.primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      children: [
                        if (prefixText != null) TextSpan(text: '$prefixText '),
                        TextSpan(
                          text: linkText,
                          style: AppTheme.poppins(
                            fontSize: 12,
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showAgreementDialog(context),
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

  void _showAgreementDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) =>
          _AgreementDialog(agreementKey: agreementKey, title: agreementTitle),
    );
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: AppTheme.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

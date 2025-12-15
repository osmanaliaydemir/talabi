import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/screens/vendor/auth/vendor_reset_password_screen.dart';
import 'package:mobile/widgets/auth_header.dart';

class VendorVerifyResetCodeScreen extends StatefulWidget {
  const VendorVerifyResetCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VendorVerifyResetCodeScreen> createState() =>
      _VendorVerifyResetCodeScreenState();
}

class _VendorVerifyResetCodeScreenState
    extends State<VendorVerifyResetCodeScreen> {
  final _apiService = ApiService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  Timer? _timer;
  int _secondsRemaining = 180; // 3 minutes
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 180;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _verifyCode() async {
    final String code = _controllers.map((e) => e.text).join();
    if (code.length != 6) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _apiService.verifyResetCode(widget.email, code);

      if (mounted) {
        // Navigate to Vendor Reset Password Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VendorResetPasswordScreen(email: widget.email, token: token),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final localizations = AppLocalizations.of(context)!;
      final languageCode = localizations.localeName;

      await _apiService.forgotPassword(widget.email, language: languageCode);

      _startTimer();

      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.verificationCodeResent,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
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
              AppTheme.vendorLight,
              AppTheme.vendorPrimary,
              AppTheme.vendorDark,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            AuthHeader(
              title: localizations.verificationCode,
              icon: Icons.lock_clock_outlined,
              onBack: () => Navigator.pop(context),
              useCircleBackButton: true,
            ),
            // Main Content Card
            Expanded(
              child: Container(
                width: double.infinity,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Subtitle
                      Text(
                        '${localizations.verificationCodeSentDesc} ${widget.email}',
                        textAlign: TextAlign.center,
                        style: AppTheme.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Code Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 44,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.vendorPrimary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    _focusNodes[index].unfocus();
                                    _verifyCode();
                                  }
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Resend Timer
                      if (!_canResend)
                        Text(
                          '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppTheme.vendorPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      if (_canResend)
                        TextButton(
                          onPressed: _isLoading ? null : _resendCode,
                          child: Text(
                            localizations.resendCode,
                            style: const TextStyle(
                              color: AppTheme.vendorPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Verify Button or Expired Message
                      if (_secondsRemaining == 0)
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
                            onPressed: _isLoading ? null : _verifyCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.vendorPrimary,
                              foregroundColor: AppTheme.textOnPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    localizations.verify,
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
          ],
        ),
      ),
    );
  }
}

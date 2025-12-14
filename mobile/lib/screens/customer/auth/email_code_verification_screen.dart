import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/services.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/auth/login_screen.dart';
import 'package:mobile/screens/shared/onboarding/main_navigation_screen.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

class EmailCodeVerificationScreen extends StatefulWidget {
  const EmailCodeVerificationScreen({
    super.key,
    required this.email,
    this.password,
  });
  final String email;
  final String? password; // Optional: for auto-login after verification

  @override
  State<EmailCodeVerificationScreen> createState() =>
      _EmailCodeVerificationScreenState();
}

class _EmailCodeVerificationScreenState
    extends State<EmailCodeVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isResending = false;
  Timer? _timer;
  int _remainingSeconds = 180; // 3 dakika = 180 saniye
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // İlk input'a focus ver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _remainingSeconds = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1) {
      // Bir sonraki input'a geç
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Son input'a geldiğinde klavyeyi kapat
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    } else if (value.isEmpty && index > 0) {
      // Geri tuşuna basıldığında önceki input'a geç
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyCode() async {
    final localizations = AppLocalizations.of(context)!;
    final code = _getCode();
    if (code.length != 4) {
      ToastMessage.show(
        context,
        message: localizations.enterFourDigitCode,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.verifyEmailCode(widget.email, code);

      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.emailVerifiedSuccess,
          isSuccess: true,
        );

        // Eğer password varsa otomatik login yap ve Customer keşfet ekranına yönlendir
        if (widget.password != null && widget.password!.isNotEmpty) {
          try {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            await authProvider.login(widget.email, widget.password!);

            if (mounted) {
              // Customer keşfet ekranına (MainNavigationScreen) yönlendir
              Navigator.of(context).pushAndRemoveUntil(
                NoSlidePageRoute(
                  builder: (context) => const MainNavigationScreen(),
                ),
                (route) => false,
              );
            }
          } catch (loginError) {
            // Login başarısız olursa login ekranına yönlendir
            if (mounted) {
              ToastMessage.show(
                context,
                message: localizations.emailVerifiedLoginFailed,
                isSuccess: false,
              );
              Navigator.of(context).pushAndRemoveUntil(
                NoSlidePageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        } else {
          // Password yoksa login ekranına yönlendir
          Navigator.of(context).pushAndRemoveUntil(
            NoSlidePageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = localizations.verificationFailed;
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
      }

      if (mounted) {
        ToastMessage.show(context, message: errorMessage, isSuccess: false);

        // Hatalı kodları temizle
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.errorWithMessage(e.toString()),
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

  Future<void> _resendCode() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isResending = true;
    });

    try {
      // Get user's language preference
      final localizationProvider = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      );
      final languageCode = localizationProvider.locale.languageCode;

      await _apiService.resendVerificationCode(
        widget.email,
        language: languageCode,
      );

      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.verificationCodeResent,
          isSuccess: true,
        );

        // Timer'ı yeniden başlat
        _startTimer();

        // Kod inputlarını temizle
        for (final controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } on DioException catch (e) {
      String errorMessage = localizations.codeSendFailed;
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
      }

      if (mounted) {
        ToastMessage.show(context, message: errorMessage, isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.errorWithMessage(e.toString()),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Orange Header
              SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    // Decorative shapes
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppTheme.lightOrange.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
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
                    // Title
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppTheme.spacingXLarge + AppTheme.spacingSmall,
                        ),
                        child: Text(
                          localizations.emailVerification,
                          style: AppTheme.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
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
                      child: Column(
                        children: [
                          AppTheme.verticalSpace(1.25),
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(
                              AppTheme.spacingLarge,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              size: 80,
                              color: AppTheme.darkOrange,
                            ),
                          ),
                          AppTheme.verticalSpace(2),
                          // Title
                          Text(
                            localizations.fourDigitVerificationCode,
                            style: AppTheme.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppTheme.verticalSpace(1),
                          // Description
                          Text(
                            localizations.enterCodeSentToEmail(widget.email),
                            style: AppTheme.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppTheme.verticalSpace(3),
                          // Code Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              return SizedBox(
                                width: 55,
                                height: 65,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  style: AppTheme.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: EdgeInsets
                                        .zero, // Remove default padding
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppTheme.dividerColor,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppTheme.dividerColor,
                                        width: 2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryOrange,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.backgroundColor,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) =>
                                      _onCodeChanged(index, value),
                                ),
                              );
                            }),
                          ),
                          AppTheme.verticalSpace(2),
                          // Timer or Resend Button
                          if (!_canResend)
                            Text(
                              localizations.codeExpiresIn(
                                _formatTime(_remainingSeconds),
                              ),
                              style: AppTheme.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          else
                            TextButton(
                              onPressed: _isResending ? null : _resendCode,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      localizations.resendCode,
                                      style: AppTheme.poppins(
                                        color: AppTheme.primaryOrange,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          AppTheme.verticalSpace(2),
                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyCode,
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
                                      localizations.verify,
                                      style: AppTheme.poppins(
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
      ),
    );
  }
}

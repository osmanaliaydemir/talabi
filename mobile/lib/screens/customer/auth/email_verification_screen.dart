import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/screens/customer/auth/login_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/toast_message.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;

  Future<void> _resendEmail() async {
    if (widget.email == null) {
      final localizations = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: localizations.emailRequired,
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final apiService = ApiService();
      // Get current language code
      final languageCode = Localizations.localeOf(context).languageCode;

      await apiService.resendVerificationCode(
        widget.email!,
        language: languageCode,
      );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.verificationEmailResent,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: '${localizations.error}: ${e.toString()}',
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
              // Orange Header with Gradient
              SizedBox(
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
                          color: AppTheme.lightOrange.withValues(alpha: 0.7),
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
                          localizations.emailVerification,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppTheme.verticalSpace(1.25),
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingLarge),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_unread_outlined,
                              size: 80,
                              color: AppTheme.darkOrange,
                            ),
                          ),
                          AppTheme.verticalSpace(2),
                          Text(
                            localizations.checkYourEmail,
                            style: AppTheme.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppTheme.verticalSpace(1),
                          Text(
                            localizations.emailVerificationDescription,
                            style: AppTheme.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppTheme.verticalSpace(3),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
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
                              child: Text(
                                localizations.iHaveVerified,
                                style: AppTheme.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          AppTheme.verticalSpace(1),
                          TextButton(
                            onPressed: _isResending ? null : _resendEmail,
                            child: _isResending
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  )
                                : Text(
                                    localizations.resendEmail,
                                    style: AppTheme.poppins(
                                      color: AppTheme.primaryOrange,
                                      fontSize: 14,
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

import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API'ye şifre sıfırlama isteği gönder
      await _apiService.forgotPassword(_emailController.text.trim());

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.passwordResetEmailSent,
          isSuccess: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.passwordResetFailed,
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
          child: Column(
            children: [
              // Header with decorative shapes
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
                    // Decorative shape on left side (rounded pill shape)
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
                    // Back button
                    Positioned(
                      top: AppTheme.spacingSmall,
                      left: AppTheme.spacingSmall,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textOnPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Title - Centered
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: AppTheme.spacingXLarge + AppTheme.spacingSmall,
                        ),
                        child: Text(
                          localizations.passwordReset,
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
              // Main Content Card
              Expanded(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            localizations.forgetPassword,
                            style: AppTheme.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          AppTheme.verticalSpace(0.5),
                          AppTheme.verticalSpace(0.5),
                          // Description
                          Text(
                            localizations.forgetPasswordDescription,
                            style: AppTheme.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          AppTheme.verticalSpace(2.5),
                          // Illustration
                          Center(
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: _EmailIllustrationPainter(),
                            ),
                          ),
                          AppTheme.verticalSpace(2.5),
                          // Email Input Field
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMedium,
                                  vertical: AppTheme.spacingMedium,
                                ),
                              ),
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
                          AppTheme.verticalSpace(2),
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
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
                                      localizations.continueButton,
                                      style: AppTheme.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          AppTheme.verticalSpace(1),
                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacingMedium,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                              child: Text(
                                localizations.cancel,
                                style: AppTheme.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
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

// Custom Painter for Email Illustration
class _EmailIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Hand outline (simplified)
    final handPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.6,
        size.width * 0.25,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.4,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.6,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.4,
        size.width * 0.75,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.6,
        size.width * 0.7,
        size.height * 0.7,
      );

    paint.color = Colors.pink[300]!;
    canvas.drawPath(handPath, paint);

    // Envelope
    final envelopeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.5,
        size.width * 0.3,
        size.height * 0.25,
      ),
      const Radius.circular(4),
    );

    paint
      ..color = Colors.orange
      ..style = PaintingStyle.fill;
    canvas.drawRRect(envelopeRect, paint);

    paint
      ..color = Colors.orange[800]!
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(envelopeRect, paint);

    // Envelope flap
    final flapPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.55)
      ..lineTo(size.width * 0.65, size.height * 0.5);

    paint
      ..color = Colors.orange[800]!
      ..style = PaintingStyle.stroke;
    canvas.drawPath(flapPath, paint);

    // Notification badge
    paint
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.5),
      size.width * 0.04,
      paint,
    );

    paint.color = Colors.white;
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '1',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter
      ..layout()
      ..paint(
        canvas,
        Offset(
          size.width * 0.65 - textPainter.width / 2,
          size.height * 0.5 - textPainter.height / 2,
        ),
      );

    // Paper airplane
    final airplanePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.4)
      ..lineTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.25, size.height * 0.4)
      ..close();

    paint
      ..color = Colors.blue[400]!
      ..style = PaintingStyle.fill;
    canvas.drawPath(airplanePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

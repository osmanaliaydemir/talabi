import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.passwordResetEmailSent ??
                  'Password reset email sent',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.passwordResetFailed ??
                  'Failed to send reset email: $e',
            ),
            backgroundColor: Colors.red,
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400,
              Colors.orange.shade600,
              Colors.orange.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with decorative shapes
              Container(
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
                          color: Colors.orange.shade300,
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
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Title - Centered
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          localizations.passwordReset,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            localizations.forgetPassword,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 8),
                          // Description
                          Text(
                            localizations.forgetPasswordDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Illustration
                          Center(
                            child: CustomPaint(
                              size: const Size(200, 200),
                              painter: _EmailIllustrationPainter(),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Email Input Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: localizations.emailAddress,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
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
                          const SizedBox(height: 32),
                          // Continue Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
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
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      localizations.continueButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Cancel Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                localizations.cancel,
                                style: const TextStyle(
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

    paint.color = Colors.orange;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(envelopeRect, paint);

    paint.color = Colors.orange[800]!;
    paint.style = PaintingStyle.stroke;
    canvas.drawRRect(envelopeRect, paint);

    // Envelope flap
    final flapPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.55)
      ..lineTo(size.width * 0.65, size.height * 0.5);

    paint.color = Colors.orange[800]!;
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(flapPath, paint);

    // Notification badge
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
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
    textPainter.layout();
    textPainter.paint(
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

    paint.color = Colors.blue[400]!;
    paint.style = PaintingStyle.fill;
    canvas.drawPath(airplanePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

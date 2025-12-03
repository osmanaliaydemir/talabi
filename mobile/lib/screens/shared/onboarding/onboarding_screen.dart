import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/shared/onboarding/language_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.6,
            child: Image.asset(
              'assets/images/onboarding1.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Red Background with Curve (Bottom Half)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.5,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                color: const Color(0xFFCE181B),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.areYouHungry,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              l10n.onboardingDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Montserrat',
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.getStarted,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Slide to Unlock Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: SlideActionBtn(
                        text: l10n.unlockDescription,
                        onSubmit: _completeOnboarding,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 50);
    path.quadraticBezierTo(size.width / 2, -20, size.width, 50);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SlideActionBtn extends StatefulWidget {
  final String text;
  final VoidCallback onSubmit;

  const SlideActionBtn({super.key, required this.text, required this.onSubmit});

  @override
  State<SlideActionBtn> createState() => _SlideActionBtnState();
}

class _SlideActionBtnState extends State<SlideActionBtn> {
  double _dragValue = 0.0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final buttonSize = 60.0; // Increased button size
        final padding = 5.0;
        final maxDrag =
            maxWidth - buttonSize - (padding * 2) - 40; // Adjusted for margin

        return Container(
          height: 70, // Increased height
          margin: const EdgeInsets.symmetric(
            horizontal: 20,
          ), // Added margin to decrease width
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              // Progress Trail
              if (_dragValue > 0)
                Container(
                  width: padding + _dragValue + buttonSize,
                  height: 70, // Match container height
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),

              // Centered Text
              Center(
                child: Opacity(
                  opacity: (1 - (_dragValue / maxDrag)).clamp(0.0, 1.0),
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),

              // Draggable Circle
              Positioned(
                left: padding + _dragValue,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_submitted) return;
                    setState(() {
                      _dragValue = (_dragValue + details.delta.dx).clamp(
                        0.0,
                        maxDrag,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_submitted) return;
                    if (_dragValue > maxDrag * 0.7) {
                      setState(() {
                        _dragValue = maxDrag;
                        _submitted = true;
                      });
                      widget.onSubmit();
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCE181B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

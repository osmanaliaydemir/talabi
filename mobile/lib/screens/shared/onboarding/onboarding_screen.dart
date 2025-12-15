import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/localization_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  static const int _slideDuration = 10; // seconds
  static const int _totalPages = 2;

  AnimationController? _progressController;

  // Colors
  final Color _primaryColor = const Color(0xFFCE181B); // App Brand Red

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progressController?.dispose();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _slideDuration),
    )..forward();

    _timer = Timer(const Duration(seconds: _slideDuration), () {
      _nextPage();
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _startTimer();
  }

  Future<void> _completeOnboarding() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Define data with colors included
    final List<Map<String, dynamic>> onboardingData = [
      {
        'title': l10n.onboardingTitle1,
        'desc': l10n.onboardingDesc1,
        'image': 'assets/images/banner_image.png',
        'bgColor': const Color(0xFFCE181B).withValues(alpha: 1), // Darker Red
      },
      {
        'title': l10n.onboardingTitle2,
        'desc': l10n.onboardingDesc2,
        'image': 'assets/images/market_banner.png',
        'bgColor': const Color(0xFF4CAF50).withValues(alpha: 1), // Market Green
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F2), // Light beige background
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // Top Spacer for Header (Language & Skip)
                  const SizedBox(height: 60),

                  // Page Content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: onboardingData.length,
                      itemBuilder: (context, index) {
                        return OnboardingPage(
                          image: onboardingData[index]["image"]! as String,
                          title: onboardingData[index]["title"]! as String,
                          description: onboardingData[index]["desc"]! as String,
                          circleColor:
                              onboardingData[index]["bgColor"]! as Color,
                        );
                      },
                    ),
                  ),

                  // Bottom Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Indicators (Dash style)
                        Row(
                          children: List.generate(
                            onboardingData.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 6),
                              height: 6,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),

                        // Next Button
                        GestureDetector(
                          onTap: _nextPage,
                          child: SizedBox(
                            width: 65,
                            height: 65,
                            child: Stack(
                              children: [
                                // Black Background Circle
                                Center(
                                  child: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: _primaryColor, // App Color
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryColor.withValues(
                                            alpha: 0.3,
                                          ), // Colored shadow looks better with colored button
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white, // White Arrow
                                      size: 28,
                                    ),
                                  ),
                                ),
                                // Progress Indicator Ring
                                if (_progressController != null)
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _progressController!,
                                      builder: (context, child) {
                                        return CircularProgressIndicator(
                                          value: _progressController!.value,
                                          strokeWidth: 2.5,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _primaryColor,
                                              ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Skip Text Button (Top Right)
            Positioned(
              top: 0,
              right: 20,
              child: SafeArea(
                child: SizedBox(
                  height: 50, // Fixed height for alignment
                  child: Center(
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        l10n.skip,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Language Selector (Top Left)
            Positioned(
              top: 0,
              left: 20,
              child: SafeArea(
                child: SizedBox(
                  height: 50, // Fixed height for alignment with Skip
                  child: Center(
                    child: Consumer<LocalizationProvider>(
                      builder: (context, provider, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.03,
                            ), // Reduced opacity
                            shape: BoxShape.circle,
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerTheme: DividerThemeData(
                                color: Colors.grey.withValues(alpha: 0.2),
                                space: 1,
                                thickness: 1,
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 45),
                              constraints: const BoxConstraints.tightFor(
                                width: 60, // Reduced width (70 -> 60)
                              ),
                              elevation:
                                  2, // Reduced elevation for simpler look
                              color: Colors.white.withValues(
                                alpha: 0.90, // Glassy transparency
                              ),
                              surfaceTintColor: Colors.white,
                              icon: Text(
                                provider.locale.languageCode.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF2D201C),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (String code) {
                                provider.setLanguage(code);
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'tr',
                                      height: 35, // Reduced height
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: Text(
                                          'TR',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13, // Smaller font
                                            color:
                                                provider.locale.languageCode ==
                                                    'tr'
                                                ? const Color(0xFFCE181B)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 1),
                                    PopupMenuItem<String>(
                                      value: 'en',
                                      height: 35, // Reduced height
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: Text(
                                          'EN',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13, // Smaller font
                                            color:
                                                provider.locale.languageCode ==
                                                    'en'
                                                ? const Color(0xFFCE181B)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 1),
                                    PopupMenuItem<String>(
                                      value: 'ar',
                                      height: 35, // Reduced height
                                      padding: EdgeInsets.zero,
                                      child: Center(
                                        child: Text(
                                          'AR',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13, // Smaller font
                                            color:
                                                provider.locale.languageCode ==
                                                    'ar'
                                                ? const Color(0xFFCE181B)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        );
                      },
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

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.circleColor,
  });

  final String image;
  final String title;
  final String description;
  final Color circleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image Container with Circle Background
        Expanded(
          flex: 5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Circle
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * 0.8,
                    height: constraints.maxWidth * 0.8,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              // Image
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
            ],
          ),
        ),

        // Text Content
        Expanded(
          flex: 4,
          child: Center(
            child: Container(
              width: double.infinity, // Full width (minus margins)
              height: 200, // Fixed height for consistency across pages
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700, // Poppins Bold
                      color: const Color.fromARGB(255, 45, 28, 28),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontWeight: FontWeight.w400, // Poppins Regular/Medium
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/onboarding/presentation/screens/onboarding_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key, this.onLanguageSelected});

  final VoidCallback? onLanguageSelected;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  String? _selectedLanguage;

  // Slogan için state değişkenleri
  int _currentSloganIndex = 0;
  int _displayedCharacters = 0;
  bool _showCursor = true;
  Timer? _sloganTimer;
  Timer? _typewriterTimer;
  Timer? _cursorTimer;

  final List<String> _slogans = [
    'Talep Et… Çok Geçmeden Kapında.', // Türkçe
    'Order Now… Soon at Your Door.', // İngilizce
    'اطلب الآن… قريباً على بابك.', // Arapça
  ];

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'tr',
      'name': 'Türkçe',
      'nativeName': 'Turkish',
      'shortCode': 'TR',
      'color': AppTheme.error, // Red
    },
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'shortCode': 'EN',
      'color': AppTheme.info, // Blue
    },
    {
      'code': 'ar',
      'name': 'العربية',
      'nativeName': 'Arabic',
      'shortCode': 'AR',
      'color': AppTheme.success, // Green
    },
  ];

  @override
  void initState() {
    super.initState();

    // Klavyeyi kapat
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });

    // Slogan daktilo efektini başlat
    _startTypewriterEffect();
    // 3 saniyede bir slogan değiştir
    _startSloganRotation();
    // Cursor yanıp sönme efekti
    _startCursorBlink();
  }

  void _startCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startTypewriterEffect() {
    _typewriterTimer?.cancel();
    _displayedCharacters = 0;

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          if (_displayedCharacters < _slogans[_currentSloganIndex].length) {
            _displayedCharacters++;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startSloganRotation() {
    _sloganTimer?.cancel();

    _sloganTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentSloganIndex = (_currentSloganIndex + 1) % _slogans.length;
          _displayedCharacters = 0;
        });
        _startTypewriterEffect();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _sloganTimer?.cancel();
    _typewriterTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectLanguage(String languageCode) async {
    setState(() {
      _selectedLanguage = languageCode;
    });

    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    await localizationProvider.setLanguage(languageCode);

    // Mark language selection as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('language_selection_completed', true);
    // Reset onboarding so it shows up again
    await prefs.setBool('onboarding_completed', false);

    // Animate out
    await _scaleController.reverse();
    await _slideController.reverse();
    await _fadeController.reverse();

    if (mounted) {
      // Navigate to OnboardingScreen or LoginScreen
      // Since we reset onboarding_completed to false above, we should go to OnboardingScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevents overflow when keyboard is open
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo/Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: (1 - value) * 2 * math.pi,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXLarge + AppTheme.spacingSmall,
                                ),
                                boxShadow: [
                                  const BoxShadow(
                                    color: AppTheme.shadowColor,
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXLarge + AppTheme.spacingSmall,
                                ),
                                child: Image.asset(
                                  'assets/icon/icon.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    AppTheme.verticalSpace(2.5),
                    // Slogan with typewriter effect
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_currentSloganIndex),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXLarge,
                        ),
                        child: Text(
                          _slogans[_currentSloganIndex].substring(
                                0,
                                _displayedCharacters.clamp(
                                  0,
                                  _slogans[_currentSloganIndex].length,
                                ),
                              ) +
                              (_displayedCharacters <
                                          _slogans[_currentSloganIndex]
                                              .length &&
                                      _showCursor
                                  ? '|'
                                  : ''),
                          style: AppTheme.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textOnPrimary,
                            letterSpacing: 0.8,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    AppTheme.verticalSpace(1.25),
                    // Language Cards
                    ...List.generate(
                      _languages.length,
                      (index) => TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 600 + (index * 150)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(50 * (1 - value), 0),
                              child: Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: _buildLanguageCard(
                                  _languages[index],
                                  index,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> language, int index) {
    final isSelected = _selectedLanguage == language['code'];
    final color = language['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXLarge,
        vertical: AppTheme.radiusMedium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectLanguage(language['code'] as String),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
              vertical: AppTheme.spacingLarge,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? color : AppTheme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : AppTheme.shadowColor,
                  blurRadius: isSelected ? 15 : 10,
                  spreadRadius: isSelected ? 1 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Stylized Language Code
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      language['shortCode'] as String,
                      style: AppTheme.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                AppTheme.horizontalSpace(1.25),
                // Language Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language['name'] as String,
                        style: AppTheme.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        language['nativeName'] as String,
                        style: AppTheme.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[300]!,
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

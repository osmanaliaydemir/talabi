import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback? onLanguageSelected;

  const LanguageSelectionScreen({super.key, this.onLanguageSelected});

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
      'nativeName': 'Türkçe',
      'flag': '🇹🇷',
      'color': AppTheme.error, // Red
    },
    {
      'code': 'en',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇬🇧',
      'color': AppTheme.info, // Blue
    },
    {
      'code': 'ar',
      'name': 'العربية',
      'nativeName': 'العربية',
      'flag': '🇸🇦',
      'color': AppTheme.success, // Green
    },
  ];

  @override
  void initState() {
    super.initState();

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

    // Animate out
    await _scaleController.reverse();
    await _slideController.reverse();
    await _fadeController.reverse();

    if (mounted) {
      // Trigger rebuild of MaterialApp
      widget.onLanguageSelected?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                  BoxShadow(
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
                        padding: EdgeInsets.symmetric(
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
      margin: EdgeInsets.symmetric(
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
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
              vertical: AppTheme.spacingLarge - AppTheme.spacingXSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isSelected ? color : AppTheme.dividerColor,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? color.withOpacity(0.4)
                      : AppTheme.shadowColor,
                  blurRadius: isSelected ? 20 : 10,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Flag with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      language['flag'] as String,
                      style: const TextStyle(fontSize: 32),
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : AppTheme.textPrimary,
                        ),
                      ),
                      AppTheme.verticalSpace(0.25),
                      Text(
                        language['nativeName'] as String,
                        style: AppTheme.poppins(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isSelected
                      ? Container(
                          key: const ValueKey('selected'),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: AppTheme.textOnPrimary,
                            size: 20,
                          ),
                        )
                      : Container(
                          key: const ValueKey('unselected'),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

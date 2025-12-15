import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/localization_provider.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onBack,
    this.useCircleBackButton = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback? onBack;
  final bool useCircleBackButton;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: SizedBox(
        height: 180 + MediaQuery.of(context).padding.top,
        child: Stack(
          children: [
            // Modern Abstract Shapes
            // Top Right - Large Faded Circle
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Top Right - Smaller brighter circle inside
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Middle Left - Medium Circle
            Positioned(
              top: 40,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Back Button
            if (onBack != null)
              Positioned(
                top:
                    MediaQuery.of(context).padding.top +
                    (useCircleBackButton ? 4 : 10),
                left: useCircleBackButton ? AppTheme.spacingMedium : 10,
                child: useCircleBackButton
                    ? _buildCircleButton(icon: Icons.arrow_back, onTap: onBack!)
                    : IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppTheme.textOnPrimary,
                        ),
                        onPressed: onBack,
                      ),
              ),

            // Language Selector (Top Right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              right: AppTheme.spacingMedium,
              child: Consumer<LocalizationProvider>(
                builder: (context, provider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: PopupMenuButton<String>(
                      icon: Text(
                        provider.locale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      onSelected: (String code) {
                        provider.setLanguage(code);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'tr',
                              child: Row(
                                children: [
                                  Text('🇹🇷'),
                                  SizedBox(width: 8),
                                  Text('Türkçe'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'en',
                              child: Row(
                                children: [
                                  Text('🇺🇸'),
                                  SizedBox(width: 8),
                                  Text('English'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'ar',
                              child: Row(
                                children: [
                                  Text('🇸🇦'),
                                  SizedBox(width: 8),
                                  Text('العربية'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  );
                },
              ),
            ),
            // Title Content
            Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: AppTheme.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:google_fonts/google_fonts.dart';

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
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerTheme: DividerThemeData(
                          color: Colors.grey.withValues(alpha: 0.2),
                          space: 1,
                          thickness: 1,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        constraints: const BoxConstraints.tightFor(
                          width: 60, // Reduced width
                        ),
                        elevation: 2,
                        color: Colors.white.withValues(
                          alpha: 0.90, // Glassy transparency
                        ),
                        surfaceTintColor: Colors.white,
                        icon: Text(
                          provider.locale.languageCode.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16, // Kept 16 for button as standard
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
                                height: 35,
                                padding: EdgeInsets.zero,
                                child: Center(
                                  child: Text(
                                    'TR',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color:
                                          provider.locale.languageCode == 'tr'
                                          ? const Color(0xFFCE181B)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem<String>(
                                value: 'en',
                                height: 35,
                                padding: EdgeInsets.zero,
                                child: Center(
                                  child: Text(
                                    'EN',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color:
                                          provider.locale.languageCode == 'en'
                                          ? const Color(0xFFCE181B)
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem<String>(
                                value: 'ar',
                                height: 35,
                                padding: EdgeInsets.zero,
                                child: Center(
                                  child: Text(
                                    'AR',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color:
                                          provider.locale.languageCode == 'ar'
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

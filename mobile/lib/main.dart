import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/language_selection_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/main_navigation_screen.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _rebuildKey = 0;

  Future<bool> _checkLanguageSelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('language_selection_completed') ?? false;
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  void _onLanguageSelected() {
    setState(() {
      _rebuildKey++;
    });
  }

  Widget _buildHome() {
    return FutureBuilder<bool>(
      key: ValueKey(_rebuildKey),
      future: _checkLanguageSelection(),
      builder: (context, languageSnapshot) {
        if (languageSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show language selection if not completed
        if (languageSnapshot.data == false) {
          return LanguageSelectionScreen(
            onLanguageSelected: _onLanguageSelected,
          );
        }

        // Check onboarding status
        return FutureBuilder<bool>(
          future: _checkOnboardingStatus(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Show onboarding if not completed
            if (onboardingSnapshot.data == false) {
              return const OnboardingScreen();
            }

            // Otherwise show normal app flow
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAuthenticated) {
                  return const MainNavigationScreen();
                } else {
                  return FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const LoginScreen();
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localization, _) {
        return MaterialApp(
          title: 'Talabi',
          debugShowCheckedModeBanner: false,
          locale: localization.locale,
          navigatorObservers: [NavigationLogger()],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar')],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
            useMaterial3: true,
          ),
          routes: {'/login': (context) => const LoginScreen()},
          home: _buildHome(),
        );
      },
    );
  }
}

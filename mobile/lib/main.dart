import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/screens/customer/auth/login_screen.dart';
import 'package:mobile/screens/shared/splash_screen.dart';
import 'package:mobile/routers/app_router.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize connectivity and sync services
  final connectivityService = ConnectivityService();
  final syncService = SyncService(connectivityService);

  // Initialize API service with connectivity
  ApiService().setConnectivityService(connectivityService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(
          create: (context) => ConnectivityProvider(connectivityService),
        ),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => CartProvider(
            syncService: syncService,
            connectivityProvider: context.read<ConnectivityProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates the root widget.
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationProvider, ThemeProvider>(
      builder: (context, localization, themeProvider, _) {
        return MaterialApp(
          title: 'Talabi',
          debugShowCheckedModeBanner: false,
          locale: localization.locale,
          navigatorKey: NavigationService.navigatorKey,
          scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
          navigatorObservers: [NavigationLogger(), observer],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar')],
          theme: themeProvider.isHighContrast
              ? themeProvider.highContrastTheme
              : themeProvider.lightTheme,
          darkTheme: themeProvider.isHighContrast
              ? themeProvider.highContrastTheme
              : themeProvider.darkTheme,
          // Dark mode geçici olarak kapatıldı - her zaman light mode kullan
          themeMode: ThemeMode.light,
          routes: {'/login': (context) => const LoginScreen()},
          onGenerateRoute: AppRouter.generateRoute,
          home: const SplashScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themeProvider.textScaleFactor),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

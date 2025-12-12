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
import 'package:mobile/services/preferences_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mobile/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences first (singleton pattern)
  await PreferencesService.init();

  // Initialize Hive (required for LoggerService and CacheService)
  try {
    await Hive.initFlutter();
  } catch (e, stackTrace) {
    // Hive initialization failed - log but continue
    // LoggerService will handle this gracefully
    if (kDebugMode) {
      LoggerService().error('Hive initialization failed', e, stackTrace);
    }
  }

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Analytics
    MyApp._initializeFirebaseAnalytics();

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, stackTrace) {
    // Firebase initialization failed - log but continue app execution
    LoggerService().error('Firebase initialization failed', e, stackTrace);
    LoggerService().warning('App will continue without Firebase services');
    // Set basic error handlers even if Firebase is not available
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      LoggerService().fatal('Unhandled error', error, stack);
      return true;
    };
  }

  // Initialize connectivity and sync services
  final connectivityService = ConnectivityService();
  final syncService = SyncService(connectivityService);

  // Initialize API service with connectivity
  ApiService().setConnectivityService(connectivityService);

  // Initialize Logger Service (will be fully initialized after providers)
  // Logger will be initialized after AuthProvider is available

  runApp(
    MultiProvider(
      providers: [
        // Critical providers (initialize immediately)
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => ConnectivityProvider(connectivityService),
        ),
        // Lazy providers (initialize on first use - using lazy factory pattern)
        ChangeNotifierProvider(
          create: (context) => CartProvider(
            syncService: syncService,
            connectivityProvider: context.read<ConnectivityProvider>(),
          ),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (context) => BottomNavProvider(),
          // lazy: false - ThemeProvider ile senkronize olması için hemen yüklenmeli
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
          lazy: true,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates the root widget.
  const MyApp({super.key});

  static FirebaseAnalytics? analytics;
  static FirebaseAnalyticsObserver? observer;

  static void _initializeFirebaseAnalytics() {
    try {
      analytics = FirebaseAnalytics.instance;
      observer = FirebaseAnalyticsObserver(analytics: analytics!);
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Firebase Analytics not available',
        e,
        stackTrace,
      );
      analytics = null;
      observer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationProvider, ThemeProvider, BottomNavProvider>(
      builder: (context, localization, themeProvider, bottomNav, _) {
        // Initialize Logger Service after providers are available
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final authProvider = context.read<AuthProvider>();
          final connectivityService = ConnectivityService();
          await LoggerService().init(
            connectivityService: connectivityService,
            authProvider: authProvider,
          );
        });

        // BottomNavProvider'dan kategori değişikliğini ThemeProvider'a bildir
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (themeProvider.currentCategory != bottomNav.selectedCategory) {
            themeProvider.setCategory(bottomNav.selectedCategory);
          }
        });

        return MaterialApp(
          title: 'Talabi',
          debugShowCheckedModeBanner: false,
          locale: localization.locale,
          navigatorKey: NavigationService.navigatorKey,
          scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
          navigatorObservers: [
            if (kDebugMode) NavigationLogger(), // Only in debug mode
            if (observer != null) observer!,
          ],
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

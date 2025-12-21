import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/config/injection.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/preferences_service.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection
  configureDependencies();

  // Parallelize independent initializations
  await Future.wait([
    // Initialize SharedPreferences
    PreferencesService.init(),
    // Initialize Hive
    Future(() async {
      try {
        await Hive.initFlutter();
      } catch (e, stackTrace) {
        if (kDebugMode) {
          LoggerService().error('Hive initialization failed', e, stackTrace);
        }
      }
    }),
  ]);

  // Initialize Firebase (Keep separate due to critical error handling setup)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, stackTrace) {
    LoggerService().error('Firebase initialization failed', e, stackTrace);
    LoggerService().warning('App will continue without Firebase services');

    // Fallback error handling
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

  runApp(await builder());
}

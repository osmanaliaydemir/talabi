import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (kDebugMode) {
      debugPrint(
        '🟢 [NAVIGATION] PUSH: ${route.settings.name ?? route.runtimeType}',
      );
      if (previousRoute != null) {
        debugPrint(
          '   ← From: ${previousRoute.settings.name ?? previousRoute.runtimeType}',
        );
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (kDebugMode) {
      debugPrint(
        '🔴 [NAVIGATION] POP: ${route.settings.name ?? route.runtimeType}',
      );
      if (previousRoute != null) {
        debugPrint(
          '   → To: ${previousRoute.settings.name ?? previousRoute.runtimeType}',
        );
      }
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (kDebugMode) {
      debugPrint('🔄 [NAVIGATION] REPLACE:');
      if (oldRoute != null) {
        debugPrint('   Old: ${oldRoute.settings.name ?? oldRoute.runtimeType}');
      }
      if (newRoute != null) {
        debugPrint('   New: ${newRoute.settings.name ?? newRoute.runtimeType}');
      }
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (kDebugMode) {
      debugPrint(
        '🗑️ [NAVIGATION] REMOVE: ${route.settings.name ?? route.runtimeType}',
      );
    }
  }
}

class TapLogger {
  static void logTap(String widgetName, {String? action}) {
    if (kDebugMode) {
      final actionText = action != null ? ' - $action' : '';
      debugPrint('👆 [TAP] $widgetName$actionText');
    }
  }

  static void logNavigation(String from, String to) {
    if (kDebugMode) {
      debugPrint('🧭 [NAVIGATION] $from → $to');
    }
  }

  static void logBottomNavChange(int fromIndex, int toIndex, String label) {
    if (kDebugMode) {
      debugPrint('📱 [BOTTOM_NAV] Tab $fromIndex → $toIndex ($label)');
    }
  }

  static void logButtonPress(String buttonName, {String? context}) {
    if (kDebugMode) {
      final contextText = context != null ? ' in $context' : '';
      debugPrint('🔘 [BUTTON] $buttonName$contextText');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/settings_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:provider/provider.dart';

import '../../../../orders/presentation/screens/customer/order_detail_screen_test.mocks.dart';

class MockLoggerService extends Mock implements LoggerService {
  @override
  void warning(String? message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void error(String? message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void fatal(String? message, [dynamic error, StackTrace? stackTrace]) {}
}

void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late VendorProvider vendorProvider;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    vendorProvider = VendorProvider();
    notificationProvider = NotificationProvider();

    ToastMessage.isTestMode = true;

    // Default mock behavior for Header dependencies
    when(mockApiService.getVendorProfile()).thenAnswer(
      (_) async => {'id': 'v1', 'name': 'Test Vendor', 'busyStatus': 0},
    );
    when(mockApiService.getVendorNotifications()).thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VendorProvider>.value(value: vendorProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr')],
        locale: Locale('tr'),
        home: VendorSettingsScreen(),
      ),
    );
  }

  group('VendorSettingsScreen Widget Tests', () {
    testWidgets('should render and load settings including radius slider', (
      WidgetTester tester,
    ) async {
      // Arrange
      final settingsData = {
        'minimumOrderAmount': 100.0,
        'deliveryFee': 15.0,
        'estimatedDeliveryTime': 30,
        'deliveryRadiusInKm': 10.0,
        'isActive': true,
      };

      when(
        mockApiService.getVendorSettings(),
      ).thenAnswer((_) async => settingsData);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Minimum Sipariş Tutarı'), findsOneWidget);
      expect(find.text('Teslimat Ücreti'), findsOneWidget);
      expect(find.text('Teslimat Yarıçapı (km)'), findsOneWidget);

      // Verify values
      expect(find.text('100.0'), findsOneWidget);
      expect(find.text('15.0'), findsOneWidget);
      expect(
        find.text('10 km'),
        findsOneWidget,
      ); // Total count might be 2 (label + slider value)

      // Verify Slider presence
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should call updateVendorSettings when save button is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      final settingsData = {
        'minimumOrderAmount': 100.0,
        'deliveryFee': 15.0,
        'estimatedDeliveryTime': 30,
        'deliveryRadiusInKm': 10.0,
        'isActive': true,
      };

      when(
        mockApiService.getVendorSettings(),
      ).thenAnswer((_) async => settingsData);
      when(
        mockApiService.updateVendorSettings(any),
      ).thenAnswer((_) async => {});

      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      // Change delivery fee
      final deliveryFeeField = find.widgetWithText(
        TextFormField,
        'Teslimat Ücreti',
      );
      await tester.enterText(deliveryFeeField, '25.0');
      await tester.pump();

      // Find save button specifically
      final saveButton = find.byType(ElevatedButton);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);

      await tester.pump();
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockApiService.updateVendorSettings(
          argThat(containsPair('deliveryFee', 25.0)),
        ),
      ).called(1);
    });
  });
}

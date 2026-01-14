import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/customer/addresses_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
// ignore: depend_on_referenced_packages
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/profile/presentation/providers/address_provider.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:provider/provider.dart';

import 'addresses_screen_test.mocks.dart';

@GenerateMocks([NotificationProvider, AddressProvider])
void main() {
  late MockNotificationProvider mockNotificationProvider;
  late MockAddressProvider mockAddressProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockNotificationProvider = MockNotificationProvider();
    mockAddressProvider = MockAddressProvider();

    // Stub NotificationProvider basic properties
    when(mockNotificationProvider.unreadCount).thenReturn(0);
    when(mockNotificationProvider.notifications).thenReturn([]);
    when(mockNotificationProvider.isLoading).thenReturn(false);
    when(mockNotificationProvider.error).thenReturn(null);

    // Stub AddressProvider basic properties
    when(mockAddressProvider.isLoading).thenReturn(false);
    when(mockAddressProvider.addresses).thenReturn([]);
    when(mockAddressProvider.error).thenReturn(null);

    ToastMessage.isTestMode = true;
    AnalyticsService.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: mockNotificationProvider,
        ),
        ChangeNotifierProvider<AddressProvider>.value(
          value: mockAddressProvider,
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
        home: AddressesScreen(),
      ),
    );
  }

  group('AddressesScreen Widget Tests', () {
    testWidgets('should render loading indicator initially', (
      WidgetTester tester,
    ) async {
      when(mockAddressProvider.isLoading).thenReturn(true);
      when(mockAddressProvider.loadAddresses()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Start animation

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Flush timers (200ms and 400ms in initState)
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('should render empty state when no addresses', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      when(mockAddressProvider.isLoading).thenReturn(false);
      when(mockAddressProvider.addresses).thenReturn([]);
      when(mockAddressProvider.loadAddresses()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      // Wait for initial build
      await tester.pump();
      // Account for delayed animations
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Henüz adres eklenmemiş'), findsOneWidget);
    });

    testWidgets('should render address list when addresses exist', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      final addresses = [
        Address(
          id: '1',
          title: 'Ev',
          fullAddress: 'Test Mahallesi No:1',
          cityId: '34',
          cityName: 'İstanbul',
          districtId: '1',
          districtName: 'Kadıköy',
          isDefault: true,
        ),
        Address(
          id: '2',
          title: 'İş',
          fullAddress: 'Plaza Kat:5',
          cityId: '34',
          cityName: 'İstanbul',
          districtId: '2',
          districtName: 'Levent',
          isDefault: false,
        ),
      ];

      when(mockAddressProvider.isLoading).thenReturn(false);
      when(mockAddressProvider.addresses).thenReturn(addresses);
      when(mockAddressProvider.loadAddresses()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      // Allow animations to complete (max duration is around 1200ms + stagger)
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Check titles
      expect(find.text('Ev'), findsOneWidget);
      expect(find.text('İş'), findsOneWidget);

      // Check default label
      expect(find.text('Varsayılan'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog and delete address', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      final addresses = [
        Address(
          id: '1',
          title: 'Ev',
          fullAddress: 'Test Mahallesi No:1',
          isDefault: false,
        ),
      ];

      when(mockAddressProvider.isLoading).thenReturn(false);
      when(mockAddressProvider.addresses).thenReturn(addresses);
      when(mockAddressProvider.loadAddresses()).thenAnswer((_) async {});
      when(mockAddressProvider.deleteAddress('1')).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Tap menu button
      final iconFinder = find.byIcon(Icons.more_vert);

      // Scroll to it catchily (less aggressive than before to see if it works naturally)
      await tester.scrollUntilVisible(
        iconFinder,
        500.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(iconFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Select delete
      final deleteOption = find.text('Sil');
      await tester.tap(deleteOption);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Adresi Sil'), findsOneWidget);

      // Confirm delete
      final confirmBtn = find.text('Sil').last; // Dialog button
      await tester.tap(confirmBtn);

      await tester.pumpAndSettle();

      // Verify delete called
      verify(mockAddressProvider.deleteAddress('1')).called(1);
    });
  });
}

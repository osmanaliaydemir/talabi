import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/customer/add_edit_address_screen.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:mobile/features/profile/presentation/providers/address_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'add_edit_address_screen_test.mocks.dart';

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
    when(mockAddressProvider.isLoadingLocations).thenReturn(false);
    when(mockAddressProvider.error).thenReturn(null);
    when(mockAddressProvider.countries).thenReturn([]);
    when(mockAddressProvider.cities).thenReturn([]);
    when(mockAddressProvider.districts).thenReturn([]);
    when(mockAddressProvider.localities).thenReturn([]);

    // Stub location loading methods to do nothing by default
    when(mockAddressProvider.clearLocationData()).thenReturn(null);
    when(mockAddressProvider.loadCountries()).thenAnswer((_) async {});
    when(mockAddressProvider.loadCities(any)).thenAnswer((_) async {});
    when(mockAddressProvider.loadDistricts(any)).thenAnswer((_) async {});
    when(mockAddressProvider.loadLocalities(any)).thenAnswer((_) async {});

    // Stub saveAddress
    when(
      mockAddressProvider.saveAddress(any, id: anyNamed('id')),
    ).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest({Address? address}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: mockNotificationProvider,
        ),
        ChangeNotifierProvider<AddressProvider>.value(
          value: mockAddressProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        locale: const Locale('tr'),
        home: AddEditAddressScreen(address: address),
      ),
    );
  }

  group('AddEditAddressScreen Widget Tests', () {
    testWidgets('should render add address form correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      // Mock countries to verify dropdown presence
      when(mockAddressProvider.countries).thenReturn([
        {'id': '1', 'name': 'Türkiye'},
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Adres Ekle'), findsAtLeastNWidgets(1));
      expect(
        find.byType(TextFormField),
        findsAtLeastNWidgets(3),
      ); // title, fullAddress, postalCode
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsAtLeastNWidgets(3),
      ); // city, district, locality, (country is conditional but mocked to show here? No, code logic checks countries.length > 1)

      // If we have only 1 country, country dropdown is hidden (or logic is "if length > 1")
      // Check code: if (countries.length > 1) ...
      // So with 1 country, it should NOT show country dropdown.
      // So expects 3 dropdowns (city, district, locality).
    });

    testWidgets('should populate fields when editing existing address', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final testAddress = Address(
        id: 'a1',
        title: 'Ev',
        fullAddress: 'Test Sokak No:1',
        cityId: '1',
        cityName: 'İstanbul',
        districtId: '1',
        districtName: 'Kadıköy',
        localityId: '1',
        localityName: 'Moda',
        postalCode: '34710',
        latitude: 40.9876,
        longitude: 29.0123,
        isDefault: false,
      );

      when(mockAddressProvider.countries).thenReturn([
        {'id': '1', 'name': 'Türkiye'},
      ]);
      when(mockAddressProvider.cities).thenReturn([
        {'id': '1', 'name': 'İstanbul'},
      ]);
      when(mockAddressProvider.districts).thenReturn([
        {'id': '1', 'name': 'Kadıköy'},
      ]);
      when(mockAddressProvider.localities).thenReturn([
        {'id': '1', 'name': 'Moda'},
      ]);

      await tester.pumpWidget(createWidgetUnderTest(address: testAddress));
      await tester.pumpAndSettle();

      expect(find.text('Adresi Düzenle'), findsAtLeastNWidgets(1));

      // Verify title field contains the address title
      // Logic for fields: Title is likely the first or second textformfield?
      // Layout: Title, [MapButton], Country(maybe), City, District, Locality, FullAddress, PostalCode.
      // The implementation uses distinct controllers but finding by TextFormField returns all.
      // We can check by controller text if possible, or just exact text finding.

      expect(find.widgetWithText(TextFormField, 'Ev'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Test Sokak No:1'),
        findsOneWidget,
      );
    });
  });
}

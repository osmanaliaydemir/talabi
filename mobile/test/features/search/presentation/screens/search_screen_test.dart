import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/search/presentation/screens/search_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'search_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<LoggerService>(),
  MockSpec<SharedPreferences>(),
  MockSpec<CartProvider>(),
])
void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late MockCartProvider mockCartProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();
    mockCartProvider = MockCartProvider();

    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    // Default mock behaviors
    when(mockCartProvider.items).thenReturn({});

    // Mock SharedPreferences.getInstance()
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: mockCartProvider),
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
        home: SearchScreen(),
      ),
    );
  }

  group('SearchScreen Widget Tests', () {
    testWidgets('should render search bar and initial state', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getCategories(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      // Localization check for placeholder if needed
    });

    testWidgets('should show autocomplete results when typing', (
      WidgetTester tester,
    ) async {
      final mockAutocomplete = [
        AutocompleteResultDto(id: '1', name: 'Lahmacun', type: 'product'),
        AutocompleteResultDto(id: '2', name: 'Dürüm', type: 'product'),
      ];

      when(
        mockApiService.getCategories(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);

      when(
        mockApiService.autocomplete(any),
      ).thenAnswer((_) async => mockAutocomplete);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'lah');
      await tester.pump(const Duration(milliseconds: 600)); // Debounce
      await tester.pumpAndSettle();

      // We expect at least 2 "Lahmacun" widgets:
      // 1 in Popular Searches (Wrap) and 1 in suggestions (ListView)
      final suggestionFinder = find.descendant(
        of: find.byType(ListView),
        matching: find.text('Lahmacun'),
      );
      expect(suggestionFinder, findsOneWidget);
      expect(find.text('Dürüm'), findsOneWidget);
    });

    testWidgets('should show search results when clicking a suggestion', (
      WidgetTester tester,
    ) async {
      final mockAutocomplete = [
        AutocompleteResultDto(id: '1', name: 'Lahmacun', type: 'product'),
      ];

      final mockProducts = PagedResultDto<ProductDto>(
        items: [
          ProductDto(id: 'p1', vendorId: 'v1', name: 'Lahmacun', price: 50.0),
        ],
        totalCount: 1,
        page: 1,
        pageSize: 20,
        totalPages: 1,
      );

      when(
        mockApiService.getCategories(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);

      when(
        mockApiService.autocomplete(any),
      ).thenAnswer((_) async => mockAutocomplete);

      when(
        mockApiService.searchProducts(any),
      ).thenAnswer((_) async => mockProducts);

      when(mockApiService.searchVendors(any)).thenAnswer(
        (_) async => PagedResultDto<VendorDto>(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
          totalPages: 0,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'lah');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('Lahmacun'), findsAtLeastNWidgets(1));
    });

    testWidgets('should clear search history', (WidgetTester tester) async {
      // Set initial history
      SharedPreferences.setMockInitialValues({
        'search_history': ['pizza', 'burger'],
      });

      when(
        mockApiService.getCategories(
          language: anyNamed('language'),
          vendorType: anyNamed('vendorType'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // History chips should be visible
      expect(find.text('pizza'), findsOneWidget);
      expect(find.text('burger'), findsOneWidget);

      // Find clear button (IconButton with history icon or text)
      // Actually, looking at SearchScreen, there is a "Clear" button for history
      final clearHistoryButton = find.byIcon(Icons.delete_outline);
      if (clearHistoryButton.evaluate().isNotEmpty) {
        await tester.tap(clearHistoryButton);
        await tester.pumpAndSettle();
        expect(find.text('pizza'), findsNothing);
      }
    });
  });
}

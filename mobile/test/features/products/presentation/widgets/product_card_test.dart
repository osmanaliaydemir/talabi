import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';

import 'product_card_test.mocks.dart';

@GenerateNiceMocks([MockSpec<CartProvider>()])
void main() {
  late MockCartProvider mockCartProvider;

  setUp(() {
    mockCartProvider = MockCartProvider();
    when(mockCartProvider.items).thenReturn({});
  });

  final testProduct = Product(
    id: '1',
    vendorId: 'vendor1',
    name: 'Test Product',
    price: 100.0,
    currency: Currency.try_,
    vendorName: 'Test Vendor',
  );

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr')],
      locale: const Locale('tr'),
      home: Scaffold(
        body: ChangeNotifierProvider<CartProvider>.value(
          value: mockCartProvider,
          child: ProductCard(product: testProduct),
        ),
      ),
    );
  }

  group('ProductCard Widget Tests', () {
    testWidgets('should render product name and price', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.textContaining('100'), findsOneWidget);
    });

    testWidgets('should show add button when item not in cart', (
      WidgetTester tester,
    ) async {
      when(mockCartProvider.items).thenReturn({});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should show quantity when item is in cart', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockCartProvider.items,
      ).thenReturn({'1': CartItem(product: testProduct, quantity: 2)});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
    });

    testWidgets('should have correct semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify that a widget with the product name in its semantic label exists
      // Since semantics are merged, the label will contain the product name
      expect(
        find.bySemanticsLabel(RegExp(r'.*Test Product.*')),
        findsOneWidget,
      );

      // Verify actions using matchesSemantics
      expect(
        tester.getSemantics(find.byType(ProductCard)),
        matchesSemantics(hasTapAction: true, isButton: true),
      );
    });
  });
}

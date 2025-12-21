import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

// Generate mock for ApiService, LoggerService, and SecureStorageService
@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<LoggerService>(),
  MockSpec<SecureStorageService>(),
])
import 'auth_customer_integration_test.mocks.dart';

void main() {
  // Ensure bindings are initialized for MethodChannels (though we mock services that use them, GetIt might need it)
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;
  late MockSecureStorageService mockSecureStorageService;
  late AuthProvider authProvider;

  setUp(() async {
    // Reset GetIt
    await GetIt.instance.reset();

    // Initialize mocks
    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();
    mockSecureStorageService = MockSecureStorageService();

    // Register mocks to GetIt
    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    // Initialize AuthProvider with mocked services
    authProvider = AuthProvider(
      apiService: mockApiService,
      secureStorage: mockSecureStorageService,
    );
  });

  group('Customer Authentication Integration Tests', () {
    const customerEmail = '[email protected]';
    const customerPassword = 'Password123!';
    const customerName = 'Test Customer';
    const customerToken = 'customer-test-token-123';
    const customerId = 'customer-id-123';

    test('should successfully register a customer', () async {
      // Arrange
      when(mockApiService.register(any, any, any)).thenAnswer(
        (_) async => {
          'token': customerToken,
          'refreshToken': 'refresh-token',
          'userId': customerId,
          'email': customerEmail,
          'fullName': customerName,
          'role': 'Customer',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Act
      await authProvider.register(
        customerEmail,
        customerPassword,
        customerName,
      );

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.email, customerEmail);
      expect(authProvider.fullName, customerName);
      expect(authProvider.role, 'Customer');
      expect(authProvider.userId, customerId);

      verify(
        mockApiService.register(customerEmail, customerPassword, customerName),
      ).called(1);
      verify(mockSecureStorageService.setToken(customerToken)).called(1);
    });

    test('should successfully login a customer', () async {
      // Arrange
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': customerToken,
          'refreshToken': 'refresh-token',
          'userId': customerId,
          'email': customerEmail,
          'fullName': customerName,
          'role': 'Customer',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Act
      await authProvider.login(customerEmail, customerPassword);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.email, customerEmail);
      expect(authProvider.role, 'Customer');

      verify(mockApiService.login(customerEmail, customerPassword)).called(1);
      verify(mockSecureStorageService.setToken(customerToken)).called(1);
    });

    test('should successfully logout', () async {
      // Arrange (Simulate logged in state)
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': customerToken,
          'refreshToken': 'refresh-token',
          'userId': customerId,
          'email': customerEmail,
          'fullName': customerName,
          'role': 'Customer',
          'isActive': true,
          'isProfileComplete': true,
        },
      );
      await authProvider.login(customerEmail, customerPassword);
      expect(authProvider.isAuthenticated, isTrue);

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.token, isNull);
      expect(authProvider.email, isNull);

      verify(mockSecureStorageService.clearAll()).called(1);
    });
  });
}

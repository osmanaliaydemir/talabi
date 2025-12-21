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
import 'auth_courier_integration_test.mocks.dart';

void main() {
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

  group('Courier Authentication Integration Tests', () {
    const courierEmail = '[email protected]';
    const courierPassword = 'Password123!';
    const courierName = 'Test Courier';
    const courierToken = 'courier-test-token-123';
    const courierId = 'courier-id-123';

    test('should successfully register a courier', () async {
      // Arrange
      when(mockApiService.register(any, any, any)).thenAnswer(
        (_) async => {
          'token': courierToken,
          'refreshToken': 'refresh-token',
          'userId': courierId,
          'email': courierEmail,
          'fullName': courierName,
          'role': 'Courier',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Act
      await authProvider.register(courierEmail, courierPassword, courierName);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.email, courierEmail);
      expect(authProvider.fullName, courierName);
      expect(authProvider.role, 'Courier');
      expect(authProvider.userId, courierId);

      verify(
        mockApiService.register(courierEmail, courierPassword, courierName),
      ).called(1);
      verify(mockSecureStorageService.setToken(courierToken)).called(1);
      verify(mockSecureStorageService.setRole('Courier')).called(1);
    });

    test('should successfully login a courier', () async {
      // Arrange
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': courierToken,
          'refreshToken': 'refresh-token',
          'userId': courierId,
          'email': courierEmail,
          'fullName': courierName,
          'role': 'Courier',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Act
      await authProvider.login(courierEmail, courierPassword);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.role, 'Courier');
      expect(authProvider.email, courierEmail);

      verify(mockApiService.login(courierEmail, courierPassword)).called(1);
      verify(mockSecureStorageService.setToken(courierToken)).called(1);
    });

    test('should successfully logout', () async {
      // Arrange (Simulate logged in state)
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': courierToken,
          'refreshToken': 'refresh-token',
          'userId': courierId,
          'email': courierEmail,
          'fullName': courierName,
          'role': 'Courier',
          'isActive': true,
          'isProfileComplete': true,
        },
      );
      await authProvider.login(courierEmail, courierPassword);
      expect(authProvider.isAuthenticated, isTrue);

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.token, isNull);

      verify(mockSecureStorageService.clearAll()).called(1);
    });
  });
}

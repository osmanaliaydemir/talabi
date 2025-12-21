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
import 'auth_vendor_integration_test.mocks.dart';

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

  group('Vendor Authentication Integration Tests', () {
    const vendorEmail = '[email protected]';
    const vendorPassword = 'Password123!';
    const vendorName = 'Test Vendor';
    const vendorToken = 'vendor-test-token-123';
    const vendorId = 'vendor-id-123';

    test('should successfully register a vendor', () async {
      // Arrange
      when(mockApiService.register(any, any, any)).thenAnswer(
        (_) async => {
          'token': vendorToken,
          'refreshToken': 'refresh-token',
          'userId': vendorId,
          'email': vendorEmail,
          'fullName': vendorName,
          'role': 'Vendor',
          'isActive': true,
          'isProfileComplete': false, // Vendor might need profile completion
        },
      );

      // Act
      await authProvider.register(vendorEmail, vendorPassword, vendorName);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.email, vendorEmail);
      expect(authProvider.fullName, vendorName);
      expect(authProvider.role, 'Vendor');
      expect(authProvider.userId, vendorId);
      expect(authProvider.isProfileComplete, isFalse);

      verify(
        mockApiService.register(vendorEmail, vendorPassword, vendorName),
      ).called(1);
      verify(mockSecureStorageService.setToken(vendorToken)).called(1);
      verify(mockSecureStorageService.setRole('Vendor')).called(1);
    });

    test('should successfully login a vendor with delivery zones', () async {
      // Arrange
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': vendorToken,
          'refreshToken': 'refresh-token',
          'userId': vendorId,
          'email': vendorEmail,
          'fullName': vendorName,
          'role': 'Vendor',
          'isActive': true,
          'isProfileComplete': true,
          'hasDeliveryZones': true,
        },
      );

      // Act
      await authProvider.login(vendorEmail, vendorPassword);

      // Assert
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.role, 'Vendor');
      expect(authProvider.isProfileComplete, isTrue);
      expect(authProvider.hasDeliveryZones, isTrue);

      verify(mockApiService.login(vendorEmail, vendorPassword)).called(1);
      verify(mockSecureStorageService.setToken(vendorToken)).called(1);
    });

    test('should successfully logout', () async {
      // Arrange (Simulate logged in state)
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': vendorToken,
          'refreshToken': 'refresh-token',
          'userId': vendorId,
          'email': vendorEmail,
          'fullName': vendorName,
          'role': 'Vendor',
          'isActive': true,
          'isProfileComplete': true,
        },
      );
      await authProvider.login(vendorEmail, vendorPassword);
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

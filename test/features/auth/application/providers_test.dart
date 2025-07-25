import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mabquiz/src/core/config/app_config.dart';
import 'package:mabquiz/src/core/config/config_providers.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/application/auth_service.dart';
import 'package:mabquiz/src/features/auth/data/auth_repository.dart';
import 'package:mabquiz/src/features/auth/data/mock_auth_repository.dart' as mock_repo;
import 'package:mabquiz/src/features/auth/data/models/app_user.dart';

import 'providers_test.mocks.dart';

@GenerateMocks([AuthRepository, AuthService, FirebaseAuth])
void main() {
  group('Auth Providers', () {
    late ProviderContainer container;
    late MockAuthRepository mockRepository;
    late MockAuthService mockService;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockService = MockAuthService();
    });

    tearDown(() {
      container.dispose();
    });

    group('authRepositoryProvider', () {
      test('should return MockAuthRepository when useMockAuth is true', () {
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: 500,
                enablePersistence: true,
              ),
            ),
          ],
        );

        final repository = container.read(authRepositoryProvider);

        expect(repository, isA<mock_repo.MockAuthRepository>());
      });

      test('should return FirebaseAuthRepository when useMockAuth is false', () {
        // Skip this test since Firebase initialization is complex in unit tests
        // This would be better tested in integration tests
      }, skip: 'Firebase initialization required');

      test('should configure MockAuthRepository with correct delay', () {
        const expectedDelay = 1000;
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: expectedDelay,
                enablePersistence: true,
              ),
            ),
          ],
        );

        final repository = container.read(authRepositoryProvider) as mock_repo.MockAuthRepository;

        expect(repository.simulatedDelay, const Duration(milliseconds: expectedDelay));
      });

      test('should react to configuration changes', () {
        // Start with mock auth
        container = ProviderContainer(
          overrides: [
            useMockAuthProvider.overrideWithValue(true),
            authConfigProvider.overrideWithValue(
              const AuthConfig(
                useMockAuth: true,
                mockAuthDelay: 500,
                enablePersistence: true,
              ),
            ),
          ],
        );

        var repository = container.read(authRepositoryProvider);
        expect(repository, isA<mock_repo.MockAuthRepository>());

        // Test changing delay configuration
        container.updateOverrides([
          useMockAuthProvider.overrideWithValue(true),
          authConfigProvider.overrideWithValue(
            const AuthConfig(
              useMockAuth: true,
              mockAuthDelay: 2000,
              enablePersistence: true,
            ),
          ),
        ]);

        repository = container.read(authRepositoryProvider);
        expect(repository, isA<mock_repo.MockAuthRepository>());
        expect((repository as mock_repo.MockAuthRepository).simulatedDelay,
               const Duration(milliseconds: 2000));
      });
    });

    group('authServiceProvider', () {
      test('should create AuthService with correct repository', () {
        when(mockRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final service = container.read(authServiceProvider);

        expect(service, isA<AuthService>());
        // Verify that the service was created with the mock repository
        expect(service.authStateChanges, isA<Stream<AppUser?>>());
      });

      test('should be a singleton within the container', () {
        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final service1 = container.read(authServiceProvider);
        final service2 = container.read(authServiceProvider);

        expect(identical(service1, service2), isTrue);
      });

      test('should recreate service when repository changes', () {
        final mockRepository2 = MockAuthRepository();

        container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );

        final service1 = container.read(authServiceProvider);

        // Change repository
        container.updateOverrides([
          authRepositoryProvider.overrideWithValue(mockRepository2),
        ]);

        final service2 = container.read(authServiceProvider);

        expect(identical(service1, service2), isFalse);
      });
    });

    group('authStateProvider', () {
      test('should emit user when authenticated', () async {
        final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');
        when(mockService.authStateChanges)
            .thenAnswer((_) => Stream.value(testUser));

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit
        await container.read(authStateProvider.future);
        final authState = container.read(authStateProvider);

        expect(authState.hasValue, isTrue);
        expect(authState.value, testUser);
      });

      test('should emit null when not authenticated', () async {
        when(mockService.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit
        await container.read(authStateProvider.future);
        final authState = container.read(authStateProvider);

        expect(authState.hasValue, isTrue);
        expect(authState.value, isNull);
      });

      test('should emit loading state initially', () {
        when(mockService.authStateChanges)
            .thenAnswer((_) => Stream.fromFuture(
                Future.delayed(const Duration(milliseconds: 100), () => null)));

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        final authState = container.read(authStateProvider);

        expect(authState, const AsyncValue<AppUser?>.loading());
      });

      test('should emit error state when stream fails', () async {
        final testError = Exception('Auth stream error');
        when(mockService.authStateChanges)
            .thenAnswer((_) => Stream.error(testError));

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit error
        try {
          await container.read(authStateProvider.future);
        } catch (e) {
          // Expected to throw
        }

        final authState = container.read(authStateProvider);
        expect(authState.hasError, isTrue);
        expect(authState.error, testError);
      });

      test('should keep alive and maintain state', () async {
        final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');
        when(mockService.authStateChanges)
            .thenAnswer((_) => Stream.value(testUser));

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Wait for the stream to emit
        await container.read(authStateProvider.future);
        final authState1 = container.read(authStateProvider);
        expect(authState1.hasValue, isTrue);

        // Simulate some time passing and read again
        await Future.delayed(const Duration(milliseconds: 10));
        final authState2 = container.read(authStateProvider);

        // Should maintain the same state due to keepAlive
        expect(authState2.hasValue, isTrue);
        expect(authState2.value, testUser);
      });

      test('should handle multiple state changes', () async {
        final testUser1 = AppUser(uid: 'user1', email: 'user1@example.com');
        final testUser2 = AppUser(uid: 'user2', email: 'user2@example.com');

        final streamController = StreamController<AppUser?>();
        when(mockService.authStateChanges)
            .thenAnswer((_) => streamController.stream);

        container = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockService),
          ],
        );

        final states = <AsyncValue<AppUser?>>[];
        container.listen(authStateProvider, (previous, next) {
          states.add(next);
        });

        // Emit different states
        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 1));

        streamController.add(testUser1);
        await Future.delayed(const Duration(milliseconds: 1));

        streamController.add(testUser2);
        await Future.delayed(const Duration(milliseconds: 1));

        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 1));

        expect(states.length, 4);
        expect(states[0].value, isNull);
        expect(states[1].value, testUser1);
        expect(states[2].value, testUser2);
        expect(states[3].value, isNull);

        await streamController.close();
      });
    });

    group('currentUserProvider', () {
      test('should return user when auth state has data', () async {
        final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');

        container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(testUser),
            ),
          ],
        );

        // Wait for the stream to emit
        await container.read(authStateProvider.future);
        final currentUser = container.read(currentUserProvider);

        expect(currentUser, testUser);
      });

      test('should return null when auth state is loading', () {
        container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.fromFuture(
                Future.delayed(const Duration(milliseconds: 100), () => null),
              ),
            ),
          ],
        );

        final currentUser = container.read(currentUserProvider);

        expect(currentUser, isNull);
      });

      test('should return null when auth state has error', () {
        container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.error(Exception('Test error')),
            ),
          ],
        );

        final currentUser = container.read(currentUserProvider);

        expect(currentUser, isNull);
      });

      test('should return null when user is not authenticated', () {
        container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(null),
            ),
          ],
        );

        final currentUser = container.read(currentUserProvider);

        expect(currentUser, isNull);
      });

      test('should react to auth state changes', () async {
        final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');

        // Create a stream controller to control the auth state
        final streamController = StreamController<AppUser?>();

        container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => streamController.stream,
            ),
          ],
        );

        // Start with null user
        streamController.add(null);
        await Future.delayed(const Duration(milliseconds: 1));

        var currentUser = container.read(currentUserProvider);
        expect(currentUser, isNull);

        // Change to authenticated user
        streamController.add(testUser);
        await Future.delayed(const Duration(milliseconds: 1));

        currentUser = container.read(currentUserProvider);
        expect(currentUser, testUser);

        await streamController.close();
      });
    });

    group('authLoadingProvider', () {
      test('should have initial value of false', () {
        container = ProviderContainer();

        final isLoading = container.read(authLoadingProvider);

        expect(isLoading, isFalse);
      });

      test('should allow updating loading state', () {
        container = ProviderContainer();

        // Initial state
        expect(container.read(authLoadingProvider), isFalse);

        // Update to loading
        container.read(authLoadingProvider.notifier).state = true;
        expect(container.read(authLoadingProvider), isTrue);

        // Update back to not loading
        container.read(authLoadingProvider.notifier).state = false;
        expect(container.read(authLoadingProvider), isFalse);
      });

      test('should notify listeners when state changes', () {
        container = ProviderContainer();

        final states = <bool>[];
        container.listen(authLoadingProvider, (previous, next) {
          states.add(next);
        });

        // Change state multiple times
        container.read(authLoadingProvider.notifier).state = true;
        container.read(authLoadingProvider.notifier).state = false;
        container.read(authLoadingProvider.notifier).state = true;

        expect(states, [true, false, true]);
      });

      test('should be independent across different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(authLoadingProvider.notifier).state = true;
        container2.read(authLoadingProvider.notifier).state = false;

        expect(container1.read(authLoadingProvider), isTrue);
        expect(container2.read(authLoadingProvider), isFalse);

        container1.dispose();
        container2.dispose();
      });
    });

    group('authErrorProvider', () {
      test('should have initial value of null', () {
        container = ProviderContainer();

        final error = container.read(authErrorProvider);

        expect(error, isNull);
      });

      test('should allow updating error state', () {
        container = ProviderContainer();

        // Initial state
        expect(container.read(authErrorProvider), isNull);

        // Set error
        const errorMessage = 'Test error message';
        container.read(authErrorProvider.notifier).state = errorMessage;
        expect(container.read(authErrorProvider), errorMessage);

        // Clear error
        container.read(authErrorProvider.notifier).state = null;
        expect(container.read(authErrorProvider), isNull);
      });

      test('should notify listeners when error changes', () {
        container = ProviderContainer();

        final errors = <String?>[];
        container.listen(authErrorProvider, (previous, next) {
          errors.add(next);
        });

        // Change error multiple times
        container.read(authErrorProvider.notifier).state = 'Error 1';
        container.read(authErrorProvider.notifier).state = 'Error 2';
        container.read(authErrorProvider.notifier).state = null;

        expect(errors, ['Error 1', 'Error 2', null]);
      });

      test('should handle different error types', () {
        container = ProviderContainer();

        final errorMessages = [
          'Network error',
          'Invalid credentials',
          'Service unavailable',
          '',
        ];

        for (final errorMessage in errorMessages) {
          container.read(authErrorProvider.notifier).state = errorMessage;
          expect(container.read(authErrorProvider), errorMessage);
        }
      });

      test('should be independent across different containers', () {
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        container1.read(authErrorProvider.notifier).state = 'Error 1';
        container2.read(authErrorProvider.notifier).state = 'Error 2';

        expect(container1.read(authErrorProvider), 'Error 1');
        expect(container2.read(authErrorProvider), 'Error 2');

        container1.dispose();
        container2.dispose();
      });
    });
  });

  group('Provider Integration Tests', () {
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test('should work together in a complete auth flow simulation', () async {
      final mockRepository = MockAuthRepository();
      final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');

      // Setup mock repository behavior
      when(mockRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Initial state - not authenticated
      expect(container.read(currentUserProvider), isNull);
      expect(container.read(authLoadingProvider), isFalse);
      expect(container.read(authErrorProvider), isNull);

      // Simulate loading state
      container.read(authLoadingProvider.notifier).state = true;
      expect(container.read(authLoadingProvider), isTrue);

      // Simulate successful authentication
      when(mockRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(testUser));

      // Update auth state provider to reflect new state
      container.invalidate(authStateProvider);

      // Simulate end of loading
      container.read(authLoadingProvider.notifier).state = false;

      expect(container.read(authLoadingProvider), isFalse);
      expect(container.read(authErrorProvider), isNull);
    });

    test('should handle error scenarios correctly', () async {
      final mockRepository = MockAuthRepository();
      final testError = Exception('Authentication failed');

      when(mockRepository.authStateChanges)
          .thenAnswer((_) => Stream.error(testError));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Simulate error state
      container.read(authErrorProvider.notifier).state = 'Authentication failed';
      container.read(authLoadingProvider.notifier).state = false;

      expect(container.read(authLoadingProvider), isFalse);
      expect(container.read(authErrorProvider), 'Authentication failed');
      expect(container.read(currentUserProvider), isNull);
    });

    test('should maintain provider dependencies correctly', () {
      final mockRepository = MockAuthRepository();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Verify that authServiceProvider depends on authRepositoryProvider
      final service = container.read(authServiceProvider);
      expect(service, isA<AuthService>());

      // Verify that authStateProvider depends on authServiceProvider
      final authState = container.read(authStateProvider);
      expect(authState, isA<AsyncValue<AppUser?>>());

      // Verify that currentUserProvider depends on authStateProvider
      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isA<AppUser?>());
    });

    test('should handle provider disposal correctly', () {
      final mockRepository = MockAuthRepository();

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Read all providers to initialize them
      container.read(authRepositoryProvider);
      container.read(authServiceProvider);
      container.read(authStateProvider);
      container.read(currentUserProvider);
      container.read(authLoadingProvider);
      container.read(authErrorProvider);

      // Dispose container - should not throw
      expect(() => container.dispose(), returnsNormally);
    });

    test('should handle concurrent provider access', () async {
      final mockRepository = MockAuthRepository();
      final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');

      when(mockRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(testUser));

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Simulate concurrent access to providers
      final futures = List.generate(10, (_) async {
        return [
          container.read(authRepositoryProvider),
          container.read(authServiceProvider),
          container.read(authStateProvider),
          container.read(currentUserProvider),
          container.read(authLoadingProvider),
          container.read(authErrorProvider),
        ];
      });

      final results = await Future.wait(futures);

      // All results should be consistent
      for (final result in results) {
        expect(result[0], isA<AuthRepository>());
        expect(result[1], isA<AuthService>());
        expect(result[2], isA<AsyncValue<AppUser?>>());
        expect(result[3], isA<AppUser?>());
        expect(result[4], isA<bool>());
        expect(result[5], isA<String?>());
      }
    });
  });
}
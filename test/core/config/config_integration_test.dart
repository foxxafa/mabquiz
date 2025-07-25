import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mabquiz/src/core/config/config.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/data/mock_auth_repository.dart';

void main() {
  group('Configuration Integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should provide correct configuration in development', () {
      final config = container.read(appConfigProvider);

      expect(config.environment, AppEnvironment.development);
      expect(config.auth.useMockAuth, true);
      expect(config.firebase.useEmulator, true);
    });

    test('should provide mock auth flag correctly', () {
      final useMockAuth = container.read(useMockAuthProvider);

      expect(useMockAuth, true);
    });

    test('should provide mock auth repository when configured', () {
      final useMockAuth = container.read(useMockAuthProvider);

      // Only test repository creation if mock auth is enabled
      if (useMockAuth) {
        final repository = container.read(authRepositoryProvider);
        expect(repository, isA<MockAuthRepository>());
      }
    });

    test('should provide correct auth config', () {
      final authConfig = container.read(authConfigProvider);

      expect(authConfig.useMockAuth, true);
      expect(authConfig.mockAuthDelay, 1000);
      expect(authConfig.enablePersistence, true);
    });

    test('should provide correct firebase config', () {
      final firebaseConfig = container.read(firebaseConfigProvider);

      expect(firebaseConfig.useEmulator, true);
      expect(firebaseConfig.emulatorHost, isNotEmpty);
      expect(firebaseConfig.authEmulatorPort, greaterThan(0));
      expect(firebaseConfig.enabled, true);
    });

    test('should provide correct environment', () {
      final environment = container.read(environmentProvider);

      expect(environment, AppEnvironment.development);
    });

    test('should provide emulator flag correctly', () {
      final useEmulator = container.read(useFirebaseEmulatorProvider);

      expect(useEmulator, true);
    });
  });
}
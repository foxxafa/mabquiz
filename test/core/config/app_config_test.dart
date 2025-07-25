import 'package:flutter_test/flutter_test.dart';
import 'package:mabquiz/src/core/config/config.dart';

void main() {
  group('AppConfig', () {
    test('development config should use correct settings', () {
      final config = AppConfig.development();

      expect(config.environment, AppEnvironment.development);
      expect(config.firebase.useEmulator, true);
      expect(config.firebase.enabled, true);
      expect(config.auth.useMockAuth, true);
      expect(config.auth.mockAuthDelay, 1000);
      expect(config.auth.enablePersistence, true);
    });

    test('production config should use correct settings', () {
      final config = AppConfig.production();

      expect(config.environment, AppEnvironment.production);
      expect(config.firebase.useEmulator, false);
      expect(config.firebase.enabled, true);
      expect(config.auth.useMockAuth, false);
      expect(config.auth.mockAuthDelay, 0);
      expect(config.auth.enablePersistence, true);
    });
  });

  group('FirebaseConfig', () {
    test('development config should configure emulator', () {
      final config = FirebaseConfig.development();

      expect(config.useEmulator, true);
      expect(config.emulatorHost, isNotEmpty);
      expect(config.authEmulatorPort, greaterThan(0));
      expect(config.enabled, true);
    });

    test('production config should not use emulator', () {
      final config = FirebaseConfig.production();

      expect(config.useEmulator, false);
      expect(config.emulatorHost, isEmpty);
      expect(config.authEmulatorPort, 0);
      expect(config.enabled, true);
    });
  });

  group('AuthConfig', () {
    test('development config should use mock auth', () {
      final config = AuthConfig.development();

      expect(config.useMockAuth, true);
      expect(config.mockAuthDelay, greaterThan(0));
      expect(config.enablePersistence, true);
    });

    test('production config should use real auth', () {
      final config = AuthConfig.production();

      expect(config.useMockAuth, false);
      expect(config.mockAuthDelay, 0);
      expect(config.enablePersistence, true);
    });
  });
}
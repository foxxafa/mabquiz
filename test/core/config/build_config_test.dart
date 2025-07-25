import 'package:flutter_test/flutter_test.dart';
import 'package:mabquiz/src/core/config/build_config.dart';

void main() {
  group('BuildConfig', () {
    test('should have default values', () {
      expect(BuildConfig.firebaseEmulatorHost, 'localhost');
      expect(BuildConfig.firebaseAuthEmulatorPort, 9099);
      expect(BuildConfig.forceMockAuth, false);
      expect(BuildConfig.disableFirebase, false);
    });

    test('should determine environment correctly', () {
      // In test mode, this should be development
      expect(BuildConfig.environment, 'development');
      expect(BuildConfig.isDevelopment, true);
      expect(BuildConfig.isProduction, false);
    });

    test('printConfig should not throw', () {
      expect(() => BuildConfig.printConfig(), returnsNormally);
    });
  });
}
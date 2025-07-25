import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mabquiz/src/features/auth/data/auth_error_mapper.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/error_messages.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/form_validators.dart';

void main() {
  group('Error Handling Integration Tests', () {
    test('complete error mapping flow works', () {
      // Test Firebase exception mapping
      final firebaseException = FirebaseAuthException(code: 'invalid-credential');
      final mappedException = AuthErrorMapper.mapFirebaseException(firebaseException);

      expect(mappedException, isA<InvalidCredentialsException>());
      expect(mappedException.code, equals('invalid-credentials'));

      // Test localized message
      final localizedMessage = AuthErrorMessages.getAuthExceptionMessage(mappedException);
      expect(localizedMessage, contains('Geçersiz email veya şifre'));
    });

    test('form validation integration works', () {
      // Test email validation
      expect(AuthFormValidators.validateEmail('test@example.com'), isNull);
      expect(AuthFormValidators.validateEmail('invalid'), isNotNull);

      // Test password validation
      expect(AuthFormValidators.validatePassword('validPass123'), isNull);
      expect(AuthFormValidators.validatePassword('123'), isNotNull);

      // Test password confirmation
      expect(AuthFormValidators.validatePasswordConfirmation('pass123', 'pass123'), isNull);
      expect(AuthFormValidators.validatePasswordConfirmation('pass123', 'different'), isNotNull);
    });

    test('error message localization works', () {
      // Test Turkish messages (default)
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Geçersiz email veya şifre'));

      // Test language switching
      AuthErrorMessages.setLanguage('en');
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Invalid email or password'));

      // Reset to Turkish
      AuthErrorMessages.setLanguage('tr');
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Geçersiz email veya şifre'));
    });

    test('password strength calculation works', () {
      expect(AuthFormValidators.getPasswordStrength(''), equals(0));
      expect(AuthFormValidators.getPasswordStrength('weak'), equals(1));
      expect(AuthFormValidators.getPasswordStrength('StrongPassword123!'), equals(4));

      // Test strength descriptions
      expect(AuthFormValidators.getPasswordStrengthDescription(0), equals('Çok zayıf'));
      expect(AuthFormValidators.getPasswordStrengthDescription(4), equals('Çok güçlü'));
    });

    test('form validation helpers work', () {
      final loginErrors = AuthFormValidators.validateLoginForm(
        email: 'test@example.com',
        password: 'validPassword123',
      );

      expect(loginErrors['email'], isNull);
      expect(loginErrors['password'], isNull);

      final registrationErrors = AuthFormValidators.validateRegistrationForm(
        email: 'test@example.com',
        password: 'validPassword123',
        passwordConfirmation: 'validPassword123',
        displayName: 'John Doe',
      );

      expect(registrationErrors['email'], isNull);
      expect(registrationErrors['password'], isNull);
      expect(registrationErrors['passwordConfirmation'], isNull);
      expect(registrationErrors['displayName'], isNull);
    });

    test('error mapping handles various exception types', () {
      // Test network exception
      final networkError = Exception('network connection failed');
      final mappedNetwork = AuthErrorMapper.mapException(networkError);
      expect(mappedNetwork, isA<NetworkException>());

      // Test timeout exception
      final timeoutError = Exception('timeout occurred');
      final mappedTimeout = AuthErrorMapper.mapException(timeoutError);
      expect(mappedTimeout.code, equals('timeout'));

      // Test unknown exception
      final unknownError = Exception('some random error');
      final mappedUnknown = AuthErrorMapper.mapException(unknownError);
      expect(mappedUnknown, isA<UnknownAuthException>());
    });

    test('success and confirmation messages work', () {
      expect(AuthErrorMessages.getSuccessMessage('login'),
             equals('Başarıyla giriş yapıldı'));
      expect(AuthErrorMessages.getSuccessMessage('registration'),
             equals('Hesap başarıyla oluşturuldu'));

      expect(AuthErrorMessages.getConfirmationMessage('logout'),
             equals('Çıkış yapmak istediğinizden emin misiniz?'));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mabquiz/src/features/auth/data/auth_error_mapper.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/error_messages.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/form_validators.dart';

void main() {
  group('AuthErrorMapper', () {
    test('maps Firebase exceptions correctly', () {
      // Test invalid credentials
      final invalidCredException = FirebaseAuthException(code: 'invalid-credential');
      final mappedException = AuthErrorMapper.mapFirebaseException(invalidCredException);
      expect(mappedException, isA<InvalidCredentialsException>());

      // Test weak password
      final weakPasswordException = FirebaseAuthException(code: 'weak-password');
      final mappedWeakPassword = AuthErrorMapper.mapFirebaseException(weakPasswordException);
      expect(mappedWeakPassword, isA<WeakPasswordException>());

      // Test email already in use
      final emailInUseException = FirebaseAuthException(code: 'email-already-in-use');
      final mappedEmailInUse = AuthErrorMapper.mapFirebaseException(emailInUseException);
      expect(mappedEmailInUse, isA<EmailAlreadyInUseException>());

      // Test network error
      final networkException = FirebaseAuthException(code: 'network-request-failed');
      final mappedNetwork = AuthErrorMapper.mapFirebaseException(networkException);
      expect(mappedNetwork, isA<NetworkException>());
    });

    test('maps generic exceptions correctly', () {
      // Test network-related exception
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

    test('gets localized messages correctly', () {
      const invalidCreds = InvalidCredentialsException();
      final message = AuthErrorMapper.getLocalizedMessage(invalidCreds);
      expect(message, contains('Geçersiz email veya şifre'));

      const weakPassword = WeakPasswordException();
      final weakMessage = AuthErrorMapper.getLocalizedMessage(weakPassword);
      expect(weakMessage, contains('Şifre çok zayıf'));

      const emailInUse = EmailAlreadyInUseException();
      final emailMessage = AuthErrorMapper.getLocalizedMessage(emailInUse);
      expect(emailMessage, contains('Bu email adresi zaten kullanımda'));
    });
  });

  group('AuthErrorMessages', () {
    test('returns correct Turkish messages', () {
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Geçersiz email veya şifre'));
      expect(AuthErrorMessages.getMessage('weak-password'),
             contains('Şifre çok zayıf'));
      expect(AuthErrorMessages.getMessage('email-already-in-use'),
             contains('Bu email adresi zaten kullanımda'));
      expect(AuthErrorMessages.getMessage('network-error'),
             contains('İnternet bağlantısı sorunu'));
    });

    test('handles language switching', () {
      // Set to English
      AuthErrorMessages.setLanguage('en');
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Invalid email or password'));

      // Set back to Turkish
      AuthErrorMessages.setLanguage('tr');
      expect(AuthErrorMessages.getMessage('invalid-credentials'),
             contains('Geçersiz email veya şifre'));
    });

    test('gets auth exception messages correctly', () {
      const exception = InvalidCredentialsException();
      final message = AuthErrorMessages.getAuthExceptionMessage(exception);
      expect(message, contains('Geçersiz email veya şifre'));
    });

    test('gets success messages correctly', () {
      expect(AuthErrorMessages.getSuccessMessage('login'),
             equals('Başarıyla giriş yapıldı'));
      expect(AuthErrorMessages.getSuccessMessage('registration'),
             equals('Hesap başarıyla oluşturuldu'));
      expect(AuthErrorMessages.getSuccessMessage('logout'),
             equals('Başarıyla çıkış yapıldı'));
    });
  });

  group('AuthFormValidators', () {
    test('validates email correctly', () {
      // Valid emails
      expect(AuthFormValidators.validateEmail('test@example.com'), isNull);
      expect(AuthFormValidators.validateEmail('user.name@domain.co.uk'), isNull);

      // Invalid emails
      expect(AuthFormValidators.validateEmail(''), isNotNull);
      expect(AuthFormValidators.validateEmail('invalid-email'), isNotNull);
      expect(AuthFormValidators.validateEmail('test@'), isNotNull);
      expect(AuthFormValidators.validateEmail('@domain.com'), isNotNull);
      expect(AuthFormValidators.validateEmail('test..test@domain.com'), isNotNull);
    });

    test('validates password correctly', () {
      // Valid passwords
      expect(AuthFormValidators.validatePassword('password123'), isNull);
      expect(AuthFormValidators.validatePassword('strongPass1'), isNull);

      // Invalid passwords
      expect(AuthFormValidators.validatePassword(''), isNotNull);
      expect(AuthFormValidators.validatePassword('12345'), isNotNull);
      expect(AuthFormValidators.validatePassword('123456'), isNotNull); // Common weak password
      expect(AuthFormValidators.validatePassword('password'), isNotNull); // Common weak password
    });

    test('validates password confirmation correctly', () {
      const password = 'testPassword123';

      // Valid confirmation
      expect(AuthFormValidators.validatePasswordConfirmation(password, password), isNull);

      // Invalid confirmations
      expect(AuthFormValidators.validatePasswordConfirmation('', password), isNotNull);
      expect(AuthFormValidators.validatePasswordConfirmation('different', password), isNotNull);
    });

    test('validates display name correctly', () {
      // Valid names
      expect(AuthFormValidators.validateDisplayName('John Doe'), isNull);
      expect(AuthFormValidators.validateDisplayName('Ahmet Yılmaz'), isNull);
      expect(AuthFormValidators.validateDisplayName(''), isNull); // Optional field

      // Invalid names
      expect(AuthFormValidators.validateDisplayName('A'), isNotNull); // Too short
      expect(AuthFormValidators.validateDisplayName('A' * 51), isNotNull); // Too long
      expect(AuthFormValidators.validateDisplayName('John123'), isNotNull); // Invalid characters
    });

    test('validates phone number correctly', () {
      // Valid phone numbers
      expect(AuthFormValidators.validatePhoneNumber('05551234567'), isNull);
      expect(AuthFormValidators.validatePhoneNumber('+905551234567'), isNull);
      expect(AuthFormValidators.validatePhoneNumber(''), isNull); // Optional field

      // Invalid phone numbers
      expect(AuthFormValidators.validatePhoneNumber('123456789'), isNotNull);
      expect(AuthFormValidators.validatePhoneNumber('05551234'), isNotNull);
      expect(AuthFormValidators.validatePhoneNumber('04551234567'), isNotNull); // Wrong prefix
    });

    test('calculates password strength correctly', () {
      expect(AuthFormValidators.getPasswordStrength(''), equals(0));
      expect(AuthFormValidators.getPasswordStrength('123456'), equals(1));
      expect(AuthFormValidators.getPasswordStrength('password'), equals(1));
      expect(AuthFormValidators.getPasswordStrength('Password1'), greaterThan(2));
      expect(AuthFormValidators.getPasswordStrength('StrongP@ssw0rd123'), equals(4));
    });

    test('validates login form correctly', () {
      final result = AuthFormValidators.validateLoginForm(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result['email'], isNull);
      expect(result['password'], isNull);

      final invalidResult = AuthFormValidators.validateLoginForm(
        email: 'invalid-email',
        password: '',
      );

      expect(invalidResult['email'], isNotNull);
      expect(invalidResult['password'], isNotNull);
    });

    test('validates registration form correctly', () {
      final result = AuthFormValidators.validateRegistrationForm(
        email: 'test@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
        displayName: 'John Doe',
      );

      expect(result['email'], isNull);
      expect(result['password'], isNull);
      expect(result['passwordConfirmation'], isNull);
      expect(result['displayName'], isNull);

      final invalidResult = AuthFormValidators.validateRegistrationForm(
        email: 'invalid-email',
        password: '123',
        passwordConfirmation: '456',
        displayName: 'A',
      );

      expect(invalidResult['email'], isNotNull);
      expect(invalidResult['password'], isNotNull);
      expect(invalidResult['passwordConfirmation'], isNotNull);
      expect(invalidResult['displayName'], isNotNull);
    });
  });

  group('String Extensions', () {
    test('email validation extension works', () {
      expect('test@example.com'.emailError, isNull);
      expect('invalid-email'.emailError, isNotNull);
    });

    test('password validation extension works', () {
      expect('password123'.passwordError, isNull);
      expect('123'.passwordError, isNotNull);
    });

    test('required field validation extension works', () {
      expect('value'.requiredError('Field'), isNull);
      expect(''.requiredError('Field'), isNotNull);
      expect(null.requiredError('Field'), isNotNull);
    });

    test('password strength extension works', () {
      expect(''.passwordStrength, equals(0));
      expect('password123'.passwordStrength, greaterThan(0));
      expect('StrongP@ssw0rd123'.passwordStrength, equals(4));
    });
  });

  group('Exception Extensions', () {
    test('AuthException extension works', () {
      const exception = InvalidCredentialsException();
      expect(exception.localizedMessage, contains('Geçersiz email veya şifre'));
    });

    test('Generic exception message works', () {
      final exception = Exception('network error');
      final message = AuthErrorMessages.getExceptionMessage(exception);
      expect(message, isNotNull);
    });
  });
}
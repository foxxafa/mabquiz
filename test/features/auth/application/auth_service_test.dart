import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mabquiz/src/features/auth/application/auth_service.dart';
import 'package:mabquiz/src/features/auth/data/auth_repository.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/data/models/app_user.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('AuthService', () {
    late MockAuthRepository mockRepository;
    late AuthService authService;

    setUp(() {
      mockRepository = MockAuthRepository();
      authService = AuthService(mockRepository);
    });

    group('authStateChanges', () {
      test('should return repository auth state stream', () async {
        final testUser = AppUser(uid: 'test-uid', email: 'test@example.com');
        when(mockRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(testUser));

        final authStates = <AppUser?>[];
        final subscription = authService.authStateChanges.listen(authStates.add);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authStates.length, 1);
        expect(authStates[0], testUser);

        await subscription.cancel();
      });

      test('should emit null when no user is signed in', () async {
        when(mockRepository.authStateChanges)
            .thenAnswer((_) => Stream.value(null));

        final authStates = <AppUser?>[];
        final subscription = authService.authStateChanges.listen(authStates.add);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(authStates.length, 1);
        expect(authStates[0], isNull);

        await subscription.cancel();
      });
    });

    group('login', () {
      test('should login successfully with valid credentials', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.signInWithEmailAndPassword(email, password))
            .thenAnswer((_) async {});

        await authService.login(email, password);

        verify(mockRepository.signInWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should throw InvalidCredentialsException for empty email', () async {
        const email = '';
        const password = 'password123';

        expect(
          () => authService.login(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
      });

      test('should throw InvalidCredentialsException for invalid email format', () async {
        const email = 'invalid-email';
        const password = 'password123';

        expect(
          () => authService.login(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
      });

      test('should throw InvalidCredentialsException for empty password', () async {
        const email = 'test@example.com';
        const password = '';

        expect(
          () => authService.login(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
      });

      test('should throw WeakPasswordException for weak password', () async {
        const email = 'test@example.com';
        const password = '123'; // Too short

        expect(
          () => authService.login(email, password),
          throwsA(isA<WeakPasswordException>()),
        );

        verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
      });

      test('should propagate InvalidCredentialsException from repository', () async {
        const email = 'test@example.com';
        const password = 'wrongpassword';

        when(mockRepository.signInWithEmailAndPassword(email, password))
            .thenThrow(const InvalidCredentialsException());

        expect(
          () => authService.login(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verify(mockRepository.signInWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should propagate NetworkException from repository', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.signInWithEmailAndPassword(email, password))
            .thenThrow(const NetworkException());

        expect(
          () => authService.login(email, password),
          throwsA(isA<NetworkException>()),
        );

        verify(mockRepository.signInWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should wrap unknown exceptions as UnknownAuthException', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.signInWithEmailAndPassword(email, password))
            .thenThrow(Exception('Unknown error'));

        expect(
          () => authService.login(email, password),
          throwsA(isA<UnknownAuthException>()),
        );

        verify(mockRepository.signInWithEmailAndPassword(email, password))
            .called(1);
      });
    });
 group('register', () {
      test('should register successfully with valid credentials', () async {
        const email = 'newuser@example.com';
        const password = 'password123';

        when(mockRepository.createUserWithEmailAndPassword(email, password))
            .thenAnswer((_) async {});

        await authService.register(email, password);

        verify(mockRepository.createUserWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should throw InvalidCredentialsException for empty email', () async {
        const email = '';
        const password = 'password123';

        expect(
          () => authService.register(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.createUserWithEmailAndPassword(any, any));
      });

      test('should throw InvalidCredentialsException for invalid email format', () async {
        const email = 'invalid-email';
        const password = 'password123';

        expect(
          () => authService.register(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.createUserWithEmailAndPassword(any, any));
      });

      test('should throw InvalidCredentialsException for empty password', () async {
        const email = 'test@example.com';
        const password = '';

        expect(
          () => authService.register(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.createUserWithEmailAndPassword(any, any));
      });

      test('should throw WeakPasswordException for weak password', () async {
        const email = 'test@example.com';
        const password = '123'; // Too short

        expect(
          () => authService.register(email, password),
          throwsA(isA<WeakPasswordException>()),
        );

        verifyNever(mockRepository.createUserWithEmailAndPassword(any, any));
      });

      test('should propagate EmailAlreadyInUseException from repository', () async {
        const email = 'existing@example.com';
        const password = 'password123';

        when(mockRepository.createUserWithEmailAndPassword(email, password))
            .thenThrow(const EmailAlreadyInUseException());

        expect(
          () => authService.register(email, password),
          throwsA(isA<EmailAlreadyInUseException>()),
        );

        verify(mockRepository.createUserWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should propagate WeakPasswordException from repository', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.createUserWithEmailAndPassword(email, password))
            .thenThrow(const WeakPasswordException());

        expect(
          () => authService.register(email, password),
          throwsA(isA<WeakPasswordException>()),
        );

        verify(mockRepository.createUserWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should propagate NetworkException from repository', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.createUserWithEmailAndPassword(email, password))
            .thenThrow(const NetworkException());

        expect(
          () => authService.register(email, password),
          throwsA(isA<NetworkException>()),
        );

        verify(mockRepository.createUserWithEmailAndPassword(email, password))
            .called(1);
      });

      test('should wrap unknown exceptions as UnknownAuthException', () async {
        const email = 'test@example.com';
        const password = 'password123';

        when(mockRepository.createUserWithEmailAndPassword(email, password))
            .thenThrow(Exception('Unknown error'));

        expect(
          () => authService.register(email, password),
          throwsA(isA<UnknownAuthException>()),
        );

        verify(mockRepository.createUserWithEmailAndPassword(email, password))
            .called(1);
      });
    });

    group('logout', () {
      test('should logout successfully', () async {
        when(mockRepository.signOut()).thenAnswer((_) async {});

        await authService.logout();

        verify(mockRepository.signOut()).called(1);
      });

      test('should propagate NetworkException from repository', () async {
        when(mockRepository.signOut()).thenThrow(const NetworkException());

        expect(
          () => authService.logout(),
          throwsA(isA<NetworkException>()),
        );

        verify(mockRepository.signOut()).called(1);
      });

      test('should propagate ServiceUnavailableException from repository', () async {
        when(mockRepository.signOut()).thenThrow(const ServiceUnavailableException());

        expect(
          () => authService.logout(),
          throwsA(isA<ServiceUnavailableException>()),
        );

        verify(mockRepository.signOut()).called(1);
      });

      test('should wrap unknown exceptions as UnknownAuthException', () async {
        when(mockRepository.signOut()).thenThrow(Exception('Unknown error'));

        expect(
          () => authService.logout(),
          throwsA(isA<UnknownAuthException>()),
        );

        verify(mockRepository.signOut()).called(1);
      });
    });

    group('input validation', () {
      test('should validate email formats correctly', () async {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
        ];

        for (final email in validEmails) {
          when(mockRepository.signInWithEmailAndPassword(email, 'password123'))
              .thenAnswer((_) async {});

          // Should not throw for valid emails
          await authService.login(email, 'password123');
          verify(mockRepository.signInWithEmailAndPassword(email, 'password123')).called(1);
          reset(mockRepository);
        }
      });

      test('should reject invalid email formats', () async {
        final invalidEmails = [
          'invalid-email',
          '@example.com',
          'test@',
          'test.example.com',
          '',
        ];

        for (final email in invalidEmails) {
          expect(
            () => authService.login(email, 'password123'),
            throwsA(isA<InvalidCredentialsException>()),
          );
          verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
        }
      });

      test('should validate password requirements correctly', () async {
        final validPasswords = [
          'password123',
          'StrongP@ss1',
          'minimum6',
        ];

        for (final password in validPasswords) {
          when(mockRepository.signInWithEmailAndPassword('test@example.com', password))
              .thenAnswer((_) async {});

          // Should not throw for valid passwords
          await authService.login('test@example.com', password);
          verify(mockRepository.signInWithEmailAndPassword('test@example.com', password)).called(1);
          reset(mockRepository);
        }
      });

      test('should reject invalid passwords', () async {
        final invalidPasswords = [
          '',
          '123',
          '12345',
        ];

        for (final password in invalidPasswords) {
          if (password.isEmpty) {
            expect(
              () => authService.login('test@example.com', password),
              throwsA(isA<InvalidCredentialsException>()),
            );
          } else {
            expect(
              () => authService.login('test@example.com', password),
              throwsA(isA<WeakPasswordException>()),
            );
          }
          verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
        }
      });
    });

    group('error propagation', () {
      test('should maintain error types through the service layer', () async {
        final authExceptions = [
          const InvalidCredentialsException(),
          const WeakPasswordException(),
          const EmailAlreadyInUseException(),
          const NetworkException(),
          const ServiceUnavailableException(),
          const UnknownAuthException('Test error', 'test-code'),
        ];

        for (final exception in authExceptions) {
          when(mockRepository.signInWithEmailAndPassword('test@example.com', 'password123'))
              .thenThrow(exception);

          expect(
            () => authService.login('test@example.com', 'password123'),
            throwsA(exception.runtimeType),
          );

          reset(mockRepository);
        }
      });

      test('should wrap non-AuthException errors consistently', () async {
        final nonAuthExceptions = [
          Exception('Generic exception'),
          StateError('State error'),
          ArgumentError('Argument error'),
        ];

        for (final exception in nonAuthExceptions) {
          when(mockRepository.signInWithEmailAndPassword('test@example.com', 'password123'))
              .thenThrow(exception);

          expect(
            () => authService.login('test@example.com', 'password123'),
            throwsA(isA<UnknownAuthException>()),
          );

          reset(mockRepository);
        }
      });
    });

    group('business logic validation', () {
      test('should validate inputs before calling repository for login', () async {
        // Test that validation happens before repository call
        expect(
          () => authService.login('', 'password123'),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.signInWithEmailAndPassword(any, any));
      });

      test('should validate inputs before calling repository for register', () async {
        // Test that validation happens before repository call
        expect(
          () => authService.register('invalid-email', 'password123'),
          throwsA(isA<InvalidCredentialsException>()),
        );

        verifyNever(mockRepository.createUserWithEmailAndPassword(any, any));
      });

      test('should handle concurrent operations correctly', () async {
        when(mockRepository.signInWithEmailAndPassword('test@example.com', 'password123'))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Start multiple concurrent operations
        final futures = List.generate(3, (_) =>
            authService.login('test@example.com', 'password123'));

        await Future.wait(futures);

        verify(mockRepository.signInWithEmailAndPassword('test@example.com', 'password123'))
            .called(3);
      });
    });
  });
}
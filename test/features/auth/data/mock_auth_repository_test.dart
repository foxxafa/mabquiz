import 'package:flutter_test/flutter_test.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/data/mock_auth_repository.dart';
import 'package:mabquiz/src/features/auth/data/models/app_user.dart';

void main() {
  group('MockAuthRepository', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository(
        simulatedDelay: const Duration(milliseconds: 10), // Faster for tests
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('authStateChanges', () {
      test('should emit null initially when no user is signed in', () async {
        expect(repository.authStateChanges, emits(null));
      });

      test('should emit user when signed in', () async {
        final email = 'test@example.com';
        final password = 'password';

        // Listen to auth state changes
        final authStates = <AppUser?>[];
        final subscription = repository.authStateChanges.listen(authStates.add);

        // Sign in
        await repository.signInWithEmailAndPassword(email, password);

        // Wait for state to propagate
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authStates.length, 2); // null initially, then user
        expect(authStates[0], isNull);
        expect(authStates[1], isNotNull);
        expect(authStates[1]!.email, email);

        await subscription.cancel();
      });

      test('should emit null when signed out', () async {
        final email = 'test@example.com';
        final password = 'password';

        // Sign in first
        await repository.signInWithEmailAndPassword(email, password);

        final authStates = <AppUser?>[];
        final subscription = repository.authStateChanges.listen(authStates.add);

        // Sign out
        await repository.signOut();

        // Wait for state to propagate
        await Future.delayed(const Duration(milliseconds: 50));

        expect(authStates.last, isNull);

        await subscription.cancel();
      });
    });

group('signInWithEmailAndPassword', () {
      test('should sign in successfully with valid credentials', () async {
        const email = 'test@example.com';
        const password = 'password';

        await repository.signInWithEmailAndPassword(email, password);

        expect(repository.currentUser, isNotNull);
        expect(repository.currentUser!.email, email);
      });

      test('should throw InvalidCredentialsException with invalid email', () async {
        const email = 'invalid@example.com';
        const password = 'password';

        expect(
          () => repository.signInWithEmailAndPassword(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });

      test('should throw InvalidCredentialsException with invalid password', () async {
        const email = 'test@example.com';
        const password = 'wrongpassword';

        expect(
          () => repository.signInWithEmailAndPassword(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });

      test('should work with all predefined test users', () async {
        final testUsers = {
          'test@example.com': 'password',
          'admin@example.com': 'admin123',
          'user@example.com': 'user123',
        };

        for (final entry in testUsers.entries) {
          // Sign out first if needed
          if (repository.currentUser != null) {
            await repository.signOut();
          }

          await repository.signInWithEmailAndPassword(entry.key, entry.value);
          expect(repository.currentUser!.email, entry.key);
        }
      });

      test('should respect simulated delay', () async {
        final repository = MockAuthRepository(
          simulatedDelay: const Duration(milliseconds: 100),
        );

        final stopwatch = Stopwatch()..start();
        await repository.signInWithEmailAndPassword('test@example.com', 'password');
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
        repository.dispose();
      });
    });    group
('createUserWithEmailAndPassword', () {
      test('should create user successfully with valid credentials', () async {
        const email = 'newuser@example.com';
        const password = 'password123';

        await repository.createUserWithEmailAndPassword(email, password);

        expect(repository.currentUser, isNotNull);
        expect(repository.currentUser!.email, email);
      });

      test('should throw WeakPasswordException with weak password', () async {
        const email = 'newuser@example.com';
        const password = '123'; // Too short

        expect(
          () => repository.createUserWithEmailAndPassword(email, password),
          throwsA(isA<WeakPasswordException>()),
        );
      });

      test('should throw EmailAlreadyInUseException with existing email', () async {
        const email = 'test@example.com'; // Already exists in test users
        const password = 'password123';

        expect(
          () => repository.createUserWithEmailAndPassword(email, password),
          throwsA(isA<EmailAlreadyInUseException>()),
        );
      });

      test('should throw InvalidCredentialsException with invalid email format', () async {
        const email = 'invalid-email';
        const password = 'password123';

        expect(
          () => repository.createUserWithEmailAndPassword(email, password),
          throwsA(isA<InvalidCredentialsException>()),
        );
      });
    });    group
('signOut', () {
      test('should sign out successfully when user is signed in', () async {
        // Sign in first
        await repository.signInWithEmailAndPassword('test@example.com', 'password');
        expect(repository.currentUser, isNotNull);

        // Sign out
        await repository.signOut();
        expect(repository.currentUser, isNull);
      });

      test('should work even when no user is signed in', () async {
        expect(repository.currentUser, isNull);

        // Should not throw
        await repository.signOut();
        expect(repository.currentUser, isNull);
      });
    });

    group('error simulation methods', () {
      test('simulateNetworkError should throw NetworkException', () async {
        expect(
          () => repository.simulateNetworkError(),
          throwsA(isA<NetworkException>()),
        );
      });

      test('simulateServiceUnavailable should throw ServiceUnavailableException', () async {
        expect(
          () => repository.simulateServiceUnavailable(),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });
    });
  });
}
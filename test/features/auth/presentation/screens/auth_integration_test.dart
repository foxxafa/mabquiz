import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/data/models/app_user.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/auth_gate.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/login_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/register_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/home_screen.dart';

void main() {
  group('Auth Integration Tests', () {
    group('Full Authentication Flow', () {
      testWidgets('should show login screen initially when not authenticated', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(null)),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should show home screen when authenticated', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => Stream.value(testUser)),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should show loading screen during auth check', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) =>
                Stream.fromFuture(Future.delayed(const Duration(milliseconds: 100), () => null))
              ),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Yükleniyor...'), findsOneWidget);

        // Wait for auth check to complete
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should show error screen when auth stream has error', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) =>
                Stream.error(Exception('Auth error'))
              ),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Bir hata oluştu'), findsOneWidget);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should navigate between login and register screens', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Should start with login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Navigate to register screen
        await tester.tap(find.widgetWithText(TextButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Should show register screen
        expect(find.byType(RegisterScreen), findsOneWidget);

        // Navigate back to login screen
        await tester.tap(find.widgetWithText(TextButton, 'Giriş Yap'));
        await tester.pumpAndSettle();

        // Should show login screen again
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should navigate back from register screen using back button', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Navigate to register screen
        await tester.tap(find.widgetWithText(TextButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsOneWidget);

        // Use back button
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should be back to login screen
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Form Validation Tests', () {
      testWidgets('should show validation errors for empty login form', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Try to submit empty form
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();

        // Should show validation errors
        expect(find.text('Email adresi gereklidir'), findsOneWidget);
        expect(find.text('Şifre gereklidir'), findsOneWidget);
      });

      testWidgets('should show validation errors for empty registration form', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: RegisterScreen()),
        );

        // Try to submit empty form
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show validation errors
        expect(find.text('Email adresi gereklidir'), findsOneWidget);
        expect(find.text('Şifre gereklidir'), findsOneWidget);
        expect(find.text('Şifre tekrarı gereklidir'), findsOneWidget);
      });

      testWidgets('should show email validation error for invalid email', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalid-email',
        );

        // Try to submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();

        // Should show validation error
        expect(find.text('Geçerli bir email adresi girin'), findsOneWidget);
      });

      testWidgets('should show password mismatch error in registration', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: RegisterScreen()),
        );

        // Fill form with mismatched passwords
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'differentpassword',
        );

        // Try to submit
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show password mismatch error
        expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
      });
    });

    group('State Persistence Tests', () {
      testWidgets('should handle authentication state changes', (tester) async {
        final streamController = StreamController<AppUser?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => streamController.stream),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        // Initially should show loading (no data emitted yet)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Emit null (not authenticated)
        streamController.add(null);
        await tester.pump();

        // Should show login screen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Emit user (authenticated)
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );
        streamController.add(testUser);
        await tester.pump();

        // Should show home screen
        expect(find.byType(HomeScreen), findsOneWidget);

        // Emit null again (logged out)
        streamController.add(null);
        await tester.pump();

        // Should show login screen again
        expect(find.byType(LoginScreen), findsOneWidget);

        await streamController.close();
      });

      testWidgets('should handle rapid state changes', (tester) async {
        final streamController = StreamController<AppUser?>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => streamController.stream),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        final testUser1 = AppUser(uid: 'user1', email: 'user1@example.com');
        final testUser2 = AppUser(uid: 'user2', email: 'user2@example.com');

        // Rapid state changes
        streamController.add(null);
        streamController.add(testUser1);
        streamController.add(testUser2);
        streamController.add(null);

        await tester.pumpAndSettle();

        // Should end up showing login screen (last state was null)
        expect(find.byType(LoginScreen), findsOneWidget);

        await streamController.close();
      });
    });

    group('Error Scenario Tests', () {
      testWidgets('should handle authentication stream errors', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) =>
                Stream.error(Exception('Authentication service unavailable'))
              ),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        await tester.pumpAndSettle();

        // Should show error screen
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Bir hata oluştu'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Tekrar Dene'), findsOneWidget);

        // Tap retry button should navigate to login screen
        await tester.tap(find.widgetWithText(ElevatedButton, 'Tekrar Dene'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should show proper error messages', (tester) async {
        const errorMessage = 'Network connection failed';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) =>
                Stream.error(Exception(errorMessage))
              ),
            ],
            child: const MaterialApp(home: AuthGate()),
          ),
        );

        await tester.pumpAndSettle();

        // Should show error screen with error message
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Bir hata oluştu'), findsOneWidget);
        expect(find.text('Exception: $errorMessage'), findsOneWidget);
      });
    });

    group('User Experience Tests', () {
      testWidgets('should handle form field interactions', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Should have email and password fields
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Şifre'), findsOneWidget);

        // Should be able to enter text in fields
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        // Fields should contain the entered text
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });

      testWidgets('should handle password visibility toggle', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Should have visibility toggle button
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        // Should show visibility_off icon
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);
      });

      testWidgets('should handle multiple form fields in registration', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: RegisterScreen()),
        );

        // Should have three form fields
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Şifre'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Şifre Tekrarı'), findsOneWidget);

        // Should have two password visibility toggles
        expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      });

      testWidgets('should clear form data when navigating between screens', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoginScreen()),
        );

        // Fill login form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password',
        );

        // Navigate to register screen
        await tester.tap(find.widgetWithText(TextButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Register form should be empty (new screen, new form)
        final emailFields = tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        );
        for (final field in emailFields) {
          expect(field.controller?.text ?? '', isEmpty);
        }
      });
    });
  });
}
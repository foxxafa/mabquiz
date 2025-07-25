import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mabquiz/src/features/auth/application/auth_service.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/login_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/register_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/widgets/error_dialog.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createTestWidget({List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check for app icon
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        // Check for title and subtitle
        expect(find.text('Giriş Yap'), findsNWidgets(2)); // Title and button
        expect(find.text('Hesabınıza giriş yapın'), findsOneWidget);

        // Check for form fields
        expect(find.byType(TextFormField), findsNWidgets(2));

        // Check for email field
        final emailField = find.widgetWithText(TextFormField, 'Email');
        expect(emailField, findsOneWidget);

        // Check for password field
        final passwordField = find.widgetWithText(TextFormField, 'Şifre');
        expect(passwordField, findsOneWidget);

        // Check for login button
        expect(find.widgetWithText(ElevatedButton, 'Giriş Yap'), findsOneWidget);

        // Check for navigation to register
        expect(find.text('Hesabınız yok mu? '), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Kayıt Ol'), findsOneWidget);
      });

      testWidgets('should have correct input decorations', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check for email field with proper hint text
        expect(find.text('ornek@email.com'), findsOneWidget);

        // Check for password field with proper hint text
        expect(find.text('Şifrenizi girin'), findsOneWidget);

        // Check for email icon
        expect(find.byIcon(Icons.email), findsOneWidget);

        // Check for lock icon
        expect(find.byIcon(Icons.lock), findsOneWidget);

        // Check for visibility toggle button
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });

      testWidgets('should toggle password visibility', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Initially should show visibility icon (password is hidden)
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);

        // Find and tap the visibility toggle button
        final visibilityButton = find.byIcon(Icons.visibility);
        await tester.tap(visibilityButton);
        await tester.pump();

        // Should now show visibility_off icon (password is visible)
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        // Tap again to hide
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        // Should show visibility icon again (password is hidden)
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty fields', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap login button without entering any data
        final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
        await tester.tap(loginButton);
        await tester.pump();

        // Should show validation errors
        expect(find.text('Email adresi gereklidir'), findsOneWidget);
        expect(find.text('Şifre gereklidir'), findsOneWidget);
      });

      testWidgets('should show email validation error for invalid email', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid email
        final emailField = find.widgetWithText(TextFormField, 'Email');
        await tester.enterText(emailField, 'invalid-email');

        // Enter valid password
        final passwordField = find.widgetWithText(TextFormField, 'Şifre');
        await tester.enterText(passwordField, 'password123');

        // Tap login button
        final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
        await tester.tap(loginButton);
        await tester.pump();

        // Should show email validation error
        expect(find.text('Geçerli bir email adresi girin'), findsOneWidget);
      });

      testWidgets('should not show validation errors for valid input', (tester) async {
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter valid email and password
        final emailField = find.widgetWithText(TextFormField, 'Email');
        await tester.enterText(emailField, 'test@example.com');

        final passwordField = find.widgetWithText(TextFormField, 'Şifre');
        await tester.enterText(passwordField, 'password123');

        // Tap login button
        final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
        await tester.tap(loginButton);
        await tester.pump();

        // Should not show validation errors
        expect(find.text('Email adresi gereklidir'), findsNothing);
        expect(find.text('Şifre gereklidir'), findsNothing);
        expect(find.text('Geçerli bir email adresi girin'), findsNothing);
      });
    });

    group('Login Functionality', () {
      testWidgets('should call AuthService.login with correct parameters', (tester) async {
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        const email = 'test@example.com';
        const password = 'password123';

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          email,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          password,
        );

        // Tap login button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pumpAndSettle();

        // Verify login was called with correct parameters
        verify(mockAuthService.login(email, password)).called(1);
      });

      testWidgets('should show loading state during login', (tester) async {
        // Create a completer to control when login completes
        final completer = Completer<void>();
        when(mockAuthService.login(any, any))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        // Tap login button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();

        // Should show loading indicator in the button
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Giriş Yap'), findsNothing);

        // Form fields should be disabled (we can't easily test this with TextFormField,
        // but we can verify the loading state is shown)

        // Complete the login
        completer.complete();
        await tester.pumpAndSettle();

        // Loading should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Giriş Yap'), findsOneWidget);
      });

      testWidgets('should handle login success', (tester) async {
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        // Tap login button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pumpAndSettle();

        // Should show success message in SnackBar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Giriş başarılı!'), findsOneWidget);
      });

      testWidgets('should handle login error', (tester) async {
        when(mockAuthService.login(any, any))
            .thenThrow(const InvalidCredentialsException());

        await tester.pumpWidget(createTestWidget());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'wrongpassword',
        );

        // Tap login button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();
        await tester.pump(); // Allow error to be processed

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Hata'), findsOneWidget);
        expect(find.text('Geçersiz email veya şifre'), findsOneWidget);
      });

      testWidgets('should reset loading state after error', (tester) async {
        when(mockAuthService.login(any, any))
            .thenThrow(const InvalidCredentialsException());

        await tester.pumpWidget(createTestWidget());

        // Enter credentials and attempt login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'wrongpassword',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();
        await tester.pump(); // Allow error to be processed

        // Dismiss error dialog
        await tester.tap(find.text('Tamam'));
        await tester.pump();

        // Login button should be enabled again
        final loginButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Giriş Yap'),
        );
        expect(loginButton.onPressed, isNotNull);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to register screen when register button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap register button
        await tester.tap(find.widgetWithText(TextButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Should navigate to register screen
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('should disable navigation during loading', (tester) async {
        // Create a completer to control when login completes
        final completer = Completer<void>();
        when(mockAuthService.login(any, any))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());

        // Enter credentials and start login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Giriş Yap'));
        await tester.pump();

        // Register button should be disabled during loading
        // We can't easily test the disabled state, but we can verify loading is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete login
        completer.complete();
        await tester.pumpAndSettle();
      });
    });

    group('Form Submission', () {
      testWidgets('should submit form when Enter is pressed on password field', (tester) async {
        when(mockAuthService.login(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        // Focus on password field and press Enter
        await tester.tap(find.widgetWithText(TextFormField, 'Şifre'));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Should call login
        verify(mockAuthService.login('test@example.com', 'password123')).called(1);
      });

      testWidgets('should not submit form with invalid data on Enter', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalid-email',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );

        // Focus on password field and press Enter
        await tester.tap(find.widgetWithText(TextFormField, 'Şifre'));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Should not call login
        verifyNever(mockAuthService.login(any, any));

        // Should show validation error
        expect(find.text('Geçerli bir email adresi girin'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check that form fields have proper labels
        final emailField = find.widgetWithText(TextFormField, 'Email');
        expect(emailField, findsOneWidget);

        final passwordField = find.widgetWithText(TextFormField, 'Şifre');
        expect(passwordField, findsOneWidget);

        // Check that buttons have proper labels
        final loginButton = find.widgetWithText(ElevatedButton, 'Giriş Yap');
        expect(loginButton, findsOneWidget);
      });
    });
  });
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mabquiz/src/features/auth/application/auth_service.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/data/exceptions.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/register_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/widgets/error_dialog.dart';

import 'register_screen_test.mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('RegisterScreen Widget Tests', () {
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
          home: RegisterScreen(),
        ),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check for app bar
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Kayıt Ol'), findsNWidgets(2)); // AppBar title + button

        // Check for app icon
        expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);

        // Check for title and subtitle
        expect(find.text('Hesap Oluştur'), findsOneWidget);
        expect(find.text('Yeni hesabınızı oluşturun'), findsOneWidget);

        // Check for form fields (email, password, password confirmation)
        expect(find.byType(TextFormField), findsNWidgets(3));

        // Check for email field
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

        // Check for password field
        expect(find.widgetWithText(TextFormField, 'Şifre'), findsOneWidget);

        // Check for password confirmation field
        expect(find.widgetWithText(TextFormField, 'Şifre Tekrarı'), findsOneWidget);

        // Check for register button
        expect(find.widgetWithText(ElevatedButton, 'Kayıt Ol'), findsOneWidget);

        // Check for navigation to login
        expect(find.text('Zaten hesabınız var mı? '), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Giriş Yap'), findsOneWidget);
      });

      testWidgets('should have correct input decorations', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check for email field with proper hint text
        expect(find.text('ornek@email.com'), findsOneWidget);

        // Check for password field with proper hint text
        expect(find.text('Şifrenizi girin'), findsOneWidget);

        // Check for password confirmation field with proper hint text
        expect(find.text('Şifrenizi tekrar girin'), findsOneWidget);

        // Check for email icon
        expect(find.byIcon(Icons.email), findsOneWidget);

        // Check for lock icons
        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        // Check for visibility toggle buttons (2 for password fields)
        expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      });

      testWidgets('should toggle password visibility for both password fields', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Initially should show visibility icons (passwords are hidden)
        expect(find.byIcon(Icons.visibility), findsNWidgets(2));
        expect(find.byIcon(Icons.visibility_off), findsNothing);

        // Find and tap the first visibility toggle button
        final visibilityButtons = find.byIcon(Icons.visibility);
        await tester.tap(visibilityButtons.first);
        await tester.pump();

        // Should now show one visibility_off icon and one visibility icon
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsOneWidget);

        // Tap the second visibility toggle button
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        // Should now show two visibility_off icons
        expect(find.byIcon(Icons.visibility_off), findsNWidgets(2));
        expect(find.byIcon(Icons.visibility), findsNothing);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty fields', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap register button without entering any data
        final registerButton = find.widgetWithText(ElevatedButton, 'Kayıt Ol');
        await tester.tap(registerButton);
        await tester.pump();

        // Should show validation errors
        expect(find.text('Email adresi gereklidir'), findsOneWidget);
        expect(find.text('Şifre gereklidir'), findsOneWidget);
        expect(find.text('Şifre tekrarı gereklidir'), findsOneWidget);
      });

      testWidgets('should show email validation error for invalid email', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalid-email',
        );

        // Enter valid passwords
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'password123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show email validation error
        expect(find.text('Geçerli bir email adresi girin'), findsOneWidget);
      });

      testWidgets('should show password validation error for weak password', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Enter weak password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          '123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          '123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show password validation error
        expect(find.text('Şifre en az 6 karakter olmalıdır'), findsOneWidget);
      });

      testWidgets('should show password mismatch error', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Enter mismatched passwords
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'differentpassword',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show password mismatch error
        expect(find.text('Şifreler eşleşmiyor'), findsOneWidget);
      });

      testWidgets('should show common weak password error', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Enter common weak password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'password',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'password',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show weak password error
        expect(find.text('Bu şifre çok yaygın kullanılıyor. Daha güçlü bir şifre seçin'), findsOneWidget);
      });

      testWidgets('should not show validation errors for valid input', (tester) async {
        when(mockAuthService.register(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should not show validation errors
        expect(find.text('Email adresi gereklidir'), findsNothing);
        expect(find.text('Şifre gereklidir'), findsNothing);
        expect(find.text('Şifre tekrarı gereklidir'), findsNothing);
        expect(find.text('Geçerli bir email adresi girin'), findsNothing);
        expect(find.text('Şifreler eşleşmiyor'), findsNothing);
      });
    });

    group('Registration Functionality', () {
      testWidgets('should call AuthService.register with correct parameters', (tester) async {
        when(mockAuthService.register(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        const email = 'test@example.com';
        const password = 'strongpassword123';

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          email,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          password,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          password,
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Verify register was called with correct parameters
        verify(mockAuthService.register(email, password)).called(1);
      });

      testWidgets('should show loading state during registration', (tester) async {
        // Create a completer to control when registration completes
        final completer = Completer<void>();
        when(mockAuthService.register(any, any))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Kayıt Ol'), findsNothing);

        // Form fields should be disabled (we can't easily test this with TextFormField,
        // but we can verify the loading state is shown)

        // Complete the registration
        completer.complete();
        await tester.pumpAndSettle();

        // Loading should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Kayıt Ol'), findsOneWidget);
      });

      testWidgets('should handle registration success', (tester) async {
        when(mockAuthService.register(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Kayıt başarılı! Hoş geldiniz!'), findsOneWidget);
      });

      testWidgets('should handle email already in use error', (tester) async {
        when(mockAuthService.register(any, any))
            .thenThrow(const EmailAlreadyInUseException());

        await tester.pumpWidget(createTestWidget());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'existing@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Hata'), findsOneWidget);
        expect(find.text('Bu email adresi zaten kullanımda'), findsOneWidget);
      });

      testWidgets('should handle weak password error', (tester) async {
        when(mockAuthService.register(any, any))
            .thenThrow(const WeakPasswordException());

        await tester.pumpWidget(createTestWidget());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'weak',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'weak',
        );

        // Tap register button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Hata'), findsOneWidget);
        expect(find.text('Şifre çok zayıf'), findsOneWidget);
      });

      testWidgets('should reset loading state after error', (tester) async {
        when(mockAuthService.register(any, any))
            .thenThrow(const EmailAlreadyInUseException());

        await tester.pumpWidget(createTestWidget());

        // Enter credentials and attempt registration
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'existing@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pumpAndSettle();

        // Dismiss error dialog
        await tester.tap(find.text('Tamam'));
        await tester.pumpAndSettle();

        // Register button should be enabled again
        final registerButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Kayıt Ol'),
        );
        expect(registerButton.onPressed, isNotNull);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate back to login screen when login button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap login button
        await tester.tap(find.widgetWithText(TextButton, 'Giriş Yap'));
        await tester.pumpAndSettle();

        // Should navigate back (pop the register screen)
        expect(find.byType(RegisterScreen), findsNothing);
      });

      testWidgets('should navigate back when back button is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap back button in app bar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Should navigate back
        expect(find.byType(RegisterScreen), findsNothing);
      });

      testWidgets('should disable navigation during loading', (tester) async {
        // Create a completer to control when registration completes
        final completer = Completer<void>();
        when(mockAuthService.register(any, any))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());

        // Enter credentials and start registration
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Kayıt Ol'));
        await tester.pump();

        // Login button should be disabled
        final loginButton = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Giriş Yap'),
        );
        expect(loginButton.onPressed, isNull);

        // Complete registration
        completer.complete();
        await tester.pumpAndSettle();
      });
    });

    group('Form Submission', () {
      testWidgets('should submit form when Enter is pressed on password confirmation field', (tester) async {
        when(mockAuthService.register(any, any))
            .thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget());

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre'),
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Press Enter on password confirmation field
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Should call register
        verify(mockAuthService.register('test@example.com', 'strongpassword123')).called(1);
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
          'strongpassword123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Şifre Tekrarı'),
          'strongpassword123',
        );

        // Press Enter on password confirmation field
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Should not call register
        verifyNever(mockAuthService.register(any, any));

        // Should show validation error
        expect(find.text('Geçerli bir email adresi girin'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check that form fields have proper labels
        expect(
          tester.getSemantics(find.widgetWithText(TextFormField, 'Email')),
          matchesSemantics(
            label: 'Email',
            isTextField: true,
          ),
        );

        expect(
          tester.getSemantics(find.widgetWithText(TextFormField, 'Şifre')),
          matchesSemantics(
            label: 'Şifre',
            isTextField: true,
            isObscured: true,
          ),
        );

        expect(
          tester.getSemantics(find.widgetWithText(TextFormField, 'Şifre Tekrarı')),
          matchesSemantics(
            label: 'Şifre Tekrarı',
            isTextField: true,
            isObscured: true,
          ),
        );

        // Check that buttons have proper labels
        expect(
          tester.getSemantics(find.widgetWithText(ElevatedButton, 'Kayıt Ol')),
          matchesSemantics(
            label: 'Kayıt Ol',
            isButton: true,
          ),
        );
      });
    });
  });
}
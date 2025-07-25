import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/data/models/app_user.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/auth_gate.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/login_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/home_screen.dart';

void main() {
  group('AuthGate Widget Tests', () {
    Widget createTestWidget({
      required AsyncValue<AppUser?> authState,
    }) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) {
            return Stream.value(authState.value).asyncMap((value) {
              if (authState.hasError) {
                throw authState.error!;
              }
              return value;
            });
          }),
        ],
        child: const MaterialApp(
          home: AuthGate(),
        ),
      );
    }

    Widget createTestWidgetWithStream({
      required Stream<AppUser?> authStream,
    }) {
      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => authStream),
        ],
        child: const MaterialApp(
          home: AuthGate(),
        ),
      );
    }

    group('Authentication State Routing', () {
      testWidgets('should show LoginScreen when user is not authenticated', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: const AsyncValue.data(null),
          ),
        );

        // Should display LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should show HomeScreen when user is authenticated', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            authState: AsyncValue.data(testUser),
          ),
        );

        // Should display HomeScreen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should show loading screen when auth state is loading', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 100), () => null),
            ),
          ),
        );

        // Should display loading screen
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Yükleniyor...'), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);
      });

      testWidgets('should show error screen when auth state has error', (tester) async {
        final testError = Exception('Authentication error');

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.error(testError),
          ),
        );

        // Wait for error to be processed
        await tester.pumpAndSettle();

        // Should display error screen
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Bir hata oluştu'), findsOneWidget);
        expect(find.text('Exception: Authentication error'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Tekrar Dene'), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(HomeScreen), findsNothing);
      });
    });

    group('Loading Screen', () {
      testWidgets('should display loading indicator and text', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 100), () => null),
            ),
          ),
        );

        // Check loading screen elements
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Yükleniyor...'), findsOneWidget);

        // Check that it's properly centered
        final scaffold = find.byType(Scaffold);
        expect(scaffold, findsOneWidget);

        final center = find.descendant(
          of: scaffold,
          matching: find.byType(Center),
        );
        expect(center, findsOneWidget);

        final column = find.descendant(
          of: center,
          matching: find.byType(Column),
        );
        expect(column, findsOneWidget);

        // Verify column properties
        final columnWidget = tester.widget<Column>(column);
        expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
      });

      testWidgets('should transition from loading to login screen', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 50), () => null),
            ),
          ),
        );

        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Yükleniyor...'), findsOneWidget);

        // Wait for stream to complete
        await tester.pumpAndSettle();

        // Should now show login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Yükleniyor...'), findsNothing);
      });

      testWidgets('should transition from loading to home screen', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 50), () => testUser),
            ),
          ),
        );

        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Yükleniyor...'), findsOneWidget);

        // Wait for stream to complete
        await tester.pumpAndSettle();

        // Should now show home screen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Yükleniyor...'), findsNothing);
      });
    });

    group('Error Screen', () {
      testWidgets('should display error information correctly', (tester) async {
        final testError = Exception('Network connection failed');

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.error(testError),
          ),
        );

        await tester.pumpAndSettle();

        // Check error screen elements
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Bir hata oluştu'), findsOneWidget);
        expect(find.text('Exception: Network connection failed'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Tekrar Dene'), findsOneWidget);

        // Check icon properties
        final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(errorIcon.size, 64);
        expect(errorIcon.color, Colors.red);

        // Check title style
        final titleText = tester.widget<Text>(find.text('Bir hata oluştu'));
        expect(titleText.style?.fontSize, 20);
        expect(titleText.style?.fontWeight, FontWeight.bold);

        // Check error message style
        final errorText = tester.widget<Text>(find.text('Exception: Network connection failed'));
        expect(errorText.style?.fontSize, 14);
        expect(errorText.textAlign, TextAlign.center);
      });

      testWidgets('should handle different error types', (tester) async {
        final errors = [
          'Simple string error',
          Exception('Exception error'),
          StateError('State error'),
          ArgumentError('Argument error'),
        ];

        for (final error in errors) {
          await tester.pumpWidget(
            createTestWidgetWithStream(
              authStream: Stream.error(error),
            ),
          );

          await tester.pumpAndSettle();

          // Should display error screen with error message
          expect(find.byIcon(Icons.error_outline), findsOneWidget);
          expect(find.text('Bir hata oluştu'), findsOneWidget);
          expect(find.text(error.toString()), findsOneWidget);
          expect(find.widgetWithText(ElevatedButton, 'Tekrar Dene'), findsOneWidget);
        }
      });

      testWidgets('should navigate to login screen when retry button is tapped', (tester) async {
        final testError = Exception('Test error');

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.error(testError),
          ),
        );

        await tester.pumpAndSettle();

        // Tap retry button
        await tester.tap(find.widgetWithText(ElevatedButton, 'Tekrar Dene'));
        await tester.pumpAndSettle();

        // Should navigate to login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('State Transitions', () {
      testWidgets('should handle authentication state changes', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        // Create a stream controller to control state changes
        final streamController = StreamController<AppUser?>();

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: streamController.stream,
          ),
        );

        // Initially should show loading (no data emitted yet)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Emit null (not authenticated)
        streamController.add(null);
        await tester.pump();

        // Should show login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Emit user (authenticated)
        streamController.add(testUser);
        await tester.pump();

        // Should show home screen
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Emit null again (logged out)
        streamController.add(null);
        await tester.pump();

        // Should show login screen again
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await streamController.close();
      });

      testWidgets('should handle rapid state changes', (tester) async {
        final testUser1 = AppUser(
          uid: 'user1',
          email: 'user1@example.com',
          emailVerified: true,
        );
        final testUser2 = AppUser(
          uid: 'user2',
          email: 'user2@example.com',
          emailVerified: true,
        );

        final streamController = StreamController<AppUser?>();

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: streamController.stream,
          ),
        );

        // Rapid state changes
        streamController.add(null);
        streamController.add(testUser1);
        streamController.add(testUser2);
        streamController.add(null);

        await tester.pumpAndSettle();

        // Should end up showing login screen (last state was null)
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(HomeScreen), findsNothing);

        await streamController.close();
      });

      testWidgets('should handle error after successful authentication', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        final streamController = StreamController<AppUser?>();

        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: streamController.stream,
          ),
        );

        // Start with authenticated user
        streamController.add(testUser);
        await tester.pump();

        // Should show home screen
        expect(find.byType(HomeScreen), findsOneWidget);

        // Add error to stream
        streamController.addError(Exception('Connection lost'));
        await tester.pumpAndSettle();

        // Should show error screen
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Exception: Connection lost'), findsOneWidget);

        await streamController.close();
      });
    });

    group('Widget Structure', () {
      testWidgets('should have proper widget hierarchy for login state', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            authState: const AsyncValue.data(null),
          ),
        );

        // Check widget hierarchy
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(ProviderScope), findsOneWidget);
        expect(find.byType(AuthGate), findsOneWidget);
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should have proper widget hierarchy for authenticated state', (tester) async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          emailVerified: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            authState: AsyncValue.data(testUser),
          ),
        );

        // Check widget hierarchy
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(ProviderScope), findsOneWidget);
        expect(find.byType(AuthGate), findsOneWidget);
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('should have proper widget hierarchy for loading state', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 100), () => null),
            ),
          ),
        );

        // Check widget hierarchy for loading screen
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(ProviderScope), findsOneWidget);
        expect(find.byType(AuthGate), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should have proper widget hierarchy for error state', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.error(Exception('Test error')),
          ),
        );

        await tester.pumpAndSettle();

        // Check widget hierarchy for error screen
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(ProviderScope), findsOneWidget);
        expect(find.byType(AuthGate), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(Padding), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for loading screen', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.fromFuture(
              Future.delayed(const Duration(milliseconds: 100), () => null),
            ),
          ),
        );

        // Check loading screen semantics
        expect(
          tester.getSemantics(find.text('Yükleniyor...')),
          matchesSemantics(
            label: 'Yükleniyor...',
          ),
        );
      });

      testWidgets('should have proper semantics for error screen', (tester) async {
        await tester.pumpWidget(
          createTestWidgetWithStream(
            authStream: Stream.error(Exception('Test error')),
          ),
        );

        await tester.pumpAndSettle();

        // Check error screen semantics
        expect(
          tester.getSemantics(find.text('Bir hata oluştu')),
          matchesSemantics(
            label: 'Bir hata oluştu',
          ),
        );

        expect(
          tester.getSemantics(find.widgetWithText(ElevatedButton, 'Tekrar Dene')),
          matchesSemantics(
            label: 'Tekrar Dene',
            isButton: true,
          ),
        );
      });
    });
  });
}
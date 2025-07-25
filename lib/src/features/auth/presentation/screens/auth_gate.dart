import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mabquiz/src/features/quiz/presentation/screens/subject_selection_screen.dart';

import '../../application/providers.dart';
import 'login_screen.dart';

/// AuthGate widget that handles authentication state routing
///
/// This widget listens to the authentication state and routes users
/// to the appropriate screen based on their authentication status:
/// - If user is authenticated: shows SubjectSelectionScreen
/// - If user is not authenticated: shows LoginScreen
/// - While loading: shows loading indicator
/// - On error: shows error screen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // If user is authenticated, show home screen
        if (user != null) {
          return const SubjectSelectionScreen();
        }
        // If user is not authenticated, show login screen
        return const LoginScreen();
      },
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) => _ErrorScreen(error: error),
    );
  }
}

/// Loading screen shown while authentication state is being determined
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Yükleniyor...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication state cannot be determined
class _ErrorScreen extends StatelessWidget {
  final Object error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bir hata oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app or navigate to a safe state
                  // For now, we'll just show the login screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
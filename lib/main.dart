import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/config/config.dart';
import 'src/core/theme/theme.dart';
import 'src/features/auth/presentation/screens/auth_gate.dart';
import 'src/features/quiz/data/services/firebase_quiz_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize application configuration
  final config = AppConfig.auto();
  print('=== Application Configuration ===');
  print('Environment: ${config.environment.name}');
  print('Use Mock Auth: ${config.auth.useMockAuth}');
  print('Firebase Enabled: ${config.firebase.enabled}');
  print('================================');

  try {
    // Initialize Firebase with environment-specific configuration
    await FirebaseConfigService.initialize(config);
    print('✓ Firebase Core initialized successfully');

    // Initialize Firebase Quiz features only if Firebase is enabled
    if (config.firebase.enabled && !config.auth.useMockAuth) {
      await FirebaseQuizConfigService.instance.initialize(config);
      print('✓ Firebase Quiz service initialized successfully');
    } else {
      print('ℹ Using mock data for quiz features (Firebase disabled or mock mode)');
    }
  } catch (e) {
    print('⚠ Warning: Firebase initialization failed: $e');
    print('ℹ App will continue with mock data');
    // App can continue with mock data if Firebase fails
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAB Quiz',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}



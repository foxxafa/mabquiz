import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/config/config.dart';
import 'src/core/theme/theme.dart';
import 'src/features/auth/presentation/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize application configuration
  final config = AppConfig.auto();

  // Initialize Firebase with environment-specific configuration
  await FirebaseConfigService.initialize(config);

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



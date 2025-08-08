import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/auth_gate.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/login_screen.dart';
import 'package:mabquiz/src/features/auth/presentation/screens/register_screen.dart';
import 'package:mabquiz/src/features/quiz/presentation/screens/quiz_screen.dart';
import 'package:mabquiz/src/features/quiz/presentation/screens/subject_selection_screen.dart';
import 'package:mabquiz/src/features/home/presentation/screens/home_screen.dart';
import 'package:mabquiz/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:mabquiz/src/features/analysis/presentation/screens/analysis_screen.dart';
import 'package:mabquiz/src/features/shell/presentation/screens/main_shell.dart';

// Navigator key'leri, yönlendirme (routing) durumunu yönetmek için kullanılır.
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter provider'ı, uygulamanın tüm yönlendirme mantığını içerir.
final appRouterProvider = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/auth', // Uygulama başlangıç yolu
  routes: [
    // AuthGate, kullanıcının giriş yapıp yapmadığını kontrol eder ve yönlendirir.
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthGate(),
    ),
    // Giriş ekranı
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Kayıt ekranı
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // ShellRoute, alt navigasyon çubuğu (BottomNavigationBar) olan ana ekranları sarmalar.
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        // MainShell, alt navigasyon çubuğunu ve içeriği gösteren ana yapıdır.
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/subjects',
          builder: (context, state) => const SubjectSelectionScreen(),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) => const AnalysisScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    // Quiz ekranı, ders (subject) parametresi ile açılır.
    GoRoute(
      path: '/quiz/:subject',
      builder: (context, state) {
        final subject = state.pathParameters['subject']!;
        return QuizScreen(subject: subject);
      },
    ),
  ],
);

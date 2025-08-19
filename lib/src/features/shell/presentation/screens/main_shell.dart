import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mabquiz/src/features/shell/presentation/widgets/bottom_nav_bar.dart';

/// MainShell, uygulamanın alt navigasyon çubuğunu içeren ana çerçevesidir.
/// GoRouter'daki ShellRoute tarafından kullanılır.
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child, // Gelen sayfa içeriği burada gösterilir
      bottomNavigationBar: BottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  /// Mevcut URL'ye göre hangi navigasyon sekmesinin aktif olduğunu hesaplar.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/subjects')) {
      return 1;
    }
    if (location.startsWith('/analysis')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    return 0; // Varsayılan olarak ana sayfa
  }

  /// Navigasyon çubuğundaki bir öğeye tıklandığında ilgili sayfaya yönlendirir.
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/subjects');
        break;
      case 2:
        GoRouter.of(context).go('/analysis');
        break;
      case 3:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}

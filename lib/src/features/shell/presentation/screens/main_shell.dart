import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mabquiz/src/features/shell/presentation/widgets/bottom_nav_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

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
    return 0;
  }

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

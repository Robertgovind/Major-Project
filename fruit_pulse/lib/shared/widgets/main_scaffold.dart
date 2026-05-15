import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final showBottomNavigation = !location.startsWith('/analysis');

    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNavigation
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'News & History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
              currentIndex: _getCurrentIndex(context),
              onTap: (index) => _onItemTapped(context, index),
            )
          : null,
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/fruit-selection')) {
      return 0;
    } else if (location.startsWith('/analytics')) {
      return 1;
    } else if (location.startsWith('/settings')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/fruit-selection');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}

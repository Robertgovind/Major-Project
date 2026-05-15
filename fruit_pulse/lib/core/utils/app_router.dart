import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/fruit_selection/presentation/fruit_selection_screen.dart';
import '../../features/fruit_analysis/presentation/fruit_analysis_screen.dart';
import '../../features/analytics/presentation/news_and_history_screen.dart';
import '../../features/analytics/presentation/news_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/fruit-selection',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/fruit-selection',
            builder: (context, state) => const FruitSelectionScreen(),
          ),
          GoRoute(
            path: '/analysis',
            builder: (context, state) {
              final fruitId = state.uri.queryParameters['fruitId'] ?? '';
              return FruitAnalysisScreen(fruitId: fruitId);
            },
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) {
          final articleId = state.pathParameters['id'] ?? '';
          return NewsDetailScreen(articleId: articleId);
        },
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Placeholder screens until FM04–FM05 fill them in.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const _PlaceholderScreen('Splash'),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const _PlaceholderScreen('Login'),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (_, __) => const _PlaceholderScreen('Dashboard'),
      ),
    ],
    errorBuilder: (_, state) => _PlaceholderScreen('404 — ${state.error}'),
  );
});
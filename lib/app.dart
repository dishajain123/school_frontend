import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root application widget.
///
/// Watches [appRouterProvider] so the router refreshes whenever auth state
/// changes. The theme is applied globally from [AppTheme.light()].
class SmsApp extends ConsumerWidget {
  const SmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} — Smart School Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}

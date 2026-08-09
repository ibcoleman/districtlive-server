import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class DistrictLiveApp extends ConsumerWidget {
  const DistrictLiveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'District Live',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      // Material 3 is enabled in themes (useMaterial3: true)
      // Platform-specific behaviors are handled by Flutter defaults:
      // - iOS: SafeArea via Scaffold, BouncingScrollPhysics for scrollable content
      // - Android: SafeArea via Scaffold, ClampingScrollPhysics for scrollable content
      // - Predictive back gesture: part of Material 3 navigation defaults on Android 13+
    );
  }
}

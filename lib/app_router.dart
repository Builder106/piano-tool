import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/ingestion_repository.dart';
import '../ui/import/import_screen.dart';
import '../ui/import/review_screen.dart';
import '../ui/levels/level_list_screen.dart';
import '../ui/practice/practice_screen.dart';

/// GoRouter configuration for the app
final FutureProvider<GoRouter> appRouterProvider =
    FutureProvider<GoRouter>((final FutureProviderRef<GoRouter> ref) async {
  await ref.watch(ingestionRepositoryProvider.future);

  return GoRouter(
    initialLocation: '/',
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        name: 'levels',
        builder: (final BuildContext context, final GoRouterState state) =>
            const LevelListScreen(),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (final BuildContext context, final GoRouterState state) =>
            const ImportScreen(),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (final BuildContext context, final GoRouterState state) {
          final String? jobId = state.uri.queryParameters['jobId'];
          if (jobId == null) {
            return const Scaffold(body: Center(child: Text('Missing jobId')));
          }
          return ReviewScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/practice/:stageId',
        name: 'practice',
        builder: (final BuildContext context, final GoRouterState state) {
          final String stageId = state.pathParameters['stageId']!;
          return PracticeScreen(stageId: stageId);
        },
      ),
    ],
    errorBuilder: (final BuildContext context, final GoRouterState state) =>
        Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});

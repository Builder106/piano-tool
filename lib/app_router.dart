import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/ingestion_repository.dart';
import 'ui/import/import_screen.dart';
import 'ui/import/review_screen.dart';
import 'ui/levels/level_list_screen.dart';
import 'ui/practice/practice_screen.dart';
import 'ui/practice/stage_controller.dart';
import 'ui/results/results_screen.dart';

/// GoRouter configuration for the app
final appRouterProvider = FutureProvider<GoRouter>((ref) async {
  await ref.watch(ingestionRepositoryProvider.future);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'levels',
        builder: (context, state) => const LevelListScreen(),
      ),
      GoRoute(
        path: '/import',
        name: 'import',
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) {
          final jobId = state.uri.queryParameters['jobId'];
          if (jobId == null) {
            return const Scaffold(body: Center(child: Text('Missing jobId')));
          }
          return ReviewScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/practice/:stageId',
        name: 'practice',
        builder: (context, state) {
          final stageId = state.pathParameters['stageId']!;
          return PracticeScreen(stageId: stageId);
        },
      ),
      GoRoute(
        path: '/results/:stageId',
        name: 'results',
        builder: (context, state) {
          final result = state.extra;
          if (result is! StageResult ||
              result.stageId != state.pathParameters['stageId']) {
            return const Scaffold(
              body: Center(child: Text('Missing stage results')),
            );
          }

          return ResultsScreen(
            result: result,
            onReplay: () {
              ref
                  .read(stageControllerProvider(result.stageId).notifier)
                  .replay();
              context.goNamed(
                'practice',
                pathParameters: {'stageId': result.stageId},
              );
            },
            onReturnToLevels: () => context.goNamed('levels'),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri}'),
      ),
    ),
  );
});

import 'dart:convert';

import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_models.dart';
import 'level_repository.dart';

class StageAvailability {
  const StageAvailability({
    required this.stage,
    required this.progress,
    required this.unmetPrerequisites,
  });

  final StageModel stage;
  final StageProgress? progress;
  final List<String> unmetPrerequisites;

  bool get isUnlocked => unmetPrerequisites.isEmpty;
}

final stageProgressProvider =
    FutureProvider.autoDispose<Map<String, StageProgress>>((ref) {
      return ref.read(progressRepositoryProvider).readAll();
    });

final lastPlayedStageIdProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  return ref.watch(progressRepositoryProvider).lastPlayedStageId();
});

final stageAvailabilityProvider = FutureProvider.autoDispose
    .family<StageAvailability?, String>((ref, id) async {
      final repository = await ref.watch(levelRepositoryProvider.future);
      final stage = repository.getStage(id);
      if (stage == null) return null;
      final progress = await ref.watch(stageProgressProvider.future);
      final unmet = stage.prerequisites
          .where((requiredId) => progress[requiredId]?.completed != true)
          .toList(growable: false);
      return StageAvailability(
        stage: stage,
        progress: progress[id],
        unmetPrerequisites: unmet,
      );
    });

final isTargetTempoReadyProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, stageId) async {
      final progress = await ref.watch(stageProgressProvider.future);
      return progress[stageId]?.targetTempoReady ?? false;
    });

final stageHistoryProvider = FutureProvider.autoDispose
    .family<List<AttemptRecord>, String>((ref, stageId) async {
      return ref.watch(progressRepositoryProvider).getHistory(stageId);
    });

/// Per-stage bests, stored on device. No accounts and no network.
///
/// One key per stage rather than a single blob, so a corrupt entry costs one
/// stage's history instead of all of it.
class ProgressRepository {
  static const _prefix = 'progress.';
  static const _lastPlayedKey = 'progress.lastPlayed';

  /// Accuracy at or above this counts as clearing the stage.
  static const double completionThreshold = 0.9;

  /// Default capacity for bounded attempt history per exercise.
  static const int defaultMaxHistoryEntries = 50;

  Future<StageProgress?> read(String stageId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _decode(stageId, prefs.getString('$_prefix$stageId'));
  }

  Future<Map<String, StageProgress>> readAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, StageProgress> out = <String, StageProgress>{};
    for (final String key in prefs.getKeys()) {
      if (!key.startsWith(_prefix) || key == _lastPlayedKey) continue;
      final String id = key.substring(_prefix.length);
      final StageProgress? progress = _decode(id, prefs.getString(key));
      if (progress != null) out[id] = progress;
    }
    return out;
  }

  /// Records an attempt and updates stage progress.
  ///
  /// Distinguishes assisted completion from timed performance:
  /// - A high score earned slowly (speed < 1.0 or effective BPM below target)
  ///   or in waiting mode does not establish target tempo readiness.
  /// - Target tempo readiness requires unassisted timed mode at full target tempo
  ///   clearing the full exercise with passing accuracy (>= 90%).
  /// - Existing bests and completion status are strictly preserved.
  Future<void> record({
    required final String stageId,
    required final double accuracy,
    required final int score,
    final int totalNotes = 0,
    final int hitNotes = 0,
    final (int, int)? range,
    final HandSelection hand = HandSelection.both,
    final PracticeMode mode = PracticeMode.timed,
    final int? tempo,
    final int? targetTempo,
    final double speed = 1.0,
    final bool isAssisted = false,
    final DateTime? date,
    final int maxHistoryEntries = defaultMaxHistoryEntries,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final StageProgress? previous = _decode(
      stageId,
      prefs.getString('$_prefix$stageId'),
    );

    final now = date ?? DateTime.now();
    final isFullExercise = range == null;
    final isPassed = accuracy >= completionThreshold;
    final effectiveTempo =
        tempo ?? (targetTempo != null ? (targetTempo * speed).round() : 120);

    // Distinguish assisted completion from timed performance:
    // A run is slow if speed < 1.0 or effective BPM is below target BPM.
    final isSlow = targetTempo != null
        ? effectiveTempo < targetTempo
        : speed < 1.0;
    final isAssistedRun = isAssisted || isSlow || mode == PracticeMode.waiting;
    final isTimedPerformance =
        mode == PracticeMode.timed && !isSlow && !isAssisted;
    final isTargetTempoRun = !isSlow;

    final isAssistedCompletion = isFullExercise && isPassed && isAssistedRun;
    final isTimedTargetTempoCompletion =
        isFullExercise && isPassed && isTimedPerformance && isTargetTempoRun;

    final attempt = AttemptRecord(
      exercise: stageId,
      startMeasure: range?.$1,
      endMeasure: range?.$2,
      hand: hand,
      mode: mode,
      tempo: effectiveTempo,
      targetTempo: targetTempo,
      speed: speed,
      result: AttemptResult(
        accuracy: accuracy,
        score: score,
        totalNotes: totalNotes,
        hitNotes: hitNotes,
        missedNotes: (totalNotes - hitNotes).clamp(0, totalNotes),
        completed: isFullExercise && isPassed,
        passed: isPassed,
      ),
      date: now,
      isAssisted: isAssistedRun,
    );

    // Bounded history: append and clamp to maxHistoryEntries
    final existingHistory = previous?.history ?? const <AttemptRecord>[];
    final updatedHistory = [...existingHistory, attempt];
    final boundedHistory = updatedHistory.length > maxHistoryEntries
        ? updatedHistory.sublist(updatedHistory.length - maxHistoryEntries)
        : updatedHistory;

    // Bests only ever climb; a bad run still counts as an attempt, and
    // clearing a stage once is permanent.
    final next = StageProgress(
      stageId: stageId,
      bestAccuracy: accuracy > (previous?.bestAccuracy ?? 0)
          ? accuracy
          : (previous?.bestAccuracy ?? 0),
      bestScore: score > (previous?.bestScore ?? 0)
          ? score
          : (previous?.bestScore ?? 0),
      attempts: (previous?.attempts ?? 0) + 1,
      completed: (previous?.completed ?? false) || (isFullExercise && isPassed),
      unlocked: true,
      completedAt:
          previous?.completedAt ?? ((isFullExercise && isPassed) ? now : null),
      lastAttemptAt: now,
      // Target tempo readiness is strictly NOT established by slow or assisted runs
      targetTempoReady:
          (previous?.targetTempoReady ?? false) || isTimedTargetTempoCompletion,
      targetTempoReadyAt:
          previous?.targetTempoReadyAt ??
          (isTimedTargetTempoCompletion ? now : null),
      bestTargetTempoAccuracy:
          (isTimedPerformance &&
              isTargetTempoRun &&
              accuracy > (previous?.bestTargetTempoAccuracy ?? 0))
          ? accuracy
          : (previous?.bestTargetTempoAccuracy ?? 0),
      bestTargetTempoScore:
          (isTimedPerformance &&
              isTargetTempoRun &&
              score > (previous?.bestTargetTempoScore ?? 0))
          ? score
          : (previous?.bestTargetTempoScore ?? 0),
      assistedCompletions:
          (previous?.assistedCompletions ?? 0) + (isAssistedCompletion ? 1 : 0),
      timedCompletions:
          (previous?.timedCompletions ?? 0) +
          (isTimedTargetTempoCompletion ? 1 : 0),
      history: boundedHistory,
    );

    await prefs.setString('$_prefix$stageId', jsonEncode(next.toJson()));
  }

  /// Convenience method to record an [AttemptRecord].
  Future<void> recordAttempt(
    final AttemptRecord attempt, {
    final int maxHistoryEntries = defaultMaxHistoryEntries,
  }) async {
    await record(
      stageId: attempt.exercise,
      accuracy: attempt.accuracy,
      score: attempt.score,
      totalNotes: attempt.result.totalNotes,
      hitNotes: attempt.result.hitNotes,
      range: attempt.range,
      hand: attempt.hand,
      mode: attempt.mode,
      tempo: attempt.tempo,
      targetTempo: attempt.targetTempo,
      speed: attempt.speed,
      isAssisted: attempt.isAssisted,
      date: attempt.date,
      maxHistoryEntries: maxHistoryEntries,
    );
  }

  /// Retrieves the bounded attempt history for a specific exercise / stage.
  Future<List<AttemptRecord>> getHistory(String stageId) async {
    final progress = await read(stageId);
    return progress?.history ?? const [];
  }

  /// Retrieves all attempt records across all exercises, sorted by date descending.
  Future<List<AttemptRecord>> getAllHistory() async {
    final all = await readAll();
    final List<AttemptRecord> allAttempts = [
      for (final progress in all.values) ...progress.history,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return allAttempts;
  }

  /// Checks whether target tempo readiness has been achieved for a stage.
  Future<bool> isTargetTempoReady(String stageId) async {
    final progress = await read(stageId);
    return progress?.targetTempoReady ?? false;
  }

  /// Migrates legacy stored progress entries, strictly preserving existing bests
  /// while ensuring new readiness and history structures are initialized.
  Future<StageProgress?> migrateLegacy(String stageId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$stageId');
    if (raw == null) return null;
    final progress = _decode(stageId, raw);
    if (progress == null) return null;
    await prefs.setString('$_prefix$stageId', jsonEncode(progress.toJson()));
    return progress;
  }

  Future<String?> lastPlayedStageId() async =>
      (await SharedPreferences.getInstance()).getString(_lastPlayedKey);

  Future<void> setLastPlayed(final String stageId) async =>
      (await SharedPreferences.getInstance()).setString(
        _lastPlayedKey,
        stageId,
      );

  StageProgress? _decode(final String stageId, final String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!json.containsKey('stageId')) {
        json['stageId'] = stageId;
      }
      return StageProgress.fromJson(json);
    } catch (_) {
      // A corrupt entry is treated as no history. Rethrowing here would make
      // one bad write break the level list for good.
      return null;
    }
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(),
);

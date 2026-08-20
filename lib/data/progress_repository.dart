import 'dart:convert';

import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_models.dart';

/// Per-stage bests, stored on device. No accounts and no network.
///
/// One key per stage rather than a single blob, so a corrupt entry costs one
/// stage's history instead of all of it.
class ProgressRepository {
  static const _prefix = 'progress.';
  static const _lastPlayedKey = 'progress.lastPlayed';

  /// Accuracy at or above this counts as clearing the stage.
  static const double completionThreshold = 0.9;

  Future<StageProgress?> read(String stageId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(stageId, prefs.getString('$_prefix$stageId'));
  }

  Future<Map<String, StageProgress>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, StageProgress>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix) || key == _lastPlayedKey) continue;
      final id = key.substring(_prefix.length);
      final progress = _decode(id, prefs.getString(key));
      if (progress != null) out[id] = progress;
    }
    return out;
  }

  Future<void> record({
    required String stageId,
    required double accuracy,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = _decode(stageId, prefs.getString('$_prefix$stageId'));

    // Bests only ever climb; a bad run still counts as an attempt, and
    // clearing a stage once is permanent.
    final next = StageProgress(
      stageId: stageId,
      bestAccuracy:
          accuracy > (previous?.bestAccuracy ?? 0) ? accuracy : (previous?.bestAccuracy ?? 0),
      bestScore: score > (previous?.bestScore ?? 0) ? score : (previous?.bestScore ?? 0),
      attempts: (previous?.attempts ?? 0) + 1,
      completed: (previous?.completed ?? false) || accuracy >= completionThreshold,
      unlocked: true,
      completedAt: previous?.completedAt ??
          (accuracy >= completionThreshold ? DateTime.now() : null),
      lastAttemptAt: DateTime.now(),
    );

    await prefs.setString('$_prefix$stageId', jsonEncode(next.toJson()));
  }

  Future<String?> lastPlayedStageId() async =>
      (await SharedPreferences.getInstance()).getString(_lastPlayedKey);

  Future<void> setLastPlayed(String stageId) async =>
      (await SharedPreferences.getInstance()).setString(_lastPlayedKey, stageId);

  StageProgress? _decode(String stageId, String? raw) {
    if (raw == null) return null;
    try {
      return StageProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A corrupt entry is treated as no history. Rethrowing here would make
      // one bad write break the level list for good.
      return null;
    }
  }
}

final progressRepositoryProvider =
    Provider<ProgressRepository>((ref) => ProgressRepository());

import 'package:riverpod/riverpod.dart';
import '../models/level_models.dart';
import 'ingestion_repository.dart';

/// Repository for loading and managing levels/stages.
///
/// Levels are defined in Dart, in [_loadBuiltInLevels] below. There is no
/// JSON asset pipeline: an earlier version read `manifest.json` and
/// `stages.json` from `assets/levels/`, neither of which ever existed, and
/// silently fell back to these same built-in levels whenever that read
/// failed -- which was every time. Do not go looking for a JSON loader; there
/// isn't one.
class LevelRepository {
  final Map<String, StageModel> _stages = {};
  final Map<String, LevelModel> _levels = {};
  final Map<String, StageModel> _importedStages = {};

  LevelRepository() {
    _loadBuiltInLevels();
  }

  /// Load built-in levels as fallback
  void _loadBuiltInLevels() {
    // Level 1: Simple C Major Scale
    final level1 = LevelModel(
      id: 'level_1',
      title: 'C Major Scale',
      description: 'Learn the C major scale with quarter notes',
      tempo: 80,
      beatsPerMeasure: 4,
      totalMeasures: 4,
      measures: [
        LevelMeasure(
          index: 0,
          startBeat: 0,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0), // C4
            LevelNote(
                midiNote: 62,
                startBeat: 1,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1), // D4
            LevelNote(
                midiNote: 64,
                startBeat: 2,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 2), // E4
            LevelNote(
                midiNote: 65,
                startBeat: 3,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 3), // F4
          ],
        ),
        LevelMeasure(
          index: 1,
          startBeat: 4,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 67,
                startBeat: 4,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 0), // G4
            LevelNote(
                midiNote: 69,
                startBeat: 5,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 1), // A4
            LevelNote(
                midiNote: 71,
                startBeat: 6,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 2), // B4
            LevelNote(
                midiNote: 72,
                startBeat: 7,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 3), // C5
          ],
        ),
        LevelMeasure(
          index: 2,
          startBeat: 8,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 72,
                startBeat: 8,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 0), // C5
            LevelNote(
                midiNote: 71,
                startBeat: 9,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 1), // B4
            LevelNote(
                midiNote: 69,
                startBeat: 10,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 2), // A4
            LevelNote(
                midiNote: 67,
                startBeat: 11,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 3), // G4
          ],
        ),
        LevelMeasure(
          index: 3,
          startBeat: 12,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 65,
                startBeat: 12,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 0), // F4
            LevelNote(
                midiNote: 64,
                startBeat: 13,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 1), // E4
            LevelNote(
                midiNote: 62,
                startBeat: 14,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 2), // D4
            LevelNote(
                midiNote: 60,
                startBeat: 15,
                durationBeats: 1,
                measureIndex: 3,
                beatIndex: 3), // C4
          ],
        ),
      ],
    );

    // Level 2: Simple melody with half notes
    final level2 = LevelModel(
      id: 'level_2',
      title: 'Ode to Joy (Excerpt)',
      description: 'Play the famous melody with half and quarter notes',
      tempo: 90,
      beatsPerMeasure: 4,
      totalMeasures: 4,
      measures: [
        LevelMeasure(
          index: 0,
          startBeat: 0,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 64,
                startBeat: 0,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 0), // E4
            LevelNote(
                midiNote: 64,
                startBeat: 1,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 1), // E4
            LevelNote(
                midiNote: 65,
                startBeat: 2,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 2), // F4
            LevelNote(
                midiNote: 67,
                startBeat: 3,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 3), // G4
          ],
        ),
        LevelMeasure(
          index: 1,
          startBeat: 4,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 67,
                startBeat: 4,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 0), // G4
            LevelNote(
                midiNote: 65,
                startBeat: 5,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 1), // F4
            LevelNote(
                midiNote: 64,
                startBeat: 6,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 2), // E4
            LevelNote(
                midiNote: 62,
                startBeat: 7,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 3), // D4
          ],
        ),
        LevelMeasure(
          index: 2,
          startBeat: 8,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 60,
                startBeat: 8,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 0), // C4
            LevelNote(
                midiNote: 60,
                startBeat: 9,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 1), // C4
            LevelNote(
                midiNote: 62,
                startBeat: 10,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 2), // D4
            LevelNote(
                midiNote: 64,
                startBeat: 11,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 3), // E4
          ],
        ),
        LevelMeasure(
          index: 3,
          startBeat: 12,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 64,
                startBeat: 12,
                durationBeats: 2,
                measureIndex: 3,
                beatIndex: 0), // E4 (half)
            LevelNote(
                midiNote: 62,
                startBeat: 14,
                durationBeats: 2,
                measureIndex: 3,
                beatIndex: 2), // D4 (half)
          ],
        ),
      ],
    );

    // Level 3: Mixed rhythms
    final level3 = LevelModel(
      id: 'level_3',
      title: 'Mixed Rhythms',
      description: 'Practice quarter, half, and eighth notes',
      tempo: 70,
      beatsPerMeasure: 4,
      totalMeasures: 4,
      measures: [
        LevelMeasure(
          index: 0,
          startBeat: 0,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 60,
                startBeat: 0,
                durationBeats: 2,
                measureIndex: 0,
                beatIndex: 0), // C4 half
            LevelNote(
                midiNote: 64,
                startBeat: 2,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 2), // E4 quarter
            LevelNote(
                midiNote: 67,
                startBeat: 3,
                durationBeats: 0.5,
                measureIndex: 0,
                beatIndex: 3), // G4 eighth
            LevelNote(
                midiNote: 72,
                startBeat: 3.5,
                durationBeats: 0.5,
                measureIndex: 0,
                beatIndex: 3), // C5 eighth
          ],
        ),
        LevelMeasure(
          index: 1,
          startBeat: 4,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 72,
                startBeat: 4,
                durationBeats: 0.5,
                measureIndex: 1,
                beatIndex: 0), // C5 eighth
            LevelNote(
                midiNote: 67,
                startBeat: 4.5,
                durationBeats: 0.5,
                measureIndex: 1,
                beatIndex: 0), // G4 eighth
            LevelNote(
                midiNote: 65,
                startBeat: 5,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 1), // F4 quarter
            LevelNote(
                midiNote: 64,
                startBeat: 6,
                durationBeats: 2,
                measureIndex: 1,
                beatIndex: 2), // E4 half
          ],
        ),
        LevelMeasure(
          index: 2,
          startBeat: 8,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 62,
                startBeat: 8,
                durationBeats: 0.5,
                measureIndex: 2,
                beatIndex: 0), // D4 eighth
            LevelNote(
                midiNote: 64,
                startBeat: 8.5,
                durationBeats: 0.5,
                measureIndex: 2,
                beatIndex: 0), // E4 eighth
            LevelNote(
                midiNote: 65,
                startBeat: 9,
                durationBeats: 0.5,
                measureIndex: 2,
                beatIndex: 1), // F4 eighth
            LevelNote(
                midiNote: 67,
                startBeat: 9.5,
                durationBeats: 0.5,
                measureIndex: 2,
                beatIndex: 1), // G4 eighth
            LevelNote(
                midiNote: 69,
                startBeat: 10,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 2), // A4 quarter
            LevelNote(
                midiNote: 67,
                startBeat: 11,
                durationBeats: 1,
                measureIndex: 2,
                beatIndex: 3), // G4 quarter
          ],
        ),
        LevelMeasure(
          index: 3,
          startBeat: 12,
          beatsPerMeasure: 4,
          notes: [
            LevelNote(
                midiNote: 65,
                startBeat: 12,
                durationBeats: 2,
                measureIndex: 3,
                beatIndex: 0), // F4 half
            LevelNote(
                midiNote: 60,
                startBeat: 14,
                durationBeats: 2,
                measureIndex: 3,
                beatIndex: 2), // C4 half
          ],
        ),
      ],
    );

    _levels[level1.id] = level1;
    _levels[level2.id] = level2;
    _levels[level3.id] = level3;

    // Create stages
    _stages['stage_1'] = StageModel(
      id: 'stage_1',
      title: 'C Major Scale',
      description: 'Learn the C major scale with quarter notes',
      difficulty: Difficulty.beginner,
      level: level1,
      order: 1,
      xpReward: 100,
    );

    _stages['stage_2'] = StageModel(
      id: 'stage_2',
      title: 'Ode to Joy',
      description: 'Play the famous melody with half and quarter notes',
      difficulty: Difficulty.beginner,
      level: level2,
      order: 2,
      prerequisites: ['stage_1'],
      xpReward: 150,
    );

    _stages['stage_3'] = StageModel(
      id: 'stage_3',
      title: 'Mixed Rhythms',
      description: 'Practice quarter, half, and eighth notes',
      difficulty: Difficulty.intermediate,
      level: level3,
      order: 3,
      prerequisites: ['stage_2'],
      xpReward: 200,
    );
  }

  /// Get a level by ID
  LevelModel? getLevel(String id) => _levels[id];

  /// Get a stage by ID
  StageModel? getStage(String id) {
    final builtIn = _stages[id];
    if (builtIn != null) return builtIn;

    for (final stage in _importedStages.values) {
      if (stage.id == id) return stage;
    }
    return null;
  }

  /// Get all levels
  List<LevelModel> getAllLevels() => _levels.values.toList();

  /// Add an imported level and create a stage wrapper for it
  void addImportedLevel(LevelModel level) {
    _levels[level.id] = level;
    // Create a stage wrapper for the imported level
    final importedStagesCount = _importedStages.length;
    final order = 100 + importedStagesCount; // After built-in stages (1-3)
    _importedStages[level.id] = StageModel(
      id: 'imported_${level.id}',
      title: level.title,
      description: level.description,
      difficulty: Difficulty.beginner,
      level: level,
      order: order,
      prerequisites: const [],
      xpReward: 50,
    );
  }

  /// Remove an imported level and its stage wrapper
  void removeImportedLevel(String levelId) {
    _levels.remove(levelId);
    _importedStages.remove(levelId);
  }

  /// Get all stages including imported ones
  List<StageModel> getAllStages() {
    final stages = _stages.values.toList();
    stages.sort((a, b) => a.order.compareTo(b.order));
    // Imported stages must render newest-first, so sort descending by
    // order (order increases with each import, so the latest import has
    // the highest order value).
    final importedStages = _importedStages.values.toList();
    importedStages.sort((a, b) => b.order.compareTo(a.order));
    return [...stages, ...importedStages];
  }

  /// Check if a level is imported (not built-in)
  bool isImportedLevel(String levelId) => _importedStages.containsKey(levelId);
}

/// Riverpod provider for the level repository.
///
/// Imported levels are persisted by [IngestionRepository], so the in-memory
/// catalog must hydrate before the level list is rendered.
final levelRepositoryProvider = FutureProvider<LevelRepository>((ref) async {
  final repository = LevelRepository();
  final ingestion = await ref.watch(ingestionRepositoryProvider.future);
  final imported = await ingestion.listImportedLevels();
  for (final level in imported) {
    repository.addImportedLevel(level);
  }
  return repository;
});

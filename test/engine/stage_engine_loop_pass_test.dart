import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/engine/stage_engine.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  group('StageEngine loopPassCompleted event', () {
    late LevelModel level;

    setUp(() {
      level = const LevelModel(
        id: 'loop_event_test',
        title: 'Loop Event Test',
        description: 'Test level',
        tempo: 120, // 2 beats/sec (0.5s per beat)
        totalMeasures: 2,
        beatsPerMeasure: 4,
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
                beatIndex: 0,
              ),
              LevelNote(
                midiNote: 62,
                startBeat: 2,
                durationBeats: 1,
                measureIndex: 0,
                beatIndex: 2,
              ),
            ],
          ),
          LevelMeasure(
            index: 1,
            startBeat: 4,
            beatsPerMeasure: 4,
            notes: [
              LevelNote(
                midiNote: 64,
                startBeat: 4,
                durationBeats: 1,
                measureIndex: 1,
                beatIndex: 0,
              ),
            ],
          ),
        ],
      );
    });

    test('emits loopPassCompleted event when a loop pass finishes and wraps', () async {
      final engine = StageEngine(
        level: level,
        config: const StageEngineConfig(
          playbackSpeed: 10.0, // fast playback for quick test
          countInEnabled: false,
        ),
      );

      final loopEvents = <({double accuracy, int totalNotes, int hitNotes})>[];
      final sub = engine.events.listen((event) {
        event.whenOrNull(
          loopPassCompleted: (accuracy, score, totalNotes, hitNotes, start, end) {
            loopEvents.add((
              accuracy: accuracy,
              totalNotes: totalNotes,
              hitNotes: hitNotes,
            ));
          },
        );
      });

      // Loop measure 0: beats [0, 4) containing 2 notes (C4 at 0, D4 at 2)
      engine.playLoop(0, 4);

      // Hit note 0 (C4 at beat 0)
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0,
          volume: 0.8,
        ),
      );

      // Wait for loop to wrap once
      await Future<void>.delayed(const Duration(milliseconds: 300));
      engine.stop();
      await sub.cancel();
      engine.dispose();

      expect(loopEvents, isNotEmpty);
      final firstPass = loopEvents.first;
      expect(firstPass.totalNotes, 2);
      expect(firstPass.hitNotes, 1);
      expect(firstPass.accuracy, 0.5); // 1 hit, 1 miss
    });

    test('emits loopPassCompleted with accuracy 1.0 in waiting mode loop wrap', () async {
      final engine = StageEngine(
        level: level,
        config: const StageEngineConfig(
          practiceMode: PracticeMode.waiting,
        ),
      );

      final loopEvents = <({double accuracy, int totalNotes, int hitNotes})>[];
      final sub = engine.events.listen((event) {
        event.whenOrNull(
          loopPassCompleted: (accuracy, score, totalNotes, hitNotes, start, end) {
            loopEvents.add((
              accuracy: accuracy,
              totalNotes: totalNotes,
              hitNotes: hitNotes,
            ));
          },
        );
      });

      // Loop measure 0: beats [0, 4) containing 2 notes (60 at beat 0, 62 at beat 2)
      engine.playLoop(0, 4);

      // Hit first note
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 261.63,
          confidence: 1.0,
          midiNote: 60,
          timestamp: 0,
          volume: 0.8,
        ),
      );

      // Hit second note
      engine.processPitchEvent(
        const PitchEvent(
          frequency: 293.66,
          confidence: 1.0,
          midiNote: 62,
          timestamp: 0,
          volume: 0.8,
        ),
      );

      // In waiting mode, hitting all awaited notes in the loop triggers wrap
      await Future<void>.delayed(const Duration(milliseconds: 50));
      engine.stop();
      await sub.cancel();
      engine.dispose();

      expect(loopEvents, isNotEmpty);
      expect(loopEvents.first.accuracy, 1.0);
      expect(loopEvents.first.totalNotes, 2);
      expect(loopEvents.first.hitNotes, 2);
    });
  });
}

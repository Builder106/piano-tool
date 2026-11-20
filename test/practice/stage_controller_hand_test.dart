import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/models/level_models.dart';
import 'package:piano_tool/practice/stage_controller.dart';

LevelModel _twoHandLevel() => const LevelModel(
  id: 'two_hand_ctrl',
  title: 'Two Hand Controller Level',
  description: '',
  tempo: 120,
  beatsPerMeasure: 4,
  totalMeasures: 2,
  clef: LevelClef.grand,
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
          voiceIndex: 0,
        ),
        LevelNote(
          midiNote: 48,
          startBeat: 0,
          durationBeats: 1,
          measureIndex: 0,
          beatIndex: 0,
          voiceIndex: 1,
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer createHarness(LevelRepository repo) => ProviderContainer(
    overrides: [
      audioGrantedProvider.overrideWith((ref) async => true),
      levelRepositoryProvider.overrideWith((ref) => SynchronousFuture(repo)),
    ],
  );

  test(
    'built-in stage_1 has unknown hand assignment and supports only both hands',
    () {
      final repo = LevelRepository();
      final c = createHarness(repo);
      addTearDown(c.dispose);

      final ctrl = c.read(stageControllerProvider('stage_1').notifier);
      final ui = c.read(stageControllerProvider('stage_1'));

      expect(ui.isHandAssignmentKnown, isFalse);
      expect(ui.isHandAssignmentUnknown, isTrue);
      expect(ui.supportedHands, {HandSelection.both});
      expect(ctrl.handSelection, HandSelection.both);

      expect(c.read(isHandAssignmentKnownProvider('stage_1')), isFalse);
      expect(c.read(supportedHandsProvider('stage_1')), {HandSelection.both});
      expect(c.read(handSelectionProvider('stage_1')), HandSelection.both);
    },
  );

  test(
    'imported two-hand stage exposes known hand assignment and supports left, right, both',
    () {
      final repo = LevelRepository()..addImportedLevel(_twoHandLevel());
      final c = createHarness(repo);
      addTearDown(c.dispose);

      const stageId = 'imported_two_hand_ctrl';
      final ctrl = c.read(stageControllerProvider(stageId).notifier);
      final ui = c.read(stageControllerProvider(stageId));

      expect(ui.isHandAssignmentKnown, isTrue);
      expect(ui.isHandAssignmentUnknown, isFalse);
      expect(ui.supportedHands, {
        HandSelection.both,
        HandSelection.right,
        HandSelection.left,
      });
      expect(ctrl.supportedHands, ui.supportedHands);
      expect(ctrl.handSelection, HandSelection.both);

      expect(c.read(isHandAssignmentKnownProvider(stageId)), isTrue);
      expect(c.read(supportedHandsProvider(stageId)), {
        HandSelection.both,
        HandSelection.right,
        HandSelection.left,
      });
      expect(c.read(handSelectionProvider(stageId)), HandSelection.both);

      // Change hand selection to right hand
      ctrl.setHandSelection(HandSelection.right);
      expect(ctrl.handSelection, HandSelection.right);
      expect(c.read(handSelectionProvider(stageId)), HandSelection.right);
      expect(
        c.read(stageControllerProvider(stageId)).handSelection,
        HandSelection.right,
      );

      // Accessible description includes hand prefix
      final desc = c.read(accessibleDescriptionProvider(stageId));
      expect(desc, contains('Right hand. '));
    },
  );

  test('changing hand selection on controller updates state and provider', () {
    final repo = LevelRepository()..addImportedLevel(_twoHandLevel());
    final c = createHarness(repo);
    addTearDown(c.dispose);

    const stageId = 'imported_two_hand_ctrl';
    final ctrl = c.read(stageControllerProvider(stageId).notifier);

    ctrl.setHandSelection(HandSelection.left);
    expect(ctrl.handSelection, HandSelection.left);
    expect(c.read(handSelectionProvider(stageId)), HandSelection.left);
    expect(
      c.read(accessibleDescriptionProvider(stageId)),
      contains('Left hand. '),
    );
  });
}

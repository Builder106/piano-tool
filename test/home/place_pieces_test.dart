import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/data/level_repository.dart';
import 'package:piano_tool/home/home_screen.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  final stages = LevelRepository().getAllStages();

  test('pieces sit on every other white key from middle C', () {
    final (pieces, addKey) = placePieces(stages, const {});
    expect(pieces.map((p) => p.midi), [60, 64, 67]);
    expect(addKey, 71);
  });

  test('a new learner has one piece up next and the rest locked', () {
    final (pieces, _) = placePieces(stages, const {});
    expect(pieces.map((p) => p.state), [
      PieceState.next,
      PieceState.locked,
      PieceState.locked,
    ]);
    expect(pieces[1].status, 'After C Major Scale');
  });

  test('a cleared piece is learned and the following one is next', () {
    final (pieces, _) = placePieces(stages, const {
      'stage_1': StageProgress(
        stageId: 'stage_1',
        bestAccuracy: 0.96,
        completed: true,
      ),
    });
    expect(pieces[0].state, PieceState.learned);
    expect(pieces[0].status, 'Learned. Best 96%');
    expect(pieces[1].state, PieceState.next);
    expect(pieces[2].status, 'After Ode to Joy');
  });

  test('a struck key opens the piece on it, or one on a key of that name', () {
    final (pieces, _) = placePieces(stages, const {
      'stage_1': StageProgress(stageId: 'stage_1', completed: true),
    });
    expect(pieceForKey(pieces, 60)?.stage.id, 'stage_1');
    expect(pieceForKey(pieces, 76)?.stage.id, 'stage_2');
    expect(pieceForKey(pieces, 67), isNull, reason: 'Mixed Rhythms is locked');
    expect(pieceForKey(pieces, 62), isNull);
  });
}

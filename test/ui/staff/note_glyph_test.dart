import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/note_glyph.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  final c = PianoColors.light();

  String sig(NoteState s) {
    final st = NoteGlyphStyle.forState(s, c);
    return '${st.filled}-${st.ringed}-${st.struck}';
  }

  const hits = [NoteState.hitPerfect, NoteState.hitGood, NoteState.hitOkay];

  test('six states collapse to four distinct shapes', () {
    expect(NoteState.values.map(sig).toSet().length, 4);
  });

  test('upcoming, active, hit, and missed are all shape-distinct', () {
    final four = {
      sig(NoteState.upcoming),
      sig(NoteState.active),
      sig(NoteState.hitPerfect),
      sig(NoteState.missed),
    };
    expect(four.length, 4);
  });

  test('all three hit gradations render identically', () {
    expect(hits.map(sig).toSet().length, 1);
  });

  test('hit is filled and missed is hollow', () {
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).filled, isTrue);
    }
    expect(NoteGlyphStyle.forState(NoteState.missed, c).filled, isFalse);
  });

  test('missed carries a strike, hit does not', () {
    expect(NoteGlyphStyle.forState(NoteState.missed, c).struck, isTrue);
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).struck, isFalse);
    }
  });

  test('states map to their token colours', () {
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).color, c.success);
    }
    expect(NoteGlyphStyle.forState(NoteState.missed, c).color, c.error);
    expect(NoteGlyphStyle.forState(NoteState.upcoming, c).color, c.muted);
    expect(NoteGlyphStyle.forState(NoteState.active, c).color, c.accent);
  });
}

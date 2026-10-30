import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/note_glyph.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  final c = PianoColors.light();

  String sig(NoteState s) {
    final st = NoteGlyphStyle.forState(s, c);
    return '${st.halo}-${st.ringed}-${st.ticked}-${st.underlined}-${st.struck}';
  }

  const hits = [NoteState.hitPerfect, NoteState.hitGood, NoteState.hitOkay];

  test('every state has its own mark, without relying on colour', () {
    expect(NoteState.values.map(sig).toSet().length, NoteState.values.length);
  });

  test('upcoming notes carry no mark', () {
    final s = NoteGlyphStyle.forState(NoteState.upcoming, c);
    expect([
      s.halo,
      s.ringed,
      s.ticked,
      s.underlined,
      s.struck,
    ], everyElement(isFalse));
  });

  test('every hit is ticked and only a miss is struck', () {
    for (final h in hits) {
      final s = NoteGlyphStyle.forState(h, c);
      expect(s.ticked, isTrue);
      expect(s.struck, isFalse);
    }
    final missed = NoteGlyphStyle.forState(NoteState.missed, c);
    expect(missed.ticked, isFalse);
    expect(missed.struck, isTrue);
  });

  test('hit timing qualities are visually differentiated', () {
    expect(NoteGlyphStyle.forState(NoteState.hitPerfect, c).ringed, isTrue);
    expect(NoteGlyphStyle.forState(NoteState.hitGood, c).ringed, isFalse);
    expect(NoteGlyphStyle.forState(NoteState.hitOkay, c).underlined, isTrue);
    expect(NoteGlyphStyle.forState(NoteState.hitGood, c).underlined, isFalse);
  });

  test('only the note to play now has a halo', () {
    for (final s in NoteState.values) {
      expect(
        NoteGlyphStyle.forState(s, c).halo,
        s == NoteState.active,
        reason: '$s',
      );
    }
  });

  test('states map to their token colours', () {
    expect(NoteGlyphStyle.forState(NoteState.hitPerfect, c).color, c.success);
    expect(NoteGlyphStyle.forState(NoteState.hitGood, c).color, c.success);
    expect(NoteGlyphStyle.forState(NoteState.hitOkay, c).color, c.warning);
    expect(NoteGlyphStyle.forState(NoteState.missed, c).color, c.error);
    expect(NoteGlyphStyle.forState(NoteState.upcoming, c).color, c.ink);
    expect(NoteGlyphStyle.forState(NoteState.active, c).color, c.accent);
  });
}

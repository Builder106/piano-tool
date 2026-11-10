import '../data/settings_repository.dart';
import '../models/audio_models.dart';

/// Identifies an input setup that has been checked. A different source or a
/// different digital piano is a different setup and is checked again. The
/// format matches what earlier versions saved, so a past check still counts.
String inputCheckKey(PracticeInputSource source, String? midiDeviceId) =>
    source == PracticeInputSource.microphone || midiDeviceId == null
    ? source.name
    : '${source.name}:$midiDeviceId';

/// What the check has heard so far.
enum Hearing { waiting, silent, weak, unclear, unstable, wrongNote, heard }

const _names = [
  'C',
  'C sharp',
  'D',
  'E flat',
  'E',
  'F',
  'F sharp',
  'G',
  'A flat',
  'A',
  'B flat',
  'B',
];

/// Listens for any C and says, in plain words, what it hears instead. Feed
/// it frame levels and pitch events with the seconds since the check began.
class InputCheck {
  InputCheck({required this.loud});

  /// A frame level at or above this is a played note, not room noise.
  final double loud;
  double get _quiet => loud * 0.15;

  final _levels = <(double, double)>[];
  final _pitches = <(double, PitchEvent)>[];
  double _now = 0;
  bool _heard = false;

  void level(double rms, double at) {
    _now = at;
    _levels.add((at, rms));
    _levels.removeWhere((l) => l.$1 < at - 1.0);
  }

  void pitch(PitchEvent event, double at) {
    _now = at;
    _pitches.add((at, event));
    _pitches.removeWhere((p) => p.$1 < at - 1.2);
    final c = event.midiNote % 12 == 0;
    if (!c) return;
    // A key strike from the instrument is proof; the microphone needs the
    // same C twice in a row so a passing noise does not count.
    if (event.struck) {
      _heard = true;
      return;
    }
    final recent = [for (final p in _pitches) p.$2];
    if (recent.length >= 2 && recent[recent.length - 2].midiNote % 12 == 0) {
      _heard = true;
    }
  }

  /// Moves the clock on when nothing new has arrived.
  void tick(double at) => _now = at;

  Hearing get hearing {
    if (_heard) return Hearing.heard;
    final notes = [for (final p in _pitches) p.$2.midiNote];
    if (notes.isNotEmpty) {
      if (notes.toSet().length >= 3) return Hearing.unstable;
      return Hearing.wrongNote;
    }
    final peak = _levels.fold(0.0, (m, l) => l.$2 > m ? l.$2 : m);
    if (peak >= loud) return Hearing.unclear;
    if (peak >= _quiet) return Hearing.weak;
    return _now >= 3 ? Hearing.silent : Hearing.waiting;
  }

  /// The last note heard, by name, when it was not a C.
  String? get wrongName =>
      _pitches.isEmpty ? null : _names[_pitches.last.$2.midiNote % 12];

  /// What to tell the player, for a microphone or a digital piano.
  String message({required bool midi}) => switch (hearing) {
    Hearing.waiting => 'Listening',
    Hearing.silent =>
      midi
          ? 'Nothing from the digital piano yet. Is it plugged in?'
          : 'Nothing yet. Play the circled C a little harder',
    Hearing.weak => 'Something faint. Play louder, or move closer',
    Hearing.unclear => 'A sound, but no clear note. Play one key on its own',
    Hearing.unstable => 'The note keeps changing. Hold one key down',
    Hearing.wrongNote => 'That was $wrongName. Try the circled C',
    Hearing.heard => 'Heard it',
  };
}

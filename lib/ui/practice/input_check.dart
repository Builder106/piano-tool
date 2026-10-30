import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';
import '../../models/audio_models.dart';
import '../desk/desk.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Identifies an input setup that has been checked. A different source or a
/// different digital piano is a different setup and is checked again.
String inputCheckKey(PracticeInputSource source, String? midiDeviceId) =>
    source == PracticeInputSource.microphone || midiDeviceId == null
    ? source.name
    : '${source.name}:$midiDeviceId';

/// What the check has heard so far.
enum Hearing {
  /// Listening, and too early to call it silence.
  waiting,

  /// Nothing above the room's noise.
  silent,

  /// Sound, but too quiet to read a pitch from.
  weak,

  /// Loud enough, but no clear pitch: noise, speech, a chord.
  unclear,

  /// A pitch that keeps changing.
  unstable,

  /// A clear note other than the one asked for.
  wrongNote,

  /// The note asked for.
  heard,
}

typedef InputReading = ({Hearing hearing, int? midi});

/// Classifies incoming frames for the input check. Pure and clock-driven, so
/// it can be tested without a microphone.
class InputListener {
  InputListener({
    required this.target,
    required this.clearLevel,
    required DateTime startedAt,
  }) : _startedAt = startedAt;

  /// The note the learner is asked to play.
  final int target;

  /// The level the pitch detector needs before it will read a pitch.
  final double clearLevel;

  final DateTime _startedAt;
  final List<(DateTime, double)> _levels = [];
  final List<(DateTime, int)> _frames = [];
  (DateTime, int)? _lastStrike;
  bool _heard = false;

  /// Below this share of [clearLevel] the room counts as silent.
  static const double _weakShare = 0.35;
  static const Duration _window = Duration(milliseconds: 900);
  static const Duration _patience = Duration(seconds: 5);

  void addLevel(DateTime at, double rms) {
    _levels.add((at, rms));
    _trim(at);
  }

  void addPitch(DateTime at, PitchEvent event) {
    if (event.struck) {
      _lastStrike = (at, event.midiNote);
      if (event.midiNote == target) _heard = true;
    } else {
      _frames.add((at, event.midiNote));
      _trim(at);
      // A few frames in a row of the target note: a held key.
      final recent = _frames.reversed.take(3).toList();
      if (recent.length == 3 && recent.every((f) => f.$2 == target)) {
        _heard = true;
      }
    }
  }

  void _trim(DateTime now) {
    final cutoff = now.subtract(_window);
    _levels.removeWhere((l) => l.$1.isBefore(cutoff));
    _frames.removeWhere((f) => f.$1.isBefore(cutoff));
  }

  InputReading readingAt(DateTime now) {
    if (_heard) return (hearing: Hearing.heard, midi: target);
    _trim(now);

    final strike = _lastStrike;
    if (strike != null && now.difference(strike.$1) < _window * 2) {
      return (hearing: Hearing.wrongNote, midi: strike.$2);
    }

    if (_frames.length >= 3) {
      final counts = <int, int>{};
      for (final f in _frames) {
        counts[f.$2] = (counts[f.$2] ?? 0) + 1;
      }
      final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value / _frames.length >= 0.6) {
        return (hearing: Hearing.wrongNote, midi: top.key);
      }
      return (hearing: Hearing.unstable, midi: null);
    }

    final loudest = _levels.fold<double>(0, (m, l) => l.$2 > m ? l.$2 : m);
    if (loudest >= clearLevel) return (hearing: Hearing.unclear, midi: null);
    if (loudest >= clearLevel * _weakShare) {
      return (hearing: Hearing.weak, midi: null);
    }
    return now.difference(_startedAt) < _patience
        ? (hearing: Hearing.waiting, midi: null)
        : (hearing: Hearing.silent, midi: null);
  }
}

const int _middleC = 60;

String noteName(int midi) {
  const names = [
    'C',
    'C♯',
    'D',
    'E♭',
    'E',
    'F',
    'F♯',
    'G',
    'A♭',
    'A',
    'B♭',
    'B',
  ];
  return '${names[midi % 12]}${midi ~/ 12 - 1}';
}

/// One short, unscored step before practice: play middle C and see it
/// arrive. Only a received note shows that the input works.
class InputCheck extends StatefulWidget {
  const InputCheck({
    super.key,
    required this.source,
    required this.pitchSources,
    this.levels,
    required this.clearLevel,
    required this.midiConnected,
    required this.onHeard,
    required this.onSkip,
    this.onConnectPiano,
  });

  final PracticeInputSource source;

  /// The chosen inputs' pitch streams, microphone and MIDI.
  final List<Stream<PitchEvent>> pitchSources;

  /// Microphone frame levels; null when the microphone is not in use.
  final Stream<double>? levels;
  final double clearLevel;
  final bool midiConnected;
  final VoidCallback onHeard;
  final VoidCallback onSkip;
  final VoidCallback? onConnectPiano;

  @override
  State<InputCheck> createState() => _InputCheckState();
}

class _InputCheckState extends State<InputCheck> {
  late InputListener _listener;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _tick;
  InputReading _reading = (hearing: Hearing.waiting, midi: null);
  int? _lastHeardMidi;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _listener = InputListener(
      target: _middleC,
      clearLevel: widget.clearLevel,
      startedAt: clock.now(),
    );
    for (final pitches in widget.pitchSources) {
      _subs.add(
        pitches.listen((event) {
          _listener.addPitch(clock.now(), event);
          _lastHeardMidi = event.midiNote;
          _update();
        }),
      );
    }
    final levels = widget.levels;
    if (levels != null) {
      _subs.add(levels.listen((rms) => _listener.addLevel(clock.now(), rms)));
    }
    // Silence produces no events, so the reading is re-taken on a clock.
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final next = _listener.readingAt(clock.now());
    if (next != _reading) setState(() => _reading = next);
  }

  void _stop() {
    _tick?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _retry() {
    _stop();
    setState(() {
      _reading = (hearing: Hearing.waiting, midi: null);
      _lastHeardMidi = null;
    });
    _listen();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  String get _message {
    final usesMic = widget.levels != null;
    return switch (_reading.hearing) {
      Hearing.heard => 'Piano Tool heard middle C. You are ready to practise.',
      Hearing.wrongNote =>
        'That was ${noteName(_reading.midi!)}. Middle C is the white key just '
            'left of the two black keys nearest the middle of the keyboard.',
      Hearing.unstable =>
        'The note keeps changing. Play one key and let it ring.',
      Hearing.unclear =>
        'Sound is coming through, but not one clear note. Play a single key.',
      Hearing.weak =>
        'Piano Tool can only just hear you. Move closer or play a little '
            'louder.',
      Hearing.silent when !usesMic && !widget.midiConnected =>
        'No digital piano is connected yet.',
      Hearing.silent =>
        usesMic
            ? 'Nothing heard yet. Check that the right microphone is chosen '
                  'and not muted.'
            : 'Nothing received yet. Check the cable or Bluetooth '
                  'connection.',
      Hearing.waiting => 'Listening.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    final text = PianoTheme.textThemeOf(context);
    final heard = _reading.hearing == Hearing.heard;
    final showConnect =
        !widget.midiConnected &&
        widget.source != PracticeInputSource.microphone &&
        widget.onConnectPiano != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PianoSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: PaperSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heard ? 'Middle C, heard' : 'Play middle C',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: PianoSpacing.xs),
                Text(
                  'A quick check that Piano Tool can hear your piano. '
                  'Nothing is scored.',
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                ),
                const SizedBox(height: PianoSpacing.md),
                SizedBox(
                  height: 120,
                  child: ExcludeSemantics(
                    child: PianoKeyboardView(
                      due: const {_middleC},
                      playing: {?_lastHeardMidi},
                      range: (low: 48, high: 72),
                    ),
                  ),
                ),
                const SizedBox(height: PianoSpacing.md),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _message,
                    key: const ValueKey('input-check-message'),
                    style: text.bodyLarge?.copyWith(
                      color: heard ? colors.success : colors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: PianoSpacing.md),
                Wrap(
                  spacing: PianoSpacing.sm,
                  runSpacing: PianoSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (heard)
                      FilledButton(
                        onPressed: widget.onHeard,
                        child: const Text('Start practising'),
                      )
                    else if (_reading.hearing != Hearing.waiting)
                      OutlinedButton(
                        onPressed: _retry,
                        child: const Text('Listen again'),
                      ),
                    if (showConnect)
                      OutlinedButton(
                        onPressed: widget.onConnectPiano,
                        child: const Text('Connect a digital piano'),
                      ),
                    if (!heard)
                      TextButton(
                        onPressed: widget.onSkip,
                        child: const Text('Skip for now'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

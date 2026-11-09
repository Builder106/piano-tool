import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/buttons.dart';
import '../brand/palette.dart';
import '../brand/pencil_loop.dart';
import '../data/level_repository.dart';
import '../data/settings_repository.dart';
import '../models/audio_models.dart';
import '../models/level_models.dart';
import '../services/midi_service.dart';
import 'keys.dart';
import 'paper_staff.dart';
import 'practice_screen.dart';
import 'stage_controller.dart';

/// The first few different notes a piece asks for, in order, up to [count]:
/// what to find on the keyboard before playing it.
List<int> notesToFind(LevelModel level, {int count = 3}) {
  final found = <int>[];
  for (final note in notesOf(level)) {
    if (!found.contains(note.midiNote)) found.add(note.midiNote);
    if (found.length == count) break;
  }
  return found;
}

/// "C", "C and E", "C, E and G".
String listNotes(List<int> midis) {
  final names = [for (final m in midis) noteName(m)];
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// Ticks off the notes to find as they are played, in any order. A key
/// strike from a digital piano counts at once and must be the exact key; the
/// microphone hears frames of a sound and has trouble with octaves, so it
/// needs the same note name twice in a row.
class NoteFinder {
  NoteFinder(this.targets);

  final List<int> targets;
  final found = <int>{};
  int? _lastName;

  bool get done => found.length == targets.length;

  /// Feeds one heard event. Returns the target it found, or null.
  int? feed(PitchEvent event) {
    int? match;
    if (event.struck) {
      _lastName = null;
      for (final t in targets) {
        if (t == event.midiNote) match = t;
      }
    } else {
      final name = event.midiNote % 12;
      final repeated = _lastName == name;
      _lastName = name;
      if (repeated) {
        for (final t in targets) {
          if (t % 12 == name && !found.contains(t)) match = t;
        }
      }
    }
    if (match == null || found.contains(match)) return null;
    found.add(match);
    return match;
  }
}

/// Opens the find-the-notes step for a piece.
Route<void> findNotesRoute({required String stageId}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondary) =>
        FindNotesScreen(stageId: stageId),
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// Before a new piece: the few notes it starts with are circled on the
/// keyboard, and each is ticked off as it is played.
class FindNotesScreen extends ConsumerStatefulWidget {
  const FindNotesScreen({super.key, required this.stageId});

  final String stageId;

  @override
  ConsumerState<FindNotesScreen> createState() => _FindNotesScreenState();
}

class _FindNotesScreenState extends ConsumerState<FindNotesScreen> {
  late final StageModel _stage;
  late final NoteFinder _finder;
  late final (int, int) _keys;
  final _subs = <ProviderSubscription<AsyncValue<PitchEvent>>>[];
  bool _listening = false;
  bool _audio = false;
  bool _cantHear = false;
  String? _wrong;
  final _sounding = <int>{};

  @override
  void initState() {
    super.initState();
    _stage = ref
        .read(levelRepositoryProvider)
        .requireValue
        .getAllStages()
        .firstWhere((s) => s.id == widget.stageId);
    _finder = NoteFinder(notesToFind(_stage.level));
    _keys = keyRange([for (final n in notesOf(_stage.level)) n.midiNote]);
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }

  Future<void> _listen() async {
    final source = ref.read(settingsProvider).inputSource;
    final midi = ref.read(midiServiceProvider);
    if (source != PracticeInputSource.microphone) {
      try {
        await midi.connectSoleWiredDevice();
      } on Object {
        // No MIDI on this platform; the microphone may still do.
      }
    }
    if (source != PracticeInputSource.midi) {
      bool granted;
      try {
        granted = await ref.read(audioGrantedProvider.future);
      } on Object {
        granted = false;
      }
      if (!mounted) return;
      setState(() {
        _audio = granted;
        _cantHear = !granted && source == PracticeInputSource.microphone;
      });
      if (_cantHear) return;
    }
    if (!mounted) return;
    if (source != PracticeInputSource.midi) {
      _subs.add(ref.listenManual(audioPitchStreamProvider, (_, e) => _hear(e)));
    }
    if (source != PracticeInputSource.microphone) {
      _subs.add(ref.listenManual(midiPitchStreamProvider, (_, e) => _hear(e)));
    }
    setState(() {
      _listening = true;
      _cantHear = false;
    });
  }

  void _hear(AsyncValue<PitchEvent> next) {
    final event = next.value;
    if (event == null || _finder.done || !mounted) return;
    final found = _finder.feed(event);
    setState(() {
      _sounding
        ..clear()
        ..add(event.midiNote);
      if (found != null) {
        _wrong = null;
      } else if (event.struck &&
          !_finder.targets.contains(event.midiNote)) {
        _wrong = noteName(event.midiNote);
      }
    });
  }

  void _toPractice() => Navigator.of(
    context,
  ).pushReplacement(practiceRoute(stageId: widget.stageId));

  @override
  Widget build(BuildContext context) {
    if (_audio) ref.watch(practiceAudioSessionProvider);
    final u = (MediaQuery.sizeOf(context).height / 720).clamp(0.7, 1.25);
    final targets = _finder.targets;
    final message = _cantHear
        ? "The piano can't hear you yet. Allow the microphone, or plug in a "
              'digital piano.'
        : _finder.done
        ? 'You found all ${targets.length}.'
        : !_listening
        ? 'Press Start listening, then play each circled key.'
        : _wrong != null
        ? 'That was $_wrong. Try the circled keys.'
        : 'Listening. Play the circled keys, in any order.';
    return Material(
      color: Palette.field,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final keysHeight = (box.maxHeight * 0.3).clamp(120.0, 260.0);
            return Column(
              children: [
                SizedBox(
                  height: 64 * u,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * u),
                    child: Row(
                      children: [
                        FieldAction(
                          label: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(
                            _stage.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontSize: 26 * u,
                              color: Colors.white,
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                            ),
                          ),
                        ),
                        FieldAction(label: 'Skip', onPressed: _toPractice),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Palette.page,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      48 * u,
                      32 * u,
                      48 * u,
                      24 * u,
                    ),
                    child: _Page(
                      targets: targets,
                      found: _finder.found,
                      message: message,
                      done: _finder.done,
                      listening: _listening,
                      u: u,
                      onListen: _listen,
                      onContinue: _toPractice,
                    ),
                  ),
                ),
                SizedBox(
                  height: keysHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12 * u),
                    child: PaperKeyboard(
                      low: _keys.$1,
                      high: _keys.$2,
                      sounding: _sounding,
                      circled: {
                        for (final t in targets)
                          if (!_finder.found.contains(t)) t,
                      },
                      found: _finder.found,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.targets,
    required this.found,
    required this.message,
    required this.done,
    required this.listening,
    required this.u,
    required this.onListen,
    required this.onContinue,
  });

  final List<int> targets;
  final Set<int> found;
  final String message;
  final bool done;
  final bool listening;
  final double u;
  final VoidCallback onListen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find ${listNotes(targets)}.',
          style: TextStyle(
            fontFamily: Fonts.ui,
            fontSize: 52 * u,
            height: 1,
            letterSpacing: -1.5 * u,
            color: Palette.ink,
            fontVariations: const [FontVariation('wght', 800)],
          ),
        ),
        SizedBox(height: 12 * u),
        Text(
          message,
          style: TextStyle(
            fontFamily: Fonts.ui,
            fontSize: 22 * u,
            height: 1.35,
            color: Palette.graphite,
          ),
        ),
        SizedBox(height: 24 * u),
        if (done)
          StartButton(label: 'Play the tune', onPressed: onContinue)
        else if (!listening)
          StartButton(label: 'Start listening', onPressed: onListen),
      ],
    );
    final letters = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final t in targets)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * u),
            child: _Letter(
              name: noteName(t),
              found: found.contains(t),
              u: u,
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 760) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, SizedBox(height: 24 * u), letters],
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            SizedBox(width: 32 * u),
            letters,
          ],
        );
      },
    );
  }
}

/// A note's letter, grey until it is found, then ink with a blue pencil loop.
class _Letter extends StatelessWidget {
  const _Letter({required this.name, required this.found, required this.u});

  final String name;
  final bool found;
  final double u;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: found ? '$name, found' : '$name, not found yet',
      child: ExcludeSemantics(
        child: CustomPaint(
          foregroundPainter: found ? const _LetterLoop() : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30 * u, vertical: 18 * u),
            child: Text(
              name.endsWith(' sharp') ? '${name[0]}♯' : name,
              style: TextStyle(
                fontFamily: Fonts.ui,
                fontSize: math.max(64, 96 * u),
                height: 1,
                color: found ? Palette.ink : const Color(0xFFC3C8D8),
                fontVariations: const [FontVariation('wght', 800)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterLoop extends CustomPainter {
  const _LetterLoop();

  @override
  void paint(Canvas canvas, Size size) {
    PencilLoopPainter(
      target: (Offset.zero & size).deflate(2),
      width: 5,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_LetterLoop old) => false;
}

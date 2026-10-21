import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../audio/tone_synthesizer.dart';
import '../../data/ingestion_repository.dart';
import '../../data/level_repository.dart';
import '../../models/level_models.dart';
import '../../models/engine_models.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../practice/transport_column.dart';
import '../staff/staff_geometry.dart' show Clef;
import '../staff/staff_painter.dart' show PlacedNote;
import '../staff/staff_view.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Shows the transcribed level for one imported job, with a read-only
/// preview (no `StageEngine`, no scoring) so the learner can listen before
/// deciding whether to keep it.
///
/// Playback here is a local clock, not the practice engine: this screen has
/// nothing to score, so it only needs to move a playhead across the staff
/// and keyboard, not track hits/misses.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  LevelModel? _level;
  bool _isLoading = true;
  String? _error;

  double _currentBeat = 0;
  Timer? _playbackTimer;
  bool _isPlaying = false;
  double _speed = 1.0;
  bool _isMuted = false;
  bool _showNoteEditor = false;
  AudioSynthesizer? _synthesizer;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synthesizer = ref.read(audioSynthesizerProvider);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _synthesizer?.stop();
    super.dispose();
  }

  Future<void> _loadLevel() async {
    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);
      final result = await repo.pollJob(widget.jobId);
      if (!mounted) return;
      if (result.status == IngestionJobStatus.done && result.level != null) {
        setState(() {
          _level = result.level;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Transcription failed';
          _isLoading = false;
        });
      }
    } on IngestionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(child: Center(child: Text('Error: $_error'))),
      );
    }

    final level = _level!;
    final totalBeats = (level.totalMeasures * level.beatsPerMeasure).toDouble();

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            TransportColumn(
              isPlaying: _isPlaying,
              speed: _speed,
              onPlayPause: _togglePlayback,
              onStop: _stopPlayback,
              onReplay: _replay,
              onSpeedChanged: _setSpeed,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(PianoSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            level.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() => _isMuted = !_isMuted);
                            _synthesizer?.isMuted = _isMuted;
                          },
                          tooltip: _isMuted
                              ? 'Unmute audio preview'
                              : 'Mute audio preview',
                        ),
                      ],
                    ),
                    const SizedBox(height: PianoSpacing.lg),
                    Expanded(
                      flex: _showNoteEditor ? 2 : 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return StaffView(
                            systems: _buildSystems(level),
                            currentBeat: _currentBeat,
                            totalBeats: totalBeats,
                            beatsPerMeasure: level.beatsPerMeasure,
                            beatUnit: level.beatUnit,
                            pixelsPerBeat: 70,
                            maxStaffHeight: constraints.maxHeight * 0.8,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: PianoSpacing.sm),
                    if (_showNoteEditor) ...[
                      Expanded(flex: 3, child: _buildNoteEditorPanel(level)),
                      const SizedBox(height: PianoSpacing.sm),
                    ],
                    SizedBox(
                      height: _showNoteEditor ? 64 : 88,
                      child: PianoKeyboardView(
                        due: _getDueNotesAtBeat(level, _currentBeat),
                        playing: const {},
                      ),
                    ),
                    const SizedBox(height: PianoSpacing.md),
                    LinearProgressIndicator(
                      value: totalBeats > 0 ? _currentBeat / totalBeats : 0,
                      minHeight: 4,
                    ),
                    const SizedBox(height: PianoSpacing.xs),
                    Text(
                      '${_formatTime(_currentBeat, level.tempo)} / '
                      '${_formatTime(totalBeats, level.tempo)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: PianoSpacing.md),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(
                            _showNoteEditor
                                ? Icons.visibility_rounded
                                : Icons.tune_rounded,
                          ),
                          label: Text(
                            _showNoteEditor ? 'Hide Editor' : 'Edit Notes',
                          ),
                          onPressed: () => setState(
                            () => _showNoteEditor = !_showNoteEditor,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: _discard,
                          child: const Text('Discard'),
                        ),
                        const SizedBox(width: PianoSpacing.md),
                        FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save Level'),
                          onPressed: _saveLevel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteEditorPanel(LevelModel level) {
    final colors = PianoTheme.colorsOf(context);
    final allNotes = <({int measureIndex, int noteIndex, LevelNote note})>[];
    for (var m = 0; m < level.measures.length; m++) {
      for (var n = 0; n < level.measures[m].notes.length; n++) {
        allNotes.add((
          measureIndex: m,
          noteIndex: n,
          note: level.measures[m].notes[n],
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(PianoRadius.md),
        border: Border.all(color: colors.staff.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PianoSpacing.md,
              vertical: PianoSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: colors.ink),
                const SizedBox(width: PianoSpacing.xs),
                Text(
                  'Note Correction Inspector (${allNotes.length} notes)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _showNoteEditor = false),
                  tooltip: 'Close inspector',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: allNotes.isEmpty
                ? Center(
                    child: Text(
                      'No notes in transcription',
                      style: TextStyle(color: colors.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PianoSpacing.md,
                      vertical: PianoSpacing.xs,
                    ),
                    itemCount: allNotes.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = allNotes[index];
                      final note = item.note;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                'm.${note.measureIndex + 1} b.${note.startBeat.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: colors.muted),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: PianoSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _midiToPitchName(note.midiNote),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: PianoSpacing.xs),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 15),
                              tooltip: 'Pitch down 1 semitone',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _adjustNotePitch(
                                item.measureIndex,
                                item.noteIndex,
                                -1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.add, size: 15),
                              tooltip: 'Pitch up 1 semitone',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _adjustNotePitch(
                                item.measureIndex,
                                item.noteIndex,
                                1,
                              ),
                            ),
                            const SizedBox(width: PianoSpacing.md),
                            Text(
                              '${note.durationBeats.toStringAsFixed(2)} b',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 15,
                              ),
                              tooltip: 'Shorten by 0.25 beat',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _adjustNoteDuration(
                                item.measureIndex,
                                item.noteIndex,
                                -0.25,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 15,
                              ),
                              tooltip: 'Lengthen by 0.25 beat',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _adjustNoteDuration(
                                item.measureIndex,
                                item.noteIndex,
                                0.25,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 17,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              tooltip: 'Delete false note',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteNote(
                                item.measureIndex,
                                item.noteIndex,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _deleteNote(int measureIndex, int noteIndex) {
    final current = _level;
    if (current == null) return;
    final measures = [...current.measures];
    final targetMeasure = measures[measureIndex];
    final updatedNotes = [...targetMeasure.notes]..removeAt(noteIndex);
    measures[measureIndex] = targetMeasure.copyWith(notes: updatedNotes);
    setState(() {
      _level = current.copyWith(measures: measures);
    });
  }

  void _adjustNotePitch(int measureIndex, int noteIndex, int semitones) {
    final current = _level;
    if (current == null) return;
    final measures = [...current.measures];
    final targetMeasure = measures[measureIndex];
    final note = targetMeasure.notes[noteIndex];
    final newPitch = (note.midiNote + semitones).clamp(21, 108);
    final updatedNotes = [...targetMeasure.notes];
    updatedNotes[noteIndex] = note.copyWith(midiNote: newPitch);
    measures[measureIndex] = targetMeasure.copyWith(notes: updatedNotes);
    setState(() {
      _level = current.copyWith(measures: measures);
    });
  }

  void _adjustNoteDuration(int measureIndex, int noteIndex, double deltaBeats) {
    final current = _level;
    if (current == null) return;
    final measures = [...current.measures];
    final targetMeasure = measures[measureIndex];
    final note = targetMeasure.notes[noteIndex];
    final newDuration = (note.durationBeats + deltaBeats).clamp(0.25, 16.0);
    final updatedNotes = [...targetMeasure.notes];
    updatedNotes[noteIndex] = note.copyWith(durationBeats: newDuration);
    measures[measureIndex] = targetMeasure.copyWith(notes: updatedNotes);
    setState(() {
      _level = current.copyWith(measures: measures);
    });
  }

  static String _midiToPitchName(int midi) {
    const names = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final octave = (midi ~/ 12) - 1;
    final note = names[midi % 12];
    return '$note$octave ($midi)';
  }

  List<StaffSystem> _buildSystems(LevelModel level) {
    final placed = _buildPlacedNotes(level);
    return switch (level.clef) {
      LevelClef.bass => [(clef: Clef.bass, notes: placed)],
      LevelClef.grand => () {
        final allNotes = [
          for (final measure in level.measures) ...measure.notes,
        ];
        final hasMultiVoice = allNotes.any((n) => n.voiceIndex != 0);
        final trebleNotes = <PlacedNote>[];
        final bassNotes = <PlacedNote>[];
        for (var i = 0; i < allNotes.length && i < placed.length; i++) {
          final ln = allNotes[i];
          final pn = placed[i];
          final isBass = hasMultiVoice
              ? (ln.voiceIndex == 1)
              : (ln.midiNote < 60);
          if (isBass) {
            bassNotes.add(pn);
          } else {
            trebleNotes.add(pn);
          }
        }
        return [
          (clef: Clef.treble, notes: trebleNotes),
          (clef: Clef.bass, notes: bassNotes),
        ];
      }(),
      LevelClef.treble => [(clef: Clef.treble, notes: placed)],
    };
  }

  List<PlacedNote> _buildPlacedNotes(LevelModel level) {
    final notes = <PlacedNote>[];

    for (final measure in level.measures) {
      for (final note in measure.notes) {
        notes.add((
          midi: note.midiNote,
          startBeat: note.startBeat,
          state:
              _currentBeat >= note.startBeat &&
                  _currentBeat < note.startBeat + note.durationBeats
              ? NoteState.active
              : (_currentBeat < note.startBeat
                    ? NoteState.upcoming
                    : NoteState.missed),
        ));
      }
    }

    return notes;
  }

  Set<int> _getDueNotesAtBeat(LevelModel level, double beat) {
    final due = <int>{};

    for (final measure in level.measures) {
      for (final note in measure.notes) {
        final noteStart = note.startBeat;
        final noteEnd = noteStart + note.durationBeats;
        if (beat >= noteStart && beat < noteEnd) {
          due.add(note.midiNote);
        }
      }
    }

    return due;
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    final lvl = _level;
    if (lvl == null) return;
    final totalBeats = (lvl.totalMeasures * lvl.beatsPerMeasure).toDouble();
    const tickRate = Duration(milliseconds: 100);
    // Matches StageEngine's derivation so a preview at 1.0x plays at the
    // level's actual transcribed tempo instead of a fixed 120 BPM.
    final baseBeatsPerSecond = lvl.tempo / 60.0;

    setState(() => _isPlaying = true);
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(tickRate, (timer) {
      final prevBeat = _currentBeat;
      final nextBeat =
          _currentBeat +
          baseBeatsPerSecond * _speed * (tickRate.inMilliseconds / 1000);

      _playNotesBetween(lvl, prevBeat, nextBeat, baseBeatsPerSecond);

      setState(() {
        _currentBeat = nextBeat;
        if (_currentBeat >= totalBeats) {
          _currentBeat = totalBeats;
          _isPlaying = false;
          _synthesizer?.stop();
          timer.cancel();
        }
      });
    });
  }

  void _playNotesBetween(
    LevelModel lvl,
    double fromBeat,
    double toBeat,
    double baseBeatsPerSecond,
  ) {
    if (_isMuted) return;
    final synth = _synthesizer;
    if (synth == null) return;

    for (final measure in lvl.measures) {
      for (final note in measure.notes) {
        if (note.startBeat >= fromBeat && note.startBeat < toBeat) {
          final durSec = (note.durationBeats / baseBeatsPerSecond) / _speed;
          synth.playNote(midiNote: note.midiNote, durationSeconds: durSec);
        }
      }
    }
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _synthesizer?.stop();
    setState(() => _isPlaying = false);
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _synthesizer?.stop();
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _replay() {
    _playbackTimer?.cancel();
    _synthesizer?.stop();
    setState(() => _currentBeat = 0);
    _startPlayback();
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
  }

  Future<void> _saveLevel() async {
    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);
      await repo.saveLevel(_level!);
      if (!mounted) return;
      ref.invalidate(levelRepositoryProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Level saved successfully')));
      context.go('/');
    } on IngestionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: ${e.message}')));
    }
  }

  void _discard() {
    context.go('/import');
  }

  // Duration display uses the level's own tempo, not the current playback
  // speed, so "total time" reads as the song's real length regardless of
  // whether the learner is previewing it sped up or slowed down.
  String _formatTime(double beats, int tempo) {
    final totalSeconds = beats * (60.0 / tempo);
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ingestion_repository.dart';
import '../../data/level_repository.dart';
import '../../models/level_models.dart';
import '../../models/engine_models.dart';
import '../keyboard/piano_keyboard_view.dart';
import '../practice/transport_column.dart';
import '../staff/staff_geometry.dart' show Clef;
import '../staff/staff_painter.dart' show PlacedNote;
import '../staff/staff_view.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
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
    } catch (e) {
      // Repository methods are guarded to only throw IngestionException, but
      // this screen's own state management (mounted checks, setState) can
      // still surface a stray error here -- without this branch it would
      // leave _isLoading stuck true and an eternal spinner with no way out.
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(child: Text('Error: $_error')),
        ),
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
                      ],
                    ),
                    const SizedBox(height: PianoSpacing.lg),
                    Expanded(
                      flex: 3,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return StaffView(
                            systems: [
                              (
                                clef: Clef.treble,
                                notes: _buildPlacedNotes(level),
                              ),
                            ],
                            currentBeat: _currentBeat,
                            totalBeats: totalBeats,
                            beatsPerMeasure: level.beatsPerMeasure,
                            pixelsPerBeat: 70,
                            maxStaffHeight: constraints.maxHeight * 0.8,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: PianoSpacing.lg),
                    SizedBox(
                      height: 88,
                      child: PianoKeyboardView(
                        due: _getDueNotesAtBeat(level, _currentBeat),
                        playing: const {},
                      ),
                    ),
                    const SizedBox(height: PianoSpacing.lg),
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
                    const SizedBox(height: PianoSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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

  List<PlacedNote> _buildPlacedNotes(LevelModel level) {
    final notes = <PlacedNote>[];

    for (final measure in level.measures) {
      for (final note in measure.notes) {
        notes.add((
          midi: note.midiNote,
          startBeat: note.startBeat,
          state: _currentBeat >= note.startBeat &&
                  _currentBeat < note.startBeat + note.durationBeats
              ? NoteState.active
              : (_currentBeat < note.startBeat ? NoteState.upcoming : NoteState.missed),
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
      setState(() {
        _currentBeat +=
            baseBeatsPerSecond * _speed * (tickRate.inMilliseconds / 1000);
        if (_currentBeat >= totalBeats) {
          _currentBeat = totalBeats;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
  }

  void _replay() {
    _playbackTimer?.cancel();
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
      // LevelListScreen reads levelRepositoryProvider, which is hydrated
      // once at startup from IngestionRepository -- invalidate it so the
      // level just saved actually shows up there.
      ref.invalidate(levelRepositoryProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Level saved successfully')),
      );
      context.go('/');
    } on IngestionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.message}')),
      );
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

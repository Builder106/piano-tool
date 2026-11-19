import 'package:freezed_annotation/freezed_annotation.dart';
import 'level_models.dart';

part 'engine_models.freezed.dart';
part 'engine_models.g.dart';

/// State of a note during gameplay
enum NoteState { upcoming, active, hitPerfect, hitGood, hitOkay, missed }

/// Practice modes supported by the game engine.
enum PracticeMode {
  /// Timed mode: playhead advances with tempo, scoring timing accuracy.
  timed,

  /// Waiting mode: playhead waits at each note until the correct pitch is struck,
  /// offering contextual hints without awarding timed scores.
  waiting;

  bool get isTimed => this == timed;
  bool get isWaiting => this == waiting;
  String get label => switch (this) {
    timed => 'Play in time',
    waiting => 'Learn notes (waiting)',
  };
}

/// Hand classification for an individual note or hand assignment.
enum NoteHand {
  @JsonValue('right')
  right,
  @JsonValue('left')
  left,
  @JsonValue('unknown')
  unknown;

  bool get isRight => this == right;
  bool get isLeft => this == left;
  bool get isUnknown => this == unknown;
}

/// Target hand selection for practice.
enum HandSelection {
  @JsonValue('both')
  both,
  @JsonValue('right')
  right,
  @JsonValue('left')
  left;

  bool get isBoth => this == both;
  bool get isRight => this == right;
  bool get isLeft => this == left;

  String get label => switch (this) {
    both => 'Both hands',
    right => 'Right hand',
    left => 'Left hand',
  };

  /// Whether a voice index (0 = right hand, 1+ = left hand) matches this selection.
  bool matchesVoice(int voiceIndex) => switch (this) {
    both => true,
    right => voiceIndex == 0,
    left => voiceIndex > 0,
  };

  /// Whether a note matches this hand selection.
  bool matchesNote(LevelNote note) => matchesVoice(note.voiceIndex);
}

/// Extension providing hand assignment inspection and supported hand queries on [LevelModel].
extension LevelHandSupport on LevelModel {
  /// Whether this level has authored voice data distinguishing hands.
  bool get hasAuthoredVoices =>
      measures.any((m) => m.notes.any((n) => !n.isRest && n.voiceIndex > 0));

  /// Whether the hand assignment of notes in this level is known.
  bool get isHandAssignmentKnown => hasAuthoredVoices;

  /// Whether the hand assignment of notes in this level is unknown.
  bool get isHandAssignmentUnknown => !isHandAssignmentKnown;

  /// Returns the hands supported by this level's authored voice data.
  Set<HandSelection> get supportedHands {
    if (!isHandAssignmentKnown) {
      return const {HandSelection.both};
    }
    final hasRight = measures.any(
      (m) => m.notes.any((n) => !n.isRest && n.voiceIndex == 0),
    );
    final hasLeft = measures.any(
      (m) => m.notes.any((n) => !n.isRest && n.voiceIndex > 0),
    );
    if (hasRight && hasLeft) {
      return const {
        HandSelection.both,
        HandSelection.right,
        HandSelection.left,
      };
    } else if (hasRight) {
      return const {HandSelection.right};
    } else if (hasLeft) {
      return const {HandSelection.left};
    }
    return const {HandSelection.both};
  }

  /// Identifies the authored hand for a specific note in this level,
  /// or [NoteHand.unknown] if hand assignment is not authored/known.
  NoteHand handForNote(LevelNote note) {
    if (!isHandAssignmentKnown) return NoteHand.unknown;
    return note.voiceIndex > 0 ? NoteHand.left : NoteHand.right;
  }
}

extension LevelNoteHand on LevelNote {
  /// The hand assigned to this note based on authored voice index.
  NoteHand get hand => voiceIndex > 0 ? NoteHand.left : NoteHand.right;
}

const List<String> pitchClassNames = [
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

/// Formats a MIDI note number into scientific pitch notation (e.g. 60 -> "C4 (Middle C)" or "C4").
String formatPitch(int midiNote, {bool clarifyMiddleC = true}) {
  final name = pitchClassNames[midiNote % 12];
  final octave = (midiNote ~/ 12) - 1;
  if (clarifyMiddleC && midiNote == 60) {
    return 'C4 (Middle C)';
  }
  return '$name$octave';
}

/// Contextual hint provided when waiting for note input in waiting mode.
@freezed
sealed class WaitingHint with _$WaitingHint {
  const WaitingHint._();

  const factory WaitingHint({
    required double targetBeat,
    required List<int> targetMidiNotes,
    required String hintText,
    @Default([]) List<String> noteNames,
    int? measureIndex,
    int? beatIndex,
    int? heardWrongMidiNote,
  }) = _WaitingHint;

  factory WaitingHint.fromJson(Map<String, dynamic> json) =>
      _$WaitingHintFromJson(json);

  /// Whether the specified MIDI note matches any awaited note in this hint.
  bool matches(int midiNote) => targetMidiNotes.contains(midiNote);
}

/// Result of a note hit attempt
@freezed
sealed class NoteHitResult with _$NoteHitResult {
  const NoteHitResult._();

  const factory NoteHitResult.perfect({
    required int noteIndex,
    required double timingError, // beats (negative = early, positive = late)
  }) = _NoteHitResultPerfect;

  const factory NoteHitResult.good({
    required int noteIndex,
    required double timingError,
  }) = _NoteHitResultGood;

  const factory NoteHitResult.okay({
    required int noteIndex,
    required double timingError,
  }) = _NoteHitResultOkay;

  const factory NoteHitResult.missed({required int noteIndex}) =
      _NoteHitResultMissed;

  const factory NoteHitResult.wrongPitch({
    required int noteIndex,
    required int playedMidiNote,
    required double
    timingError, // signed beats (negative = early, positive = late)
  }) = _NoteHitResultWrongPitch;

  const factory NoteHitResult.waiting({required int noteIndex}) =
      _NoteHitResultWaiting;

  factory NoteHitResult.fromJson(Map<String, dynamic> json) =>
      _$NoteHitResultFromJson(json);

  NoteState get noteState => switch (this) {
    _NoteHitResultPerfect() => NoteState.hitPerfect,
    _NoteHitResultGood() => NoteState.hitGood,
    _NoteHitResultOkay() => NoteState.hitOkay,
    _NoteHitResultMissed() => NoteState.missed,
    _NoteHitResultWrongPitch() => NoteState.missed,
    _NoteHitResultWaiting() => NoteState.hitPerfect,
  };

  double get score => switch (this) {
    _NoteHitResultPerfect() => 100.0,
    _NoteHitResultGood() => 75.0,
    _NoteHitResultOkay() => 50.0,
    _NoteHitResultMissed() => 0.0,
    _NoteHitResultWrongPitch() => 0.0,
    _NoteHitResultWaiting() => 0.0,
  };

  /// Signed timing error in beats (negative = early, positive = late), or null if not struck with timing.
  double? get timingError => switch (this) {
    _NoteHitResultPerfect(:final timingError) => timingError,
    _NoteHitResultGood(:final timingError) => timingError,
    _NoteHitResultOkay(:final timingError) => timingError,
    _NoteHitResultWrongPitch(:final timingError) => timingError,
    _NoteHitResultMissed() => null,
    _NoteHitResultWaiting() => null,
  };

  /// MIDI pitch that was struck for a wrong pitch, or null.
  int? get playedMidiNote => switch (this) {
    _NoteHitResultWrongPitch(:final playedMidiNote) => playedMidiNote,
    _ => null,
  };

  /// Whether this note attempt was a successful hit.
  bool get isHit => switch (this) {
    _NoteHitResultPerfect() ||
    _NoteHitResultGood() ||
    _NoteHitResultOkay() ||
    _NoteHitResultWaiting() => true,
    _NoteHitResultMissed() || _NoteHitResultWrongPitch() => false,
  };

  /// Whether this note was missed due to timeout or absence of play (unplayed expected note).
  bool get isMissed => this is _NoteHitResultMissed;

  /// Whether this note was a confirmed wrong pitch.
  bool get isWrongPitch => this is _NoteHitResultWrongPitch;
}

/// Preserved detail of a completed practice attempt, including note-level results
/// and signed timing errors.
@freezed
sealed class AttemptDetail with _$AttemptDetail {
  const AttemptDetail._();

  const factory AttemptDetail({
    required int totalNotes,
    required int hitNotes,
    required int missedNotes,
    required int wrongPitchNotes,
    required double accuracy,
    required int score,
    @Default([]) List<NoteHitResult> noteResults,
    @Default({}) Map<int, NoteHitResult> noteResultsMap,
    @Default([]) List<double> signedTimingErrors,
    @Default([]) List<int> missedMeasureIndices,
    @Default([]) List<int> wrongPitchMeasureIndices,
    int? mostMissedMeasure,
  }) = _AttemptDetail;

  factory AttemptDetail.fromJson(Map<String, dynamic> json) =>
      _$AttemptDetailFromJson(json);

  /// Builds an [AttemptDetail] from raw level notes, note results, hand selection, and loop configuration.
  factory AttemptDetail.fromResults({
    required List<LevelNote> allNotes,
    required Map<int, NoteHitResult> noteResults,
    required HandSelection handSelection,
    ({double start, double end})? loop,
    int score = 0,
  }) {
    final filteredIndices = <int>[];
    for (var i = 0; i < allNotes.length; i++) {
      final note = allNotes[i];
      if (note.isRest) continue;
      if (!handSelection.matchesNote(note)) continue;
      if (loop != null) {
        if (note.startBeat < loop.start - 1e-9 || note.startBeat >= loop.end) {
          continue;
        }
      }
      filteredIndices.add(i);
    }

    final totalNotes = filteredIndices.length;
    final resultsList = <NoteHitResult>[];
    final resultsMap = <int, NoteHitResult>{};
    final timingErrors = <double>[];
    final missedMeasures = <int>{};
    final wrongPitchMeasures = <int>{};
    final errorCountsPerMeasure = <int, int>{};

    var hitCount = 0;
    var missedCount = 0;
    var wrongPitchCount = 0;

    for (final idx in filteredIndices) {
      final note = allNotes[idx];
      final res = noteResults[idx] ?? NoteHitResult.missed(noteIndex: idx);
      resultsList.add(res);
      resultsMap[idx] = res;

      final timing = res.timingError;
      if (timing != null) {
        timingErrors.add(timing);
      }

      if (res.isHit) {
        hitCount++;
      } else if (res.isWrongPitch) {
        wrongPitchCount++;
        wrongPitchMeasures.add(note.measureIndex);
        errorCountsPerMeasure[note.measureIndex] =
            (errorCountsPerMeasure[note.measureIndex] ?? 0) + 1;
      } else {
        missedCount++;
        missedMeasures.add(note.measureIndex);
        errorCountsPerMeasure[note.measureIndex] =
            (errorCountsPerMeasure[note.measureIndex] ?? 0) + 1;
      }
    }

    int? worstMeasure;
    int maxErrors = 0;
    for (final entry in errorCountsPerMeasure.entries) {
      if (entry.value > maxErrors) {
        maxErrors = entry.value;
        worstMeasure = entry.key;
      }
    }

    final accuracy = totalNotes > 0 ? hitCount / totalNotes : 0.0;

    return AttemptDetail(
      totalNotes: totalNotes,
      hitNotes: hitCount,
      missedNotes: missedCount,
      wrongPitchNotes: wrongPitchCount,
      accuracy: accuracy,
      score: score,
      noteResults: resultsList,
      noteResultsMap: resultsMap,
      signedTimingErrors: timingErrors,
      missedMeasureIndices: missedMeasures.toList()..sort(),
      wrongPitchMeasureIndices: wrongPitchMeasures.toList()..sort(),
      mostMissedMeasure: worstMeasure,
    );
  }

  /// Whether any notes were missed (either unplayed or wrong pitch).
  bool get hasErrors => missedNotes > 0 || wrongPitchNotes > 0;

  /// Total count of errors (unplayed misses + confirmed wrong pitches).
  int get totalErrors => missedNotes + wrongPitchNotes;

  /// Whether this attempt has any confirmed wrong pitches.
  bool get hasWrongPitches => wrongPitchNotes > 0;

  /// Whether this attempt has any missed expected notes (unplayed).
  bool get hasMissedExpected => missedNotes > 0;

  /// Average signed timing error in beats across all played notes with timing errors,
  /// or null if no timing errors exist.
  double? get averageTimingError => signedTimingErrors.isNotEmpty
      ? signedTimingErrors.reduce((a, b) => a + b) / signedTimingErrors.length
      : null;

  /// Whether the attempt was empty (no notes attempted).
  bool get isEmpty => totalNotes == 0;
}

/// Events emitted by the stage engine
@freezed
sealed class StageEvent with _$StageEvent {
  const factory StageEvent.noteHit({
    required int noteIndex,
    required NoteHitResult result,
    required double currentBeat,
  }) = _StageEventNoteHit;

  const factory StageEvent.noteMissed({
    required int noteIndex,
    required double currentBeat,
  }) = _StageEventNoteMissed;

  const factory StageEvent.stageCompleted({
    required double accuracy,
    required int score,
    required int totalNotes,
    required int hitNotes,
    AttemptDetail? attemptDetail,
  }) = _StageEventStageCompleted;

  const factory StageEvent.playbackPosition({
    required double currentBeat,
    required double progress, // 0.0 - 1.0
    required bool isPlaying,
  }) = _StageEventPlaybackPosition;

  const factory StageEvent.stateChanged({required StageEngineStatus state}) =
      _StageEventStateChanged;

  const factory StageEvent.beat({
    required double beat,
    required MetronomeBeatType beatType,
    required int measureIndex,
    required int beatInMeasure,
    @Default(false) bool isCountIn,
  }) = _StageEventBeat;

  const factory StageEvent.loopPassCompleted({
    required double accuracy,
    required int score,
    required int totalNotes,
    required int hitNotes,
    required double loopStartBeat,
    required double loopEndBeat,
    AttemptDetail? attemptDetail,
  }) = _StageEventLoopPassCompleted;

  factory StageEvent.fromJson(Map<String, dynamic> json) =>
      _$StageEventFromJson(json);
}

/// Beat emphasis classification for metronome and beat references.
enum MetronomeBeatType {
  /// First beat of a measure (strong primary accent).
  downbeat,

  /// Secondary accent in compound or complex meters (e.g. beat 4 in 6/8 meter).
  secondaryAccent,

  /// Regular pulse in simple meter (e.g. beats 2, 3, 4 in 4/4).
  regular,

  /// Subdivision or weak pulse in compound meter (e.g. eighth notes 2, 3, 5, 6 in 6/8).
  subdivision,
}

/// Stage engine state (enum for internal state machine)
enum StageEngineStatus { idle, playing, paused, completed, stopped }

/// Configuration for the stage engine
@freezed
sealed class StageEngineConfig with _$StageEngineConfig {
  const factory StageEngineConfig({
    @Default(0.1)
    double perfectWindow, // beats (early/late tolerance for perfect)
    @Default(0.2) double goodWindow, // beats for good
    @Default(0.3) double okayWindow, // beats for okay
    @Default(0.5) double missWindow, // beats after which note is missed
    @Default(true) bool autoAdvance, // auto-advance playhead
    @Default(1.0) double playbackSpeed, // speed multiplier
    @Default(0.0)
    double inputLatency, // seconds of input/buffer latency compensation
    @Default(PracticeMode.timed) PracticeMode practiceMode,
    @Default(false) bool metronomeEnabled,
    @Default(false) bool countInEnabled,
    @Default(HandSelection.both) HandSelection handSelection,
  }) = _StageEngineConfig;

  factory StageEngineConfig.fromJson(Map<String, dynamic> json) =>
      _$StageEngineConfigFromJson(json);
}

/// Current state of the stage engine
@freezed
sealed class StageEngineStateModel with _$StageEngineStateModel {
  const StageEngineStateModel._();

  const factory StageEngineStateModel({
    required StageEngineStatus engineState,
    required LevelModel level,
    required double currentBeat,
    required List<NoteState> noteStates,
    required int score,
    required int hitCount,
    required int missCount,
    @Default(0) int perfectCount,
    @Default(0) int goodCount,
    @Default(0) int okayCount,
    @Default(PracticeMode.timed) PracticeMode practiceMode,
    @Default(null) WaitingHint? waitingHint,
    @Default(false) bool isCountingIn,
    int? countInBeat,
    @Default(HandSelection.both) HandSelection handSelection,
    @Default({}) Map<int, NoteHitResult> noteResults,
    @Default(null) AttemptDetail? attemptDetail,
  }) = _StageEngineStateModel;

  factory StageEngineStateModel.fromJson(Map<String, dynamic> json) =>
      _$StageEngineStateModelFromJson(json);

  bool get isWaitingMode => practiceMode == PracticeMode.waiting;
  bool get isTimedMode => practiceMode == PracticeMode.timed;

  double get progress => level.totalMeasures > 0
      ? (currentBeat / (level.totalMeasures * level.beatsPerMeasure)).clamp(
          0.0,
          1.0,
        )
      : 0.0;

  double get accuracy =>
      (hitCount + missCount) > 0 ? hitCount / (hitCount + missCount) : 0.0;
}

/// Provider state for the current game
@freezed
sealed class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    @Default(null) StageModel? currentStage,
    @Default(null) LevelModel? currentLevel,
    @Default(StageEngineStatus.idle) StageEngineStatus engineState,
    @Default(0.0) double currentBeat,
    @Default(0) int score,
    @Default(0.0) double accuracy,
    @Default(1.0) double playbackSpeed,
  }) = _GameState;

  factory GameState.initial() => const GameState();
}

/// Assistance offered to the learner after repeated unsuccessful attempts.
@freezed
sealed class AssistanceOffer with _$AssistanceOffer {
  const AssistanceOffer._();

  const factory AssistanceOffer({
    required int unsuccessfulAttempts,
    required double currentSpeed,
    double? suggestedSpeed,
    int? currentStartMeasure,
    int? currentEndMeasure,
    int? suggestedStartMeasure,
    int? suggestedEndMeasure,
    int? mostMissedMeasure,
    required String reason,
    required String message,
  }) = _AssistanceOffer;

  factory AssistanceOffer.fromJson(Map<String, dynamic> json) =>
      _$AssistanceOfferFromJson(json);

  /// Current loop measure range at the time of the offer, or null for whole piece.
  (int, int)? get currentLoopRange =>
      currentStartMeasure != null && currentEndMeasure != null
      ? (currentStartMeasure!, currentEndMeasure!)
      : null;

  /// Suggested shorter phrase loop range, or null if no shorter phrase is applicable.
  (int, int)? get suggestedLoopRange =>
      suggestedStartMeasure != null && suggestedEndMeasure != null
      ? (suggestedStartMeasure!, suggestedEndMeasure!)
      : null;

  /// Whether a slower playback speed is suggested.
  bool get hasSlowerSpeed =>
      suggestedSpeed != null && suggestedSpeed! < currentSpeed;

  /// Whether a shorter phrase range is suggested.
  bool get hasShorterPhrase =>
      suggestedStartMeasure != null && suggestedEndMeasure != null;
}

/// Active assistance settings and the baseline configuration needed to revert cleanly.
@freezed
sealed class AppliedAssistance with _$AppliedAssistance {
  const AppliedAssistance._();

  const factory AppliedAssistance({
    required double originalSpeed,
    int? originalStartMeasure,
    int? originalEndMeasure,
    double? assistedSpeed,
    int? assistedStartMeasure,
    int? assistedEndMeasure,
  }) = _AppliedAssistance;

  factory AppliedAssistance.fromJson(Map<String, dynamic> json) =>
      _$AppliedAssistanceFromJson(json);

  /// Baseline loop measure range prior to applying assistance, or null if whole piece.
  (int, int)? get originalLoopRange =>
      originalStartMeasure != null && originalEndMeasure != null
      ? (originalStartMeasure!, originalEndMeasure!)
      : null;

  /// Active assisted loop measure range, or null if loop was not modified.
  (int, int)? get assistedLoopRange =>
      assistedStartMeasure != null && assistedEndMeasure != null
      ? (assistedStartMeasure!, assistedEndMeasure!)
      : null;

  /// Whether playback speed was modified by assistance.
  bool get isSpeedAssisted =>
      assistedSpeed != null && (assistedSpeed! - originalSpeed).abs() > 0.001;

  /// Whether phrase / loop range was modified by assistance.
  bool get isPhraseAssisted =>
      assistedStartMeasure != null &&
      (assistedStartMeasure != originalStartMeasure ||
          assistedEndMeasure != originalEndMeasure);
}

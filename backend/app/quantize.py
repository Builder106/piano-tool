import math
from dataclasses import dataclass

from app.models import LevelClef, LevelMeasure, LevelModel, LevelNote

SIXTEENTH_NOTE_BEATS = 0.25
MIN_DURATION_BEATS = 0.25


@dataclass
class NoteEvent:
    pitch: int
    start: float
    end: float
    velocity: int


def _snap(value_beats: float, snap_unit: float = SIXTEENTH_NOTE_BEATS) -> float:
    return round(value_beats / snap_unit) * snap_unit


def detect_meter(
    note_events: list[NoteEvent],
    tempo_bpm: float,
) -> tuple[int, int]:
    """Detect musical meter (beats_per_measure, beat_unit) from note onsets.

    Supports 4/4 (common time), 3/4 (triple/waltz time), and 6/8 (compound duple).
    """
    if not note_events or tempo_bpm <= 0:
        return (4, 4)

    seconds_per_beat = 60.0 / tempo_bpm
    onsets_in_beats = [event.start / seconds_per_beat for event in note_events]

    # Check for compound 6/8 triplet subdivision feel:
    # In compound meters with dotted-quarter tempo, subdivisions cluster around thirds
    triplet_count = 0
    total_non_integer = 0
    for beat in onsets_in_beats:
        frac = beat - math.floor(beat)
        if 0.05 < frac < 0.95:
            total_non_integer += 1
            dist_triplet = min(abs(frac - 1 / 3), abs(frac - 2 / 3))
            dist_duple = min(abs(frac - 0.25), abs(frac - 0.5), abs(frac - 0.75))
            if dist_triplet < dist_duple and dist_triplet < 0.10:
                triplet_count += 1

    if total_non_integer >= 3 and (triplet_count / total_non_integer) > 0.45:
        return (6, 8)

    # Score downbeat periodicity for 3/4 vs 4/4
    def measure_alignment_score(period: int) -> float:
        score = 0.0
        for event, beat in zip(note_events, onsets_in_beats, strict=False):
            phase = beat % period
            dist_to_downbeat = min(phase, period - phase)
            if dist_to_downbeat < 0.20:
                weight = event.velocity / 100.0
                if event.pitch < 60:
                    weight *= 1.5
                score += weight
        return score

    score_3 = measure_alignment_score(3)
    score_4 = measure_alignment_score(4)

    # Require 3/4 score to clearly beat 4/4 to avoid false positives on sparse 4/4
    if score_3 > score_4 * 1.2 and score_3 >= 1.5:
        return (3, 4)

    return (4, 4)


def _infer_clef(note_events: list[NoteEvent]) -> LevelClef:
    if not note_events:
        return LevelClef.treble
    has_bass = any(e.pitch < 60 for e in note_events)
    has_treble = any(e.pitch >= 60 for e in note_events)
    if has_bass and has_treble:
        return LevelClef.grand
    if has_bass:
        return LevelClef.bass
    return LevelClef.treble


def quantize_notes(  # noqa: PLR0913
    note_events: list[NoteEvent],
    tempo_bpm: float,
    level_id: str,
    title: str,
    beats_per_measure: int | None = None,
    beat_unit: int | None = None,
    clef: LevelClef | None = None,
) -> LevelModel:
    if tempo_bpm <= 0:
        raise ValueError("tempo_bpm must be positive")

    if beats_per_measure is None:
        detected_beats, detected_unit = detect_meter(note_events, tempo_bpm)
        beats_per_measure = detected_beats
        if beat_unit is None:
            beat_unit = detected_unit
    elif beat_unit is None:
        beat_unit = 8 if beats_per_measure == 6 else 4

    if clef is None:
        clef = _infer_clef(note_events)

    seconds_per_beat = 60.0 / tempo_bpm
    snap_unit = 0.5 if beat_unit == 8 else SIXTEENTH_NOTE_BEATS
    min_dur = 0.5 if beat_unit == 8 else MIN_DURATION_BEATS

    placed: list[tuple[int, float, float]] = []
    for event in note_events:
        start_beat = _snap(event.start / seconds_per_beat, snap_unit)
        raw_duration_beats = (event.end - event.start) / seconds_per_beat
        duration_beats = max(_snap(raw_duration_beats, snap_unit), min_dur)
        placed.append((event.pitch, start_beat, duration_beats))

    if not placed:
        return LevelModel(
            id=level_id,
            title=title,
            description="Imported from audio",
            tempo=round(tempo_bpm),
            beatsPerMeasure=beats_per_measure,
            beatUnit=beat_unit,
            clef=clef,
            totalMeasures=0,
            measures=[],
        )

    last_measure_index = max(int(start_beat // beats_per_measure) for _, start_beat, _ in placed)
    measures: list[LevelMeasure] = []
    for measure_index in range(last_measure_index + 1):
        measure_start_beat = float(measure_index * beats_per_measure)
        measure_end_beat = measure_start_beat + beats_per_measure
        notes_in_measure = [
            LevelNote(
                midiNote=pitch,
                startBeat=start_beat,
                durationBeats=duration_beats,
                measureIndex=measure_index,
                beatIndex=math.floor(start_beat - measure_start_beat),
                voiceIndex=1 if (clef == LevelClef.grand and pitch < 60) else 0,
            )
            for pitch, start_beat, duration_beats in placed
            if measure_start_beat <= start_beat < measure_end_beat
        ]
        measures.append(
            LevelMeasure(
                index=measure_index,
                startBeat=measure_start_beat,
                beatsPerMeasure=beats_per_measure,
                notes=notes_in_measure,
            )
        )

    return LevelModel(
        id=level_id,
        title=title,
        description="Imported from audio",
        tempo=round(tempo_bpm),
        beatsPerMeasure=beats_per_measure,
        beatUnit=beat_unit,
        clef=clef,
        totalMeasures=len(measures),
        measures=measures,
    )

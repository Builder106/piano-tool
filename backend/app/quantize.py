import math
from dataclasses import dataclass

from app.models import LevelMeasure, LevelModel, LevelNote

SIXTEENTH_NOTE_BEATS = 0.25
MIN_DURATION_BEATS = 0.25


@dataclass
class NoteEvent:
    pitch: int
    start: float
    end: float
    velocity: int


def _snap(value_beats: float) -> float:
    return round(value_beats / SIXTEENTH_NOTE_BEATS) * SIXTEENTH_NOTE_BEATS


def quantize_notes(
    note_events: list[NoteEvent],
    tempo_bpm: float,
    level_id: str,
    title: str,
    beats_per_measure: int = 4,
) -> LevelModel:
    if tempo_bpm <= 0:
        raise ValueError("tempo_bpm must be positive")

    seconds_per_beat = 60.0 / tempo_bpm
    placed: list[tuple[int, float, float]] = []
    for event in note_events:
        start_beat = _snap(event.start / seconds_per_beat)
        raw_duration_beats = (event.end - event.start) / seconds_per_beat
        duration_beats = max(_snap(raw_duration_beats), MIN_DURATION_BEATS)
        placed.append((event.pitch, start_beat, duration_beats))

    if not placed:
        return LevelModel(
            id=level_id,
            title=title,
            description="Imported from audio",
            tempo=round(tempo_bpm),
            beatsPerMeasure=beats_per_measure,
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
        totalMeasures=len(measures),
        measures=measures,
    )

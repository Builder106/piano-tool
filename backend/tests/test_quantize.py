from app.quantize import NoteEvent, quantize_notes


def test_a_single_note_lands_on_the_expected_beat():
    # At 120 bpm, a note starting at 1.0s starts on beat 2.0.
    events = [NoteEvent(pitch=60, start=1.0, end=1.5, velocity=80)]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    note = level.measures[0].notes[0]
    assert note.midi_note == 60
    assert note.start_beat == 2.0


def test_a_very_short_note_is_bumped_to_the_minimum_duration():
    # At 120 bpm, a 0.05s note is far shorter than a 16th note (0.125s) and
    # must not collapse to zero duration.
    events = [NoteEvent(pitch=60, start=0.0, end=0.05, velocity=80)]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.measures[0].notes[0].duration_beats == 0.25


def test_notes_are_assigned_to_the_correct_measure():
    # At 120 bpm (0.5s/beat), beat 4.0 is the first beat of measure 1
    # (0-indexed, 4 beats per measure).
    events = [
        NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80),  # beat 0, measure 0
        NoteEvent(pitch=62, start=2.0, end=2.5, velocity=80),  # beat 4, measure 1
    ]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.total_measures == 2
    assert level.measures[0].notes[0].measure_index == 0
    assert level.measures[1].notes[0].measure_index == 1
    assert level.measures[1].notes[0].beat_index == 0


def test_overlapping_notes_are_all_preserved_as_a_chord():
    events = [
        NoteEvent(pitch=60, start=0.0, end=1.0, velocity=80),
        NoteEvent(pitch=64, start=0.0, end=1.0, velocity=70),
        NoteEvent(pitch=67, start=0.0, end=1.0, velocity=75),
    ]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="lvl", title="T")

    pitches = {n.midi_note for n in level.measures[0].notes}
    assert pitches == {60, 64, 67}


def test_no_notes_produces_an_empty_level():
    level = quantize_notes([], tempo_bpm=120.0, level_id="lvl", title="T")

    assert level.total_measures == 0
    assert level.measures == []


def test_a_non_positive_tempo_is_rejected():
    import pytest

    with pytest.raises(ValueError):
        quantize_notes(
            [NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80)],
            tempo_bpm=0.0,
            level_id="lvl",
            title="T",
        )

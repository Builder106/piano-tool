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


def test_quantize_with_explicit_three_four_meter():
    # 3/4 waltz: 3 beats per measure, at 120 bpm (0.5s per beat)
    # Beat 0, 1, 2 = measure 0; Beat 3 = measure 1
    events = [
        NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80),  # beat 0, measure 0
        NoteEvent(pitch=64, start=0.5, end=1.0, velocity=70),  # beat 1, measure 0
        NoteEvent(pitch=67, start=1.0, end=1.5, velocity=70),  # beat 2, measure 0
        NoteEvent(pitch=62, start=1.5, end=2.0, velocity=80),  # beat 3, measure 1
    ]

    level = quantize_notes(
        events,
        tempo_bpm=120.0,
        level_id="lvl_3_4",
        title="Waltz",
        beats_per_measure=3,
        beat_unit=4,
    )

    assert level.beats_per_measure == 3
    assert level.beat_unit == 4
    assert level.total_measures == 2
    assert len(level.measures[0].notes) == 3
    assert len(level.measures[1].notes) == 1
    assert level.measures[1].notes[0].start_beat == 3.0


def test_quantize_with_explicit_six_eight_meter():
    # 6/8 compound meter: 6 beats per measure, beatUnit = 8
    events = [
        NoteEvent(pitch=60, start=0.0, end=0.5, velocity=80),
        NoteEvent(pitch=64, start=1.5, end=2.0, velocity=70),  # beat 3 in measure 0
        NoteEvent(pitch=67, start=3.0, end=3.5, velocity=80),  # beat 6 -> measure 1
    ]

    level = quantize_notes(
        events,
        tempo_bpm=120.0,
        level_id="lvl_6_8",
        title="Compound Study",
        beats_per_measure=6,
        beat_unit=8,
    )

    assert level.beats_per_measure == 6
    assert level.beat_unit == 8
    assert level.total_measures == 2
    assert level.measures[0].notes[0].measure_index == 0
    assert level.measures[1].notes[0].measure_index == 1
    assert level.measures[1].notes[0].start_beat == 6.0


def test_detect_meter_waltz_three_four():
    from app.quantize import detect_meter

    # 120 bpm = 0.5s per beat. Strong downbeats at beats 0, 3, 6, 9
    events = [
        # Measure 0 (beats 0, 1, 2)
        NoteEvent(pitch=48, start=0.0, end=0.5, velocity=90),
        NoteEvent(pitch=64, start=0.5, end=1.0, velocity=60),
        NoteEvent(pitch=67, start=1.0, end=1.5, velocity=60),
        # Measure 1 (beats 3, 4, 5)
        NoteEvent(pitch=48, start=1.5, end=2.0, velocity=90),
        NoteEvent(pitch=64, start=2.0, end=2.5, velocity=60),
        NoteEvent(pitch=67, start=2.5, end=3.0, velocity=60),
        # Measure 2 (beats 6, 7, 8)
        NoteEvent(pitch=53, start=3.0, end=3.5, velocity=90),
        NoteEvent(pitch=65, start=3.5, end=4.0, velocity=60),
        NoteEvent(pitch=69, start=4.0, end=4.5, velocity=60),
        # Measure 3 (beats 9, 10, 11)
        NoteEvent(pitch=48, start=4.5, end=5.0, velocity=90),
        NoteEvent(pitch=64, start=5.0, end=5.5, velocity=60),
        NoteEvent(pitch=67, start=5.5, end=6.0, velocity=60),
    ]

    meter = detect_meter(events, tempo_bpm=120.0)
    assert meter == (3, 4)


def test_detect_meter_compound_six_eight():
    from app.quantize import detect_meter

    # In compound 6/8 with dotted quarter beat at 120 bpm (0.5s per dotted beat)
    # Eighth notes land at 1/3 and 2/3 of a beat
    events = [
        NoteEvent(pitch=60, start=0.0, end=0.15, velocity=80),
        NoteEvent(pitch=64, start=0.5 / 3.0, end=0.30, velocity=70),
        NoteEvent(pitch=67, start=1.0 / 3.0, end=0.45, velocity=70),
        NoteEvent(pitch=60, start=0.5, end=0.65, velocity=80),
        NoteEvent(pitch=64, start=0.5 + 0.5 / 3.0, end=0.80, velocity=70),
        NoteEvent(pitch=67, start=0.5 + 1.0 / 3.0, end=0.95, velocity=70),
    ]

    meter = detect_meter(events, tempo_bpm=120.0)
    assert meter == (6, 8)


def test_automatic_clef_assignment_for_grand_staff():
    from app.models import LevelClef

    # Notes spanning bass (MIDI < 60) and treble (MIDI >= 60)
    events = [
        NoteEvent(pitch=48, start=0.0, end=1.0, velocity=80),  # C3 bass
        NoteEvent(pitch=64, start=0.0, end=1.0, velocity=80),  # E4 treble
    ]

    level = quantize_notes(events, tempo_bpm=120.0, level_id="grand_lvl", title="Grand")
    assert level.clef == LevelClef.grand
    # Left-hand bass note assigned voice 1, treble assigned voice 0
    notes = level.measures[0].notes
    assert len(notes) == 2
    assert {n.voice_index for n in notes} == {0, 1}

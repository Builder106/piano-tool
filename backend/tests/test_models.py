from app.models import LevelMeasure, LevelModel, LevelNote


def test_level_note_serializes_with_camel_case_keys():
    note = LevelNote(
        midi_note=60,
        start_beat=0.0,
        duration_beats=1.0,
        measure_index=0,
        beat_index=0,
    )

    data = note.model_dump(by_alias=True)

    assert data == {
        "midiNote": 60,
        "startBeat": 0.0,
        "durationBeats": 1.0,
        "measureIndex": 0,
        "beatIndex": 0,
        "isRest": False,
        "voiceIndex": 0,
    }


def test_level_model_serializes_nested_structure_with_camel_case_keys():
    note = LevelNote(
        midi_note=64, start_beat=1.0, duration_beats=1.0, measure_index=0, beat_index=1
    )
    measure = LevelMeasure(index=0, start_beat=0.0, beats_per_measure=4, notes=[note])
    level = LevelModel(
        id="level_test",
        title="Test Level",
        description="A test level",
        tempo=80,
        beats_per_measure=4,
        total_measures=1,
        measures=[measure],
    )

    data = level.model_dump(by_alias=True)

    assert data["beatsPerMeasure"] == 4
    assert data["totalMeasures"] == 1
    assert data["clefOctave"] == 4
    assert data["transpose"] == 0
    assert data["measures"][0]["startBeat"] == 0.0
    assert data["measures"][0]["notes"][0]["midiNote"] == 64


def test_level_model_round_trips_from_camel_case_json():
    payload = {
        "id": "level_x",
        "title": "X",
        "description": "d",
        "tempo": 100,
        "beatsPerMeasure": 4,
        "totalMeasures": 0,
        "measures": [],
    }

    level = LevelModel.model_validate(payload)

    assert level.beats_per_measure == 4
    assert level.total_measures == 0

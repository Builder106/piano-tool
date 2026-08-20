from pydantic import BaseModel, ConfigDict, Field


class LevelNote(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    midi_note: int = Field(alias="midiNote")
    start_beat: float = Field(alias="startBeat")
    duration_beats: float = Field(alias="durationBeats")
    measure_index: int = Field(alias="measureIndex")
    beat_index: int = Field(alias="beatIndex")
    is_rest: bool = Field(default=False, alias="isRest")
    voice_index: int = Field(default=0, alias="voiceIndex")


class LevelMeasure(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    index: int
    start_beat: float = Field(alias="startBeat")
    beats_per_measure: int = Field(alias="beatsPerMeasure")
    notes: list[LevelNote] = Field(default_factory=list)


class LevelModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: str
    title: str
    description: str
    tempo: int
    beats_per_measure: int = Field(alias="beatsPerMeasure")
    total_measures: int = Field(alias="totalMeasures")
    measures: list[LevelMeasure]
    clef_octave: int = Field(default=4, alias="clefOctave")
    transpose: int = Field(default=0, alias="transpose")

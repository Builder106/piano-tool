# Piano-Tool Roadmap

Interactive piano practice tutor with real-time pitch detection and audio ingestion roadmap.

## v1.1 — Practice Polish & Settings

- **Settings & Calibration Screen**: Pitch detection tolerance calibration, default tempo, light/dark theme toggle, backend endpoint/token management, and audio hardware diagnostics per [`docs/specs/2026-08-17-ui-revamp-design.md`](docs/specs/2026-08-17-ui-revamp-design.md).
- **Home Navigation & Continue Hub**: Dedicated root landing route (`/`) with a "Continue Practice" card, recent level progress, and quick import triggers.
- **Audio Review Synthesizer**: Auditory playback during `ReviewScreen` preview so learners can audibly evaluate transcription quality before saving.
- **SMuFL Glyph Polish**: Native Bravura time-signature glyphs and visual differentiation for hit timing quality (`hitPerfect`, `hitGood`, `hitOkay`).

## v1.2 — Musical Notation & Meter Expansion

- **Grand Staff & Bass Clef Support**: Two-system grand staff notation, brace glyphs, and bass clef level models for two-handed practice.
- **Variable Meter Detection**: Quantizer support for 3/4, 6/8, and compound meters in `backend/app/quantize.py` instead of fixed 4/4.
- **Note-Level Ingestion Correction**: In-app mini piano-roll or note trimming interface in `ReviewScreen` to correct false note detections prior to persistence.
- **USB / Bluetooth MIDI Input**: Direct digital piano keyboard connectivity via Web MIDI / CoreMIDI / Android MIDI alongside acoustic microphone listening.

## v2.0 — Sheet Music OMR & Advanced Ingestion

- **Optical Music Recognition (OMR)**: Photograph- and scan-to-level pipeline via Audiveris/MusicXML transcription on `ampere-dev`, expanding on the initial feasibility spike.
- **Source Separation Pipeline**: Multi-track stem separation (e.g., Demucs) to isolate piano tracks from mixed recordings prior to Basic Pitch inference.
- **Targeted Practice Modes**: Measure loop-region drills, spaced repetition practice tracking, and ear-training interval modes.

## Out of Scope

- Real-time client-side neural transcription (Basic Pitch stays on persistent Linux VM backend).
- Public cloud multi-tenant hosting (stays single-user private infrastructure).
- Commercial gamified microtransactions or public social leaderboards.

---
For technical specifications, see [`docs/specs/`](docs/specs/).

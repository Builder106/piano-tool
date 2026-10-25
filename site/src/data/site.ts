// Every visible string and every unit of the site.
// Assumptions to confirm before shipping:
// - `site.url` is a placeholder production URL; canonical links, OG and the sitemap use it.
// Facts come from the app's source: lib/data/level_repository.dart (stage one),
// lib/audio/pitch_detector.dart and lib/models/audio_models.dart (YIN and its gates),
// lib/ui/staff/note_glyph.dart and staff_geometry.dart (glyphs), lib/data/settings_repository.dart
// (tolerance windows), lib/services/midi_service.dart, backend/app/quantize.py.

export const site = {
  name: 'Piano Tool',
  url: 'https://piano-tool-site.vercel.app',
  description:
    'Piano Tool is a practice tutor that listens to your piano through the microphone or MIDI and marks every note you play, with how close you were to the beat.',
  repo: 'https://github.com/Builder106/piano-tool',
  webApp: 'https://piano-tool.vercel.app',
  author: 'Olayinka Vaughan',
  stage: { number: 1, title: 'C major scale', tempo: 80, beatsPerMeasure: 4 },
};

export type Unit = {
  midi: number;
  note: string;
  route: string;
  /** The page heading. */
  title: string;
  /** Short label used in the score and the next-note cue. */
  label: string;
  /** Meta description, 120 to 160 characters. */
  description: string;
  /** Computer key that plays this note. */
  key: string;
  measure: number;
  beat: number;
};

export const units: Unit[] = [
  {
    midi: 60, note: 'C4', route: '/', title: 'Piano Tool', label: 'What it is', key: 'A', measure: 1, beat: 1,
    description: site.description,
  },
  {
    midi: 62, note: 'D4', route: '/listening/', title: 'It listens.', label: 'It listens', key: 'S', measure: 1, beat: 2,
    description: 'How Piano Tool hears an acoustic piano: the YIN pitch estimator on 2,048 sample buffers, with a live version that runs on your own microphone.',
  },
  {
    midi: 64, note: 'E4', route: '/staff/', title: 'Measured in staff spaces.', label: 'Measured in staff spaces', key: 'D', measure: 1, beat: 3,
    description: 'Every glyph on the Piano Tool staff is sized from one number, the staff space, which is why a grand staff for two hands needed no new drawing code.',
  },
  {
    midi: 65, note: 'F4', route: '/shape/', title: 'Shape before colour.', label: 'Shape before colour', key: 'F', measure: 1, beat: 4,
    description: 'Piano Tool draws a note as hollow, ringed, filled or struck through, so hits and misses still read for players with red-green colour blindness.',
  },
  {
    midi: 67, note: 'G4', route: '/timing/', title: 'Early, late, on the beat.', label: 'Early, late, on the beat', key: 'G', measure: 2, beat: 1,
    description: 'The timing windows Piano Tool uses to grade a note perfect, good, okay or missed, with a tap test at the stage one tempo of 80 beats a minute.',
  },
  {
    midi: 69, note: 'A4', route: '/midi/', title: 'Or plug the piano in.', label: 'Or plug the piano in', key: 'H', measure: 2, beat: 2,
    description: 'Piano Tool reads USB and Bluetooth MIDI keyboards: a three byte Note On message becomes a pitch event with full confidence, beside or instead of the microphone.',
  },
  {
    midi: 71, note: 'B4', route: '/import/', title: 'A recording becomes a level.', label: 'A recording becomes a level', key: 'J', measure: 2, beat: 3,
    description: 'Piano Tool turns a recording or a YouTube link into a practice level with Basic Pitch, a beat quantiser, meter detection and a note by note review.',
  },
  {
    midi: 72, note: 'C5', route: '/play/', title: 'The octave.', label: 'Get the app', key: 'K', measure: 2, beat: 4,
    description: 'Stage one ends on C5. Run Piano Tool from source with Flutter on Android, iOS, macOS, Windows, Linux or the web, or try the web build.',
  },
];

/** Black keys inside the stage octave: playable, not part of the stage. */
export const blackKeys: { midi: number; note: string; key: string }[] = [
  { midi: 61, note: 'C sharp 4', key: 'W' },
  { midi: 63, note: 'D sharp 4', key: 'E' },
  { midi: 66, note: 'F sharp 4', key: 'T' },
  { midi: 68, note: 'G sharp 4', key: 'Y' },
  { midi: 70, note: 'A sharp 4', key: 'U' },
];

export const unitByMidi = new Map(units.map((u) => [u.midi, u]));
export const unitByRoute = new Map(units.map((u) => [u.route, u]));

export function nextUnit(u: Unit) {
  const i = units.indexOf(u);
  return units[(i + 1) % units.length]!;
}
export function prevUnit(u: Unit) {
  const i = units.indexOf(u);
  return i > 0 ? units[i - 1]! : null;
}

const NAMES = ['C', 'C sharp ', 'D', 'D sharp ', 'E', 'F', 'F sharp ', 'G', 'G sharp ', 'A', 'A sharp ', 'B'];
/** Note name for any MIDI number, e.g. 61 → "C sharp 4". */
export function noteName(midi: number) {
  return `${NAMES[midi % 12]}${Math.floor(midi / 12) - 1}`;
}

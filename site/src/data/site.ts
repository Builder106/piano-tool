// Every unit of the site. The site is for people starting piano, and it sells the app: each page
// is one thing a learner gets, in plain words. Facts come from the app's source:
// lib/data/level_repository.dart (the three stages), lib/audio/ (microphone listening),
// lib/ui/staff/note_glyph.dart (note marks), lib/data/settings_repository.dart (timing windows),
// lib/ui/practice/transport_column.dart (speeds 0.5x to 2x), lib/services/midi_service.dart.

export const site = {
  name: 'Piano Tool',
  url: 'https://piano-tool.vercel.app',
  description:
    "Piano Tool listens while you play a real piano and marks every note, so you can see what you got right. It's free to try in your browser.",
  repo: 'https://github.com/Builder106/piano-tool',
  webApp: '/app/',
  author: 'Olayinka Vaughan',
  stage: { number: 1, title: 'C major scale', tempo: 80, beatsPerMeasure: 4 },
};

export type Unit = {
  midi: number;
  note: string;
  route: string;
  /** The page heading. */
  title: string;
  /** Short label used in the score and the page links. */
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
    midi: 60, note: 'C4', route: '/tour/', title: 'Piano Tool', label: 'Start here', key: 'A', measure: 1, beat: 1,
    description: site.description,
  },
  {
    midi: 62, note: 'D4', route: '/listens/', title: 'It listens to your piano.', label: 'It listens', key: 'S', measure: 1, beat: 2,
    description: "Piano Tool listens to your piano through your phone or tablet's microphone. An upright, a grand or a keyboard all work, with nothing to plug in.",
  },
  {
    midi: 64, note: 'E4', route: '/marks/', title: 'Every note gets a mark.', label: 'Every note gets a mark', key: 'D', measure: 1, beat: 3,
    description: 'As you play, Piano Tool fills in each note you hit and strikes through each one you miss, so you can see exactly what to practise next.',
  },
  {
    midi: 65, note: 'F4', route: '/timing/', title: 'Right on time.', label: 'Right on time', key: 'F', measure: 1, beat: 4,
    description: 'Piano Tool marks each note perfect, good or okay by how close to the beat you play it, which is how you learn a steady pulse. Tap along here.',
  },
  {
    midi: 67, note: 'G4', route: '/slow-down/', title: 'Slow it down.', label: 'Slow it down', key: 'G', measure: 2, beat: 1,
    description: 'Play any Piano Tool piece at half speed while you learn it, then build back up. The beat slows with you, and your timing is checked against it.',
  },
  {
    midi: 69, note: 'A4', route: '/plug-in/', title: 'Got a digital piano?', label: 'Got a digital piano?', key: 'H', measure: 2, beat: 2,
    description: 'Have a digital piano? Connect it to Piano Tool over USB or Bluetooth and the app reads every key you press straight from the keyboard.',
  },
  {
    midi: 71, note: 'B4', route: '/stages/', title: 'One step at a time.', label: 'One step at a time', key: 'J', measure: 2, beat: 3,
    description: "Piano Tool starts with a C major scale, then opens a simple tune and a rhythm piece as you go. Your scores are saved, and you can see how far you've come.",
  },
  {
    midi: 72, note: 'C5', route: '/play/', title: "That's a scale.", label: 'Try Piano Tool', key: 'K', measure: 2, beat: 4,
    description: 'You just played a C major scale. Piano Tool is free: try it in your browser now and practise stage one with a scrolling score.',
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

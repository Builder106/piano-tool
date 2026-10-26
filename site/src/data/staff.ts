// Stage one engraving. Every vertical size follows the staff space.
import { units } from './site';

export const VIEW = { w: 840, h: 272 };
export const SPACE = 24;
export const TOP = 62;
export const LINES = [0, 1, 2, 3, 4].map((i) => TOP + i * SPACE);
export const BOTTOM = LINES[4]!;
export const G_LINE = LINES[3]!;
export const HEAD = { rx: SPACE * 0.65, ry: SPACE * 0.5, tilt: -20.05 };
export const RING_R = SPACE * 1.3 * 0.72;
export const STEM = { length: SPACE * 3.5, width: SPACE * 0.12 };
export const STROKE = SPACE * 0.18;
export const STRIKE = { r: SPACE * 1.3 * 0.85, angle: -0.6, width: SPACE * 0.16 };

const DIATONIC = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
const diatonic = (midi: number) => Math.floor(midi / 12) * 7 + DIATONIC[midi % 12]!;
export const noteY = (midi: number) => BOTTOM - (diatonic(midi) - diatonic(64)) * SPACE / 2;

// Rows under the staff, as a teacher writes them: the letter name of every note, then the word
// left beside a note once it is played. The arrow to the annotation starts under those rows.
export const LETTER_Y = BOTTOM + SPACE * 2.3;
export const WORD_Y = LETTER_Y + SPACE * 0.85;
export const ARROW_Y = WORD_Y + SPACE * 0.3;

// The first head starts after the clef, time signature, and breathing room.
const CLEF_WIDTH = 96;
const TIME_WIDTH = 40;
const HEADER_PAD = 48;
export const NOTE_START = CLEF_WIDTH + TIME_WIDTH + HEADER_PAD;
export const SLOT = 76;
export const BARLINES = [NOTE_START + SLOT * 3.5, 815] as const;
export const noteX = (i: number) => NOTE_START + i * SLOT + (i > 3 ? 16 : 0);
export type StaffNote = { midi: number; x: number; y: number; stemUp: boolean; ledger: boolean };
export const staffNotes: StaffNote[] = units.map((u, i) => ({
  midi: u.midi,
  x: noteX(i),
  y: noteY(u.midi),
  stemUp: u.midi < 71,
  ledger: u.midi === 60,
}));

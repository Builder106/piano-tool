// Staff geometry in one coordinate system (viewBox 1000 x 186), following
// lib/ui/staff/staff_geometry.dart: everything is a multiple of the staff space.
import { units } from './site';

export const VIEW = { w: 1000, h: 186 };
export const SPACE = 24;
export const TOP = 40; // top line (F5)
export const LINES = [0, 1, 2, 3, 4].map((i) => TOP + i * SPACE);
export const BOTTOM = LINES[4]!; // E4
export const G_LINE = LINES[3]!;

export const HEAD = { rx: SPACE * 0.65, ry: SPACE * 0.5, tilt: -20.05 }; // 1.3 x 1 space, -0.35 rad
export const RING_R = SPACE * 1.3 * 0.72;
export const STEM = { length: SPACE * 3.5, width: SPACE * 0.12 };
export const STROKE = SPACE * 0.18;
export const STRIKE = { r: SPACE * 1.3 * 0.85, angle: -0.6, width: SPACE * 0.16 };

const DIATONIC = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
const diatonic = (midi: number) => Math.floor(midi / 12) * 7 + DIATONIC[midi % 12]!;
/** Each diatonic step moves half a space; E4 sits on the bottom line. */
export const noteY = (midi: number) => BOTTOM - (diatonic(midi) - diatonic(64)) * (SPACE / 2);

export const MEASURE_X = [200, 595];
export const BARLINES = [590, 985];
const SLOT = 95;
export const noteX = (i: number) => MEASURE_X[i < 4 ? 0 : 1]! + 50 + (i % 4) * SLOT;

export type StaffNote = {
  midi: number; x: number; y: number; stemUp: boolean; ledger: boolean;
};

export const staffNotes: StaffNote[] = units.map((u, i) => ({
  midi: u.midi,
  x: noteX(i),
  y: noteY(u.midi),
  stemUp: u.midi < 71, // B4 on the middle line and above take a stem down
  ledger: u.midi === 60,
}));

export const SLOT_W = 90;

/** Measures 3 and 4 of level_1: the scale coming back down, drawn faded past the right edge. */
export const RUN_END = 1780;
export const RUN_BAR = 1375;
export const runNotes = [72, 71, 69, 67, 65, 64, 62, 60].map((midi, i) => ({
  midi,
  x: (i < 4 ? BARLINES[1]! : RUN_BAR) + 50 + (i % 4) * SLOT,
  y: noteY(midi),
  stemUp: midi < 71,
  ledger: midi === 60,
}));

// The pencil annotation written beside each note of the sheet. Facts come from the app's source,
// as listed at the top of site.ts. `mark` is the word left beside a note after you have played it.

export type Annotation = {
  midi: number;
  heading: string;
  body: string;
  mark: string;
};

export const annotations: Annotation[] = [
  {
    midi: 60,
    heading: 'Middle C. Start here.',
    body: "Piano Tool is a practice tutor that listens to your piano and marks every note you play, the way this sheet will. You're on middle C. To turn the page, play the next note: tap its key, type its letter, or switch on MIDI or the mic below and play your own piano.",
    mark: 'start',
  },
  {
    midi: 62,
    heading: 'It listens.',
    body: 'Every 2,048 samples, about 46 milliseconds of sound, the app runs YIN. It compares the sound with delayed copies of itself. When the delay matches one period of the note, the difference drops toward zero, and the first dip under 0.1 gives the pitch. Switch on Mic and this curve draws itself from your piano.',
    mark: 'listens',
  },
  {
    midi: 64,
    heading: 'Measured in staff spaces.',
    body: "Every mark on this staff is sized from one number: the gap between two lines. So when the app added a grand staff for two hands, it didn't need any new drawing code. Each staff got half the height, and every clef, head and stem shrank with it.",
    mark: 'spaces',
  },
  {
    midi: 65,
    heading: 'Shape before colour.',
    body: "A note's state is a shape first. Hollow means still to come, filled is a hit, a ring is perfect timing, and a stroke through it is a miss. An early build told hits from misses by green and red alone, and about one man in twelve can't tell those apart.",
    mark: 'shape',
  },
  {
    midi: 67,
    heading: 'Early, late, on the beat.',
    body: "Every note has a window around its beat. At the normal setting, a tenth of a beat either side is perfect, two tenths is good and three is okay. At 80 beats a minute that's 75, 150 and 225 milliseconds. Start the beat and tap along to see where you land.",
    mark: 'timing',
  },
  {
    midi: 69,
    heading: 'Or plug it in.',
    body: 'A digital piano can skip the microphone. Each key sends three bytes: status, note number, velocity. The note number is already the pitch the app scores in, so it goes straight through with full confidence. The microphone has to earn 0.7. USB and Bluetooth both work.',
    mark: 'MIDI',
  },
  {
    midi: 71,
    heading: 'A recording becomes a level.',
    body: 'Give the app a recording or a YouTube link. Basic Pitch finds the notes, a quantiser snaps them to the beat and works out the meter, and you check the result note by note before anything gets saved.',
    mark: 'import',
  },
  {
    midi: 72,
    heading: 'The octave.',
    body: "The scale ends an octave above where it started. Piano Tool runs from one Flutter codebase on Android, iOS, macOS, Windows, Linux and the web. It's open source under the MIT licence.",
    mark: 'octave',
  },
];

export const annotationByMidi = new Map(annotations.map((a) => [a.midi, a]));

/** The cue written beside the next note. */
export const nextCue = (note: string, letter: string) => ({ text: `Play ${note} next`, keys: `(${letter} on a keyboard)` });

export const missing = {
  heading: "That note isn't in this stage.",
  body: 'Nothing lives at this address. A hollow head with a stroke through it is how Piano Tool marks a note that never sounded.',
};

export const scorePage = {
  heading: 'The score.',
  body: 'The whole site as a list. Every note is a page.',
};

/** Right-hand fingering for the C major scale, C4 to C5. */
export const fingering = [1, 2, 3, 1, 2, 3, 4, 5];

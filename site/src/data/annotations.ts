// The pencil annotation written beside each note of the sheet: one thing a learner gets from the
// app, in plain words. Facts come from the app's source, as listed at the top of site.ts.
// `mark` is the word left beside a note after you have played it.

export type Annotation = {
  midi: number;
  heading: string;
  body: string;
  mark: string;
};

export const annotations: Annotation[] = [
  {
    midi: 60,
    heading: 'Start here.',
    body: 'Piano Tool is an app that listens while you practise and shows you how each note went. This page works the same way. Press the blue key on the keyboard below to turn the page.',
    mark: 'start',
  },
  {
    midi: 62,
    heading: 'It listens to your piano.',
    body: 'Stand your phone or tablet on the music stand and play. The app hears your piano through the microphone. Upright, grand or keyboard, any piano works. Turn on Microphone below to try it here.',
    mark: 'listens',
  },
  {
    midi: 64,
    heading: 'Every note gets a mark.',
    body: 'Each note fills in when you play it. Miss one and it gets a line through it. The marks are shapes, which you can read without colour. At the end you can see exactly what to practise.',
    mark: 'marks',
  },
  {
    midi: 65,
    heading: 'Right on time.',
    body: "The right note is only half of it. The app also marks each note perfect, good or okay by how close to the beat you played it. That's how you learn a steady pulse. Start the beat and tap along.",
    mark: 'timing',
  },
  {
    midi: 67,
    heading: 'Slow it down.',
    body: "Too fast? Play it at half speed until it feels easy, then build back up. The beat slows down with you, so your timing is checked against the slower beat.",
    mark: 'slower',
  },
  {
    midi: 69,
    heading: 'Got a digital piano?',
    body: "Connect it over USB or Bluetooth and the app reads every key you press straight from the keyboard. A noisy room won't matter. Plug it into this computer and turn on Digital piano below to try it.",
    mark: 'plug in',
  },
  {
    midi: 71,
    heading: 'One step at a time.',
    body: "You start with this scale. Finish it and the next stage opens: a simple tune, then a piece that works on rhythm. Your scores are saved, and you can look back and see how far you've come.",
    mark: 'stages',
  },
  {
    midi: 72,
    heading: "That's a scale.",
    body: "Eight notes, C to C. In Piano Tool this is stage one, with a scrolling score and your accuracy at the end. It's free, and you can try it right now in your browser.",
    mark: 'octave',
  },
];

export const annotationByMidi = new Map(annotations.map((a) => [a.midi, a]));

export const missing = {
  heading: "That note isn't in this stage.",
  body: 'Nothing lives at this address. In Piano Tool, a note you miss gets a line through it, like this one.',
};

export const scorePage = {
  heading: 'The score.',
  body: 'Every page of this site in one list.',
};

/** Right-hand fingering for the C major scale, C4 to C5. */
export const fingering = [1, 2, 3, 1, 2, 3, 4, 5];

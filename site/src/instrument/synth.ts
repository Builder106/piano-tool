// The app's review tone (lib/audio/tone_synthesizer.dart), in Web Audio: the fundamental and the
// 2nd and 3rd harmonics at 0.60, 0.25 and 0.15, a 5 ms attack and an exp(-3.5 t / duration) decay.

let ctx: AudioContext | null = null;
export const audioContext = () => (ctx ??= new AudioContext());

const PARTIALS = [
  [1, 0.6],
  [2, 0.25],
  [3, 0.15],
] as const;

export function tone(midi: number, duration = 1.2, level = 0.22) {
  const ac = audioContext();
  if (ac.state === 'suspended') void ac.resume();
  const f = 440 * Math.pow(2, (midi - 69) / 12);
  const t = ac.currentTime;
  const out = ac.createGain();
  out.gain.setValueAtTime(0, t);
  out.gain.linearRampToValueAtTime(level, t + 0.005);
  out.gain.setTargetAtTime(0, t + 0.005, duration / 3.5);
  out.connect(ac.destination);
  for (const [h, a] of PARTIALS) {
    const osc = ac.createOscillator();
    const g = ac.createGain();
    osc.frequency.value = f * h;
    g.gain.value = a;
    osc.connect(g).connect(out);
    osc.start(t);
    osc.stop(t + duration + 0.3);
  }
}

/** A short click for the tap test's beat. */
export function click(accent = false) {
  const ac = audioContext();
  const t = ac.currentTime;
  const osc = ac.createOscillator();
  const g = ac.createGain();
  osc.frequency.value = accent ? 1760 : 1320;
  g.gain.setValueAtTime(0.18, t);
  g.gain.exponentialRampToValueAtTime(0.0001, t + 0.05);
  osc.connect(g).connect(ac.destination);
  osc.start(t);
  osc.stop(t + 0.06);
}

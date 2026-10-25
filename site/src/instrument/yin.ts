// A port of PitchDetector.processBuffer from lib/audio/pitch_detector.dart: YIN with a 0.1
// threshold, parabolic interpolation, an 80 to 1,000 Hz gate and an autocorrelation confidence.
// One deliberate difference: the volume gate. The app gates PCM16 from its own recorder at an RMS
// of 0.1; browser microphones arrive with lower, device-dependent levels, so the web gate is 0.01.

export const YIN_THRESHOLD = 0.1;
export const MIN_CONFIDENCE = 0.7;
export const WEB_MIN_RMS = 0.01;

export type Detection = {
  rms: number;
  frequency: number | null;
  midi: number | null;
  confidence: number;
  tau: number | null;
  /** Cumulative mean normalised difference, tau = 0..half-1. */
  cmnd: Float32Array;
};

export function rmsOf(signal: Float32Array) {
  let s = 0;
  for (let i = 0; i < signal.length; i++) s += signal[i]! * signal[i]!;
  return Math.sqrt(s / signal.length);
}

export function cmndOf(signal: Float32Array, out: Float32Array) {
  const half = out.length;
  out[0] = 1;
  let running = 0;
  for (let tau = 1; tau < half; tau++) {
    let sum = 0;
    for (let i = 0; i < half; i++) {
      const d = signal[i]! - signal[i + tau]!;
      sum += d * d;
    }
    running += sum;
    out[tau] = running > 0 ? (sum * tau) / running : 1;
  }
  return out;
}

function confidenceOf(signal: Float32Array, frequency: number, sampleRate: number) {
  const period = sampleRate / frequency;
  if (period < 2 || period > signal.length / 2) return 0;
  const tau = Math.round(period);
  let sum = 0;
  let sumSq = 0;
  for (let i = 0; i + tau < signal.length; i++) {
    sum += signal[i]! * signal[i + tau]!;
    sumSq += signal[i]! * signal[i]!;
  }
  if (sumSq === 0) return 0;
  return Math.min(1, Math.max(0, sum / sumSq));
}

export function detect(signal: Float32Array, sampleRate: number, cmnd: Float32Array): Detection {
  const rms = rmsOf(signal);
  cmndOf(signal, cmnd);
  const none = { rms, frequency: null, midi: null, confidence: 0, tau: null, cmnd };
  if (rms < WEB_MIN_RMS) return none;

  const half = cmnd.length;
  let tau = 1;
  while (tau < half) {
    if (cmnd[tau]! < YIN_THRESHOLD) {
      while (tau + 1 < half && cmnd[tau + 1]! < cmnd[tau]!) tau++;
      break;
    }
    tau++;
  }
  if (tau >= half) return none;

  let better = tau;
  if (tau > 0 && tau < half - 1) {
    const a = cmnd[tau - 1]!, b = cmnd[tau]!, c = cmnd[tau + 1]!;
    const den = 2 * (a - 2 * b + c);
    if (den !== 0) better = tau + (a - c) / den;
  }
  const frequency = sampleRate / better;
  if (frequency < 80 || frequency > 1000) return { ...none, tau: better };
  const confidence = confidenceOf(signal, frequency, sampleRate);
  if (confidence < MIN_CONFIDENCE) return { ...none, tau: better, confidence };
  const midi = Math.round(69 + 12 * Math.log2(frequency / 440));
  return { rms, frequency, midi, confidence, tau: better, cmnd };
}

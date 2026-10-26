// Live pencil figures share the instrument's microphone and MIDI listeners.
import { gsap } from 'gsap';
import { onPage, prefersReducedMotion } from '../engine';
import { noteName } from '../data/site';
import { onHear, onMidiMessage, soundOn } from './index';
import { click } from './synth';

const $ = <T extends Element = HTMLElement>(selector: string, root: ParentNode = document) => root.querySelector<T>(selector);

// D4: while the microphone is on, say which note the app hears, in plain words.
function hearLive() {
  const live = $('[data-hear-live]');
  if (!live) return;
  return onHear((d) => {
    live.textContent = d.midi === null
      ? (d.rms < .01 ? 'Listening. Play a note.' : 'Listening...')
      : `Hearing ${noteName(d.midi)}`;
  });
}

// A4: with MIDI on, name each key the digital piano sends.
function midiLive() {
  const live = $('[data-midi-live]');
  if (!live) return;
  return onMidiMessage(([status, note, velocity]) => {
    if (status === undefined || note === undefined || velocity === undefined) return;
    if ((status & 0xf0) === 0x90 && velocity > 0) live.textContent = `Your piano played ${noteName(note)}`;
  });
}

function tapTest() {
  const fig = $('[data-tap]');
  const start = fig && $<HTMLButtonElement>('[data-tap-start]', fig);
  const pad = fig && $<HTMLButtonElement>('[data-tap-pad]', fig);
  const out = fig && $('[data-tap-out]', fig);
  const marks = fig && $<SVGGElement>('[data-tap-marks]', fig);
  const head = fig && $<SVGGElement>('[data-tap-head]', fig);
  if (!start || !pad || !out || !marks || !head) return;
  const BEAT_MS = 750;
  let t0 = 0, lastBeat = -1, running = false;
  const tick = () => {
    const n = Math.floor((performance.now() - t0) / BEAT_MS);
    if (n === lastBeat) return;
    lastBeat = n;
    if (soundOn()) click(n % 4 === 0);
    if (!prefersReducedMotion()) gsap.fromTo(head, { scale: 1.5, svgOrigin: '320 30' }, { scale: 1, svgOrigin: '320 30', duration: .6, ease: 'expo.out' });
  };
  const tap = () => {
    if (!running) return;
    const beats = (performance.now() - t0) / BEAT_MS;
    const error = beats - Math.round(beats);
    const a = Math.abs(error);
    const grade = a <= .1 ? 'perfect' : a <= .2 ? 'good' : a <= .3 ? 'okay' : 'missed';
    const x = Math.max(24, Math.min(616, 320 + error * 600));
    const mark = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    mark.setAttribute('class', `tap-mark tap-mark--${grade}`);
    mark.setAttribute('transform', `translate(${x.toFixed(1)} 100)`);
    mark.innerHTML = grade === 'missed'
      ? '<ellipse rx="6.5" ry="5" transform="rotate(-20.05)"/><line x1="-9.1" y1="6.2" x2="9.1" y2="-6.2"/>'
      : `${grade === 'perfect' ? '<circle r="9.4"/>' : ''}<ellipse rx="6.5" ry="5" transform="rotate(-20.05)"/>`;
    marks.append(mark);
    while (marks.children.length > 8) marks.firstElementChild?.remove();
    if (!prefersReducedMotion()) gsap.from(mark, { y: -14, autoAlpha: 0, duration: .5, ease: 'power2.out' });
    const side = error < 0 ? 'early' : 'late';
    out.textContent = a <= .1 ? 'Right on the beat' : a <= .3 ? `A little ${side}` : side === 'early' ? 'Early' : 'Late';
  };
  const toggle = () => {
    running = !running;
    start.setAttribute('aria-pressed', String(running));
    start.textContent = running ? 'Stop the beat' : 'Start the beat';
    pad.disabled = !running;
    if (running) {
      t0 = performance.now(); lastBeat = -1; gsap.ticker.add(tick); out.textContent = 'Tap on each beat';
    } else gsap.ticker.remove(tick);
  };
  const key = (event: KeyboardEvent) => {
    if (running && event.code === 'Space' && !(event.target as Element).closest('button')) { event.preventDefault(); tap(); }
  };
  start.addEventListener('click', toggle);
  pad.addEventListener('click', tap);
  document.addEventListener('keydown', key);
  return () => {
    gsap.ticker.remove(tick);
    start.removeEventListener('click', toggle);
    pad.removeEventListener('click', tap);
    document.removeEventListener('keydown', key);
  };
}

export function startFigures() {
  onPage(() => {
    const cleanups = [hearLive(), tapTest(), midiLive()];
    return () => cleanups.forEach((cleanup) => cleanup?.());
  });
}

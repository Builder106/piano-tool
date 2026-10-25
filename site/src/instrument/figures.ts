// Page figures. Each one checks for its markup, runs inside onPage (reverted on leave), and
// returns a cleanup for anything outside GSAP.
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { onPage, prefersReducedMotion, ease } from '../engine';
import { drawOn } from '../engine/glax';
import { noteName } from '../data/site';
import { onHear, onMidiMessage, soundOn } from './index';
import { click } from './synth';

gsap.registerPlugin(ScrollTrigger);

const $ = <T extends Element = HTMLElement>(s: string, root: ParentNode = document) => root.querySelector<T>(s);
const $$ = <T extends Element = HTMLElement>(s: string, root: ParentNode = document) => [...root.querySelectorAll<T>(s)];

// Strokes drawn on as their figure enters the viewport.
function drawFigures() {
  for (const fig of $$('.figure')) {
    const paths = $$<SVGGeometryElement>('[data-draw]', fig);
    if (!paths.length) continue;
    const tween = drawOn(paths, { paused: true, stagger: 0.08, duration: 1.3 });
    if (tween) ScrollTrigger.create({ trigger: fig, start: 'top 85%', once: true, onEnter: () => tween.play() });
  }
}

// D4: the YIN figure redrawn from the microphone. Same geometry as yin_figure_data.py.
function yinLive() {
  const fig = $('[data-yin]');
  if (!fig) return;
  const wave = $<SVGPathElement>('[data-yin-wave]', fig)!;
  const curve = $<SVGPathElement>('[data-yin-curve]', fig)!;
  const dip = $<SVGGElement>('[data-yin-dip]', fig)!;
  const live = $('[data-yin-live]', fig)!;
  const W = 600, H = 150, TAU_MAX = 400, YMAX = 2.5;
  let first = true;
  return onHear((d, buffer) => {
    if (first) {
      first = false;
      gsap.set([wave, curve], { strokeDasharray: 'none', strokeDashoffset: 0 });
      fig.classList.add('is-live');
    }
    let w = '';
    for (let i = 0; i < buffer.length; i += 12) {
      const x = (i / (buffer.length - 1)) * W;
      const y = 40 - Math.max(-1, Math.min(1, buffer[i]! / 0.5)) * 36;
      w += `${i ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`;
    }
    wave.setAttribute('d', w);
    let c = '';
    for (let t = 1; t <= TAU_MAX && t < d.cmnd.length; t += 2) {
      const y = H - Math.min(d.cmnd[t]!, YMAX) / YMAX * H;
      c += `${t === 1 ? 'M' : 'L'}${((t / TAU_MAX) * W).toFixed(1)} ${y.toFixed(1)}`;
    }
    curve.setAttribute('d', c);
    if (d.tau !== null && d.tau <= TAU_MAX && d.midi !== null) {
      const ti = Math.round(d.tau);
      dip.setAttribute('transform', `translate(${20 + (d.tau / TAU_MAX) * W} ${120 + H - Math.min(d.cmnd[ti]!, YMAX) / YMAX * H})`);
      dip.style.opacity = '1';
      live.textContent = `Live: a dip at ${d.tau.toFixed(1)} samples, ${d.frequency!.toFixed(1)} Hz, ${noteName(d.midi)}, confidence ${d.confidence.toFixed(2)}.`;
    } else {
      dip.style.opacity = '0.25';
      live.textContent = d.rms < 0.01 ? 'Live: too quiet to read.' : 'Live: no dip under 0.1, so no pitch.';
    }
  });
}

// F4: the same six heads with colour removed.
function greyscale() {
  const btn = $<HTMLButtonElement>('[data-greyscale]');
  const fig = $('[data-states]');
  if (!btn || !fig) return;
  const toggle = () => {
    const on = btn.getAttribute('aria-pressed') !== 'true';
    btn.setAttribute('aria-pressed', String(on));
    fig.classList.toggle('is-grey', on);
  };
  btn.addEventListener('click', toggle);
  return () => btn.removeEventListener('click', toggle);
}

// G4: tap on the beat at 80 bpm, graded with the normal windows (settings_repository.dart).
function tapTest() {
  const fig = $('[data-tap]');
  if (!fig) return;
  const start = $<HTMLButtonElement>('[data-tap-start]', fig)!;
  const pad = $<HTMLButtonElement>('[data-tap-pad]', fig)!;
  const out = $('[data-tap-out]', fig)!;
  const marks = $<SVGGElement>('[data-tap-marks]', fig)!;
  const head = $<SVGGElement>('[data-tap-head]', fig)!;
  const BEAT_MS = 750;
  let t0 = 0;
  let lastBeat = -1;
  let running = false;
  const tick = () => {
    const n = Math.floor((performance.now() - t0) / BEAT_MS);
    if (n === lastBeat) return;
    lastBeat = n;
    if (soundOn()) click(n % 4 === 0);
    if (!prefersReducedMotion()) gsap.fromTo(head, { scale: 1.5, svgOrigin: '320 30' }, { scale: 1, svgOrigin: '320 30', duration: 0.6, ease: 'expo.out' });
  };
  const grade = (e: number) => {
    const a = Math.abs(e);
    return a <= 0.1 ? 'perfect' : a <= 0.2 ? 'good' : a <= 0.3 ? 'okay' : 'missed';
  };
  const tap = () => {
    if (!running) return;
    const beats = (performance.now() - t0) / BEAT_MS;
    const e = beats - Math.round(beats);
    const g = grade(e);
    const ms = Math.round(e * BEAT_MS);
    const x = Math.max(24, Math.min(616, 320 + e * 400));
    const mark = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    mark.setAttribute('class', `tap-mark tap-mark--${g}`);
    mark.setAttribute('transform', `translate(${x.toFixed(1)} 100)`);
    mark.innerHTML = g === 'missed'
      ? '<ellipse rx="6.5" ry="5" transform="rotate(-20.05)"/><line x1="-9.1" y1="6.2" x2="9.1" y2="-6.2"/>'
      : `${g === 'perfect' ? '<circle r="9.4"/>' : ''}<ellipse rx="6.5" ry="5" transform="rotate(-20.05)"/>`;
    marks.append(mark);
    while (marks.children.length > 8) marks.firstElementChild?.remove();
    [...marks.children].forEach((m, i, all) => ((m as SVGGElement).style.opacity = String(0.35 + (0.65 * (i + 1)) / all.length)));
    if (!prefersReducedMotion()) gsap.from(mark, { y: -14, autoAlpha: 0, duration: 0.5, ease: ease.out });
    out.textContent = `${ms > 0 ? '+' : ''}${ms} ms, ${g}`;
  };
  const toggle = () => {
    running = !running;
    start.setAttribute('aria-pressed', String(running));
    start.textContent = running ? 'Stop the beat' : 'Start the beat';
    pad.disabled = !running;
    if (running) {
      t0 = performance.now();
      lastBeat = -1;
      gsap.ticker.add(tick);
      out.textContent = 'Tap on each beat';
    } else gsap.ticker.remove(tick);
  };
  const key = (e: KeyboardEvent) => {
    if (running && e.code === 'Space' && !(e.target as Element).closest('button')) { e.preventDefault(); tap(); }
  };
  start.addEventListener('click', toggle);
  pad.addEventListener('pointerdown', tap);
  pad.addEventListener('keydown', (e) => { if (e.code === 'Space' || e.key === 'Enter') { e.preventDefault(); tap(); } });
  document.addEventListener('keydown', key);
  return () => {
    gsap.ticker.remove(tick);
    document.removeEventListener('keydown', key);
    start.removeEventListener('click', toggle);
    pad.removeEventListener('pointerdown', tap);
  };
}

// B4: transcribed notes snap to the beat, then the level's noteheads appear.
function quantise() {
  const fig = $('[data-import]');
  if (!fig || prefersReducedMotion()) return;
  const bars = $$<SVGRectElement>('[data-bar]', fig);
  const heads = $$<SVGGElement>('[data-head]', fig);
  gsap.set(heads, { autoAlpha: 0 });
  const tl = gsap.timeline({ paused: true })
    .to(bars, { attr: { x: (i: number) => Number(bars[i]!.dataset.to), width: 60 }, duration: 0.9, stagger: 0.12, ease: ease.out })
    .to(heads, { autoAlpha: 1, duration: 0.6, stagger: 0.1, ease: ease.out }, '-=0.3');
  ScrollTrigger.create({ trigger: fig, start: 'top 75%', once: true, onEnter: () => tl.play() });
}

// A4: the last message from a MIDI keyboard, byte by byte.
function midiLog() {
  const fig = $('[data-midi-figure]');
  if (!fig) return;
  const byte = (i: number) => $(`[data-midi-byte="${i}"]`, fig)!;
  const label = (i: number) => $(`[data-midi-label="${i}"]`, fig)!;
  const caption = $('[data-midi-caption]', fig)!;
  return onMidiMessage(([s, n, v]) => {
    const kind = (s! & 0xf0) === 0x90 && v! > 0 ? 'note on' : (s! & 0xf0) === 0x80 || (s! & 0xf0) === 0x90 ? 'note off' : 'message';
    [s, n, v].forEach((b, i) => (byte(i).textContent = `0x${b!.toString(16).toUpperCase().padStart(2, '0')}`));
    label(0).textContent = `${kind}, channel ${(s! & 0x0f) + 1}`;
    label(1).textContent = `note ${n}`;
    label(2).textContent = `velocity ${v}`;
    label(3).textContent = `${noteName(n!)}, confidence 1.0`;
    caption.textContent = 'Live from your keyboard.';
  });
}

// The note mark rides beside the page on wide screens until the body runs out.
function pinMark() {
  const mark = $('[data-mark]');
  const body = mark?.parentElement;
  if (!mark || !body || !matchMedia('(min-width: 1100px)').matches) return;
  const top = () => (document.getElementById('hud')?.offsetHeight ?? 60) + 48;
  ScrollTrigger.create({
    trigger: body, pin: mark, pinSpacing: false, invalidateOnRefresh: true,
    start: () => `top ${top()}px`,
    end: () => `+=${Math.max(0, body.offsetHeight - mark.offsetHeight)}`,
  });
}

export function startFigures() {
  onPage(() => {
    drawFigures();
    pinMark();
    const offs = [yinLive(), greyscale(), tapTest(), quantise(), midiLog()];
    return () => offs.forEach((off) => off?.());
  });
}

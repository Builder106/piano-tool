// The instrument: the one driver behind the concept. A note played by any input goes through
// play(); the page's note decides what the staff, keys, and ledge show.
// Everything animates on the GSAP ticker; nothing here owns a requestAnimationFrame loop.
import { gsap } from 'gsap';
import { navigate } from 'astro:transitions/client';
import { prefersReducedMotion } from '../engine';
import { units, unitByMidi, noteName } from '../data/site';
import { staffNotes } from '../data/staff';
import { tone, audioContext } from './synth';
import { detect, type Detection } from './yin';

type Source = 'pointer' | 'keys' | 'midi' | 'mic';

const PLAYED_KEY = 'piano-tool:played';
const PREFS_KEY = 'piano-tool:prefs:2'; // 2: sound now starts on
const LETTERS: Record<string, number> = {
  a: 60, w: 61, s: 62, e: 63, d: 64, f: 65, t: 66, g: 67, y: 68, h: 69, u: 70, j: 71, k: 72,
};
const BEAT = 60 / 80; // stage one tempo, seconds

function read<T>(store: Storage, key: string, fallback: T): T {
  try {
    const v = store.getItem(key);
    return v ? (JSON.parse(v) as T) : fallback;
  } catch {
    return fallback;
  }
}
function write(store: Storage, key: string, value: unknown) {
  try {
    store.setItem(key, JSON.stringify(value));
  } catch {
    /* storage can be unavailable (private mode); the site works without it */
  }
}

let current: number | null = null;
let played = new Set<number>();
// Sound starts on: a key that makes no sound when you press it reads as broken.
const prefs = { keys: true, sound: true };

// Listeners for figures that show live input.
const hearFns = new Set<(d: Detection, buffer: Float32Array) => void>();
const midiFns = new Set<(bytes: number[]) => void>();
export const onHear = (fn: (d: Detection, buffer: Float32Array) => void) => (hearFns.add(fn), () => void hearFns.delete(fn));
export const onMidiMessage = (fn: (bytes: number[]) => void) => (midiFns.add(fn), () => void midiFns.delete(fn));
export const soundOn = () => prefs.sound;
export const playedCount = () => played.size;

const $ = <T extends Element = HTMLElement>(s: string, root: ParentNode = document) => root.querySelector<T>(s);
const $$ = <T extends Element = HTMLElement>(s: string, root: ParentNode = document) => [...root.querySelectorAll<T>(s)];

// ---------------------------------------------------------------- keys (the Blender render)

function pressImg(midi: number) {
  return $<HTMLImageElement>(`[data-press="${midi}"]`);
}

/** Attack: the key goes down fast. A momentary strike releases after a short hold. */
function strike(midi: number, momentary: boolean) {
  const img = pressImg(midi);
  const key = $(`[data-key="${midi}"]`);
  key?.classList.add('is-down');
  if (img) gsap.to(img, { autoAlpha: 1, duration: prefersReducedMotion() ? 0 : 0.06, ease: 'power4.out', overwrite: true });
  if (!momentary) return;
  gsap.delayedCall(0.22, () => release(midi));
}

function release(midi: number) {
  if (midi === current) return;
  $(`[data-key="${midi}"]`)?.classList.remove('is-down');
  const img = pressImg(midi);
  if (img) gsap.to(img, { autoAlpha: 0, duration: prefersReducedMotion() ? 0 : 0.5, ease: 'expo.out', overwrite: true });
}

// ---------------------------------------------------------------- play

let toastTimer: gsap.core.Tween | null = null;
function toast(text: string) {
  const el = $('#toast');
  const label = $('[data-toast-text]');
  if (!el || !label) return;
  label.textContent = text;
  el.classList.add('is-on');
  toastTimer?.kill();
  if (!prefersReducedMotion()) gsap.fromTo(el, { y: 10 }, { y: 0, duration: 0.5, ease: 'expo.out' });
  toastTimer = gsap.delayedCall(2.2, () => el.classList.remove('is-on'));
}

export function play(midi: number, source: Source) {
  if (prefs.sound && source !== 'mic') tone(midi);
  const unit = unitByMidi.get(midi);
  const inOctave = midi >= 60 && midi <= 72;
  if (unit) {
    strike(midi, false);
    if (midi !== current) void navigate(unit.route);
    return;
  }
  if (inOctave) strike(midi, true);
  toast(`${noteName(midi)} is not in stage one`);
}

// ---------------------------------------------------------------- page state

function sync() {
  const main = $('#main');
  const note = Number(main?.dataset.note) || null;
  const previous = current;
  current = note;
  if (note) {
    played.add(note);
    write(sessionStorage, PLAYED_KEY, [...played]);
  }
  const reduced = prefersReducedMotion();

  // What to play next: the note after this page's, or C4 again from the top of the octave.
  const idx = units.findIndex((u) => u.midi === note);
  const next = idx >= 0 ? units[(idx + 1) % units.length] ?? null : units[0] ?? null;
  const again = idx === units.length - 1;

  // Staff, as the app marks it: the note to play next is due (blue, ringed, keeping the beat);
  // this page's note and every note already played are hits; the rest are still to come.
  for (const a of $$<SVGElement>('.staff .note')) {
    const m = Number(a.dataset.midi);
    const state = m === next?.midi && m !== note ? 'next' : m === note ? 'current' : played.has(m) ? 'hit' : 'upcoming';
    const was = a.dataset.state;
    a.dataset.state = state;
    if (m === note) a.setAttribute('aria-current', 'page');
    else a.removeAttribute('aria-current');
    const at = staffNotes.find((s) => s.midi === m);
    if (!at) continue;
    if (state === 'next' && was !== 'next' && !reduced) {
      gsap.fromTo(a.querySelector('.note__head'), { scale: 0.55, svgOrigin: `${at.x} ${at.y}` },
        { scale: 1, svgOrigin: `${at.x} ${at.y}`, duration: 0.9, ease: 'expo.out' });
    }
  }

  // Letters under the staff: a tick and a word beside each note played, "next" under the due one.
  for (const row of $$<SVGGElement>('[data-letter]')) {
    const m = Number(row.dataset.letter);
    row.classList.toggle('is-played', played.has(m));
    row.classList.toggle('is-current', m === note);
    row.classList.toggle('is-next', m === next?.midi && m !== note);
    const cue = row.querySelector('.staff__cue');
    if (cue) cue.textContent = again && m === next?.midi ? 'again' : 'next';
  }

  // Playhead: the app's playhead, resting just ahead of the due note.
  const head = $<SVGLineElement>('[data-playhead]');
  if (head) {
    const n = staffNotes.find((s) => s.midi === next?.midi);
    if (n && note) {
      const x = n.x - 34; // clear of stems and ledger lines
      if (previous === null || reduced) gsap.set(head, { attr: { x1: x, x2: x } });
      gsap.to(head, { attr: { x1: x, x2: x }, autoAlpha: 1, duration: reduced ? 0 : 0.9, ease: 'expo.out' });
    } else gsap.to(head, { autoAlpha: 0, duration: reduced ? 0 : 0.3 });
  }

  // Keys: hold the page's key down, release the last one, light the next one's sticker.
  if (previous && previous !== note) release(previous);
  if (note) strike(note, false);
  for (const k of $$('.key--white')) {
    const m = Number(k.dataset.key);
    k.classList.toggle('is-current', m === note);
    k.classList.toggle('is-next', m === next?.midi && m !== note && note !== null);
  }

  const result = $('[data-result-count]');
  if (result) result.textContent = String(played.size);
  // Astro replaces <html> attributes on every page swap, so the flag is set again here.
  document.documentElement.classList.toggle('letters-off', !prefs.keys);
}

// ---------------------------------------------------------------- idle: the due note keeps time

function startIdle() {
  if (prefersReducedMotion()) return;
  gsap.ticker.add((t) => {
    if (document.hidden) return;
    // A beat at 80 bpm: a sharp onset and a slow decay, like a struck string. CSS reads --pulse,
    // set on the two elements that use it so a write restyles nothing else.
    const phase = (t / BEAT) % 1;
    const amp = Math.exp(-phase * 5).toFixed(2);
    $('.staff .note[data-state="next"]')?.style.setProperty('--pulse', amp);
    $('.key--white.is-next')?.style.setProperty('--pulse', amp);
  });
}

// ---------------------------------------------------------------- inputs

function setPressed(input: string, on: boolean) {
  const btn = $(`[data-input="${input}"]`);
  btn?.setAttribute('aria-pressed', String(on));
  const state = btn?.querySelector('[data-state-text]');
  if (state) state.textContent = on ? 'on' : 'off';
  if (input === 'keys') document.documentElement.classList.toggle('letters-off', !on);
}

function hear(text: string) {
  const el = $('[data-hear]');
  if (el && el.textContent !== text) el.textContent = text;
}

// Letter keys. WCAG 2.1.4: single-character shortcuts can be switched off on the ledge.
function onKeyDown(e: KeyboardEvent) {
  if (e.repeat || e.metaKey || e.ctrlKey || e.altKey) return;
  const t = e.target as HTMLElement;
  if (t.closest('input, textarea, select, [contenteditable="true"]')) return;
  // Arrow keys turn the page, like the page links at the foot of the sheet.
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
    const link = $<HTMLAnchorElement>(e.key === 'ArrowLeft' ? '.sheet__foot [rel="prev"]' : '.sheet__foot .sheet__turn--next');
    if (link) { e.preventDefault(); void navigate(link.href); }
    return;
  }
  if (!prefs.keys) return;
  const midi = LETTERS[e.key.toLowerCase()];
  if (midi === undefined) return;
  e.preventDefault();
  play(midi, 'keys');
}

// Web MIDI: Note On with a velocity above zero plays the note, as in MidiService.
let midiAccess: MIDIAccess | null = null;
function onMidi(e: MIDIMessageEvent) {
  const data = e.data;
  if (!data || data.length < 3) return;
  const bytes = [data[0]!, data[1]!, data[2]!];
  midiFns.forEach((fn) => fn(bytes));
  if ((bytes[0]! & 0xf0) === 0x90 && bytes[2]! > 0) play(bytes[1]!, 'midi');
}
function attachMidi(on: boolean) {
  midiAccess?.inputs.forEach((input) => { input.onmidimessage = on ? onMidi : null; });
}
async function toggleMidi() {
  if (midiAccess) {
    attachMidi(false);
    midiAccess.onstatechange = null;
    midiAccess = null;
    setPressed('midi', false);
    return;
  }
  try {
    midiAccess = await navigator.requestMIDIAccess();
    attachMidi(true);
    midiAccess.onstatechange = () => attachMidi(true);
    setPressed('midi', true);
    toast(midiAccess.inputs.size ? 'Digital piano on. Play a key.' : 'No digital piano connected yet.');
  } catch {
    toast("This browser can't connect to a digital piano. Try Chrome or Edge.");
  }
}

// Microphone: the browser port of the app's YIN detector, run on the GSAP ticker.
let mic: { stream: MediaStream; analyser: AnalyserNode; tick: () => void } | null = null;
async function toggleMic() {
  if (mic) {
    gsap.ticker.remove(mic.tick);
    mic.stream.getTracks().forEach((t) => t.stop());
    mic.analyser.disconnect();
    mic = null;
    setPressed('mic', false);
    hear('');
    return;
  }
  let stream: MediaStream;
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false },
    });
  } catch {
    toast('The microphone is blocked or missing');
    return;
  }
  const ac = audioContext();
  if (ac.state === 'suspended') await ac.resume();
  const analyser = ac.createAnalyser();
  analyser.fftSize = 2048;
  ac.createMediaStreamSource(stream).connect(analyser);
  const buffer = new Float32Array(analyser.fftSize);
  const cmnd = new Float32Array(analyser.fftSize / 2);
  let frame = 0;
  let candidate: number | null = null;
  let streak = 0;
  let fired: number | null = null;
  let quiet = 0;
  const tick = () => {
    if (++frame % 3) return; // about 20 analyses a second
    analyser.getFloatTimeDomainData(buffer);
    const d = detect(buffer, ac.sampleRate, cmnd);
    hearFns.forEach((fn) => fn(d, buffer));
    if (d.midi === null) {
      hear(d.rms < 0.01 ? 'Listening' : 'Listening, no clear pitch');
      if (++quiet > 8) fired = null; // after silence the same note can play again
      candidate = null;
      streak = 0;
      return;
    }
    quiet = 0;
    hear(`Hearing ${noteName(d.midi)}, ${Math.round(d.frequency!)} Hz`);
    streak = d.midi === candidate ? streak + 1 : 1;
    candidate = d.midi;
    if (streak >= 2 && d.midi !== fired) {
      fired = d.midi;
      play(d.midi, 'mic');
    }
  };
  gsap.ticker.add(tick);
  mic = { stream, analyser, tick };
  setPressed('mic', true);
  hear('Listening');
}

function onLedgeClick(e: MouseEvent) {
  const btn = (e.target as Element).closest<HTMLButtonElement>('[data-input]');
  if (!btn) return;
  const input = btn.dataset.input;
  if (input === 'keys') { prefs.keys = !prefs.keys; setPressed('keys', prefs.keys); write(localStorage, PREFS_KEY, prefs); }
  if (input === 'sound') { prefs.sound = !prefs.sound; setPressed('sound', prefs.sound); write(localStorage, PREFS_KEY, prefs); if (prefs.sound) audioContext(); }
  if (input === 'mic') void toggleMic();
  if (input === 'midi') void toggleMidi();
}

// Pointer on the keys: the attack and the tone on pointerdown, before the click navigates.
function onPointerDown(e: PointerEvent) {
  const key = (e.target as Element).closest<HTMLElement>('.key');
  if (!key) return;
  const midi = Number(key.dataset.key);
  if (key.classList.contains('key--black')) { play(midi, 'pointer'); return; }
  if (prefs.sound) tone(midi);
  strike(midi, midi === current);
}

// A note on the staff and its key light together, so the page shows which key plays which note.
function link(midi: number | null) {
  for (const el of $$('.is-linked')) el.classList.remove('is-linked');
  if (midi === null) return;
  for (const el of $$(`.key[data-key="${midi}"], .staff .note[data-midi="${midi}"], [data-letter="${midi}"]`)) el.classList.add('is-linked');
}
function linkedMidi(target: EventTarget | null) {
  const el = (target as Element | null)?.closest<HTMLElement | SVGElement>('.key--white, .staff .note');
  if (!el) return null;
  return Number(el.dataset.key ?? el.dataset.midi) || null;
}
const onLinkOver = (e: Event) => link(linkedMidi(e.target));
const onLinkOut = (e: Event) => { if (linkedMidi((e as FocusEvent).relatedTarget) === null) link(null); };

// Hover: under a fine pointer the key starts to sink, a shallow version of the strike.
function onPointerOver(e: PointerEvent) {
  if (e.pointerType !== 'mouse') return;
  const key = (e.target as Element).closest<HTMLElement>('.key');
  const left = (e.relatedTarget as Element | null)?.closest('.key');
  if (!key || key === left) return;
  const midi = Number(key.dataset.key);
  if (midi === current || key.classList.contains('is-down')) return;
  const img = pressImg(midi);
  if (img) gsap.to(img, { autoAlpha: 0.4, duration: prefersReducedMotion() ? 0 : 0.25, ease: 'power3.out', overwrite: true });
}
function onPointerOut(e: PointerEvent) {
  if (e.pointerType !== 'mouse') return;
  const key = (e.target as Element).closest<HTMLElement>('.key');
  const into = (e.relatedTarget as Element | null)?.closest('.key');
  if (!key || key === into) return;
  const midi = Number(key.dataset.key);
  if (midi === current || key.classList.contains('is-down')) return;
  const img = pressImg(midi);
  if (img) gsap.to(img, { autoAlpha: 0, duration: prefersReducedMotion() ? 0 : 0.45, ease: 'expo.out', overwrite: true });
}

export function startInstrument() {
  played = new Set(read<number[]>(sessionStorage, PLAYED_KEY, []));
  Object.assign(prefs, read(localStorage, PREFS_KEY, prefs));
  setPressed('keys', prefs.keys);
  setPressed('sound', prefs.sound);
  if ('requestMIDIAccess' in navigator) $('[data-input="midi"]')?.removeAttribute('hidden');
  document.addEventListener('keydown', onKeyDown);
  document.addEventListener('click', onLedgeClick);
  document.addEventListener('pointerdown', onPointerDown);
  document.addEventListener('pointerover', onPointerOver);
  document.addEventListener('pointerout', onPointerOut);
  document.addEventListener('pointerover', onLinkOver);
  document.addEventListener('pointerout', onLinkOut);
  document.addEventListener('focusin', onLinkOver);
  document.addEventListener('focusout', onLinkOut);
  // Not onPage: page contexts revert their tweens on leave, and the instrument persists.
  sync();
  document.addEventListener('astro:after-swap', sync);
  startIdle();
}

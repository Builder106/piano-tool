import { gsap } from 'gsap';
import { DrawSVGPlugin } from 'gsap/DrawSVGPlugin';
import { Flip } from 'gsap/Flip';
import { onPage, prefersReducedMotion, setTransition } from '@/engine';
import { startInstrument } from '@/instrument';
import { startFigures } from '@/instrument/figures';
import { motion } from './params';

gsap.registerPlugin(DrawSVGPlugin, Flip);

type Departing = { midi: number; text: string; rect: DOMRect; font: string };
let departing: Departing | null = null;

function settleMark() {
  const previous = departing;
  departing = null;
  if (!previous || prefersReducedMotion()) return;
  const mark = document.querySelector<SVGTextElement>(`[data-leftover="${previous.midi}"] text`);
  const target = mark?.getBoundingClientRect();
  if (!mark || !target || target.width === 0) return;
  mark.style.opacity = '0';
  const ghost = document.createElement('span');
  ghost.textContent = previous.text;
  ghost.setAttribute('aria-hidden', 'true');
  ghost.style.position = 'fixed';
  ghost.style.zIndex = '7';
  ghost.style.pointerEvents = 'none';
  ghost.style.whiteSpace = 'nowrap';
  ghost.style.color = '#4e535c';
  ghost.style.font = previous.font;
  ghost.style.left = `${previous.rect.left}px`;
  ghost.style.top = `${previous.rect.top}px`;
  ghost.style.width = `${previous.rect.width}px`;
  ghost.style.height = `${previous.rect.height}px`;
  document.body.append(ghost);
  const state = Flip.getState(ghost);
  ghost.style.left = `${target.left}px`;
  ghost.style.top = `${target.top}px`;
  ghost.style.width = `${target.width}px`;
  ghost.style.height = `${target.height}px`;
  ghost.style.fontSize = '15px';
  Flip.from(state, { duration: motion.settle.duration, ease: motion.settle.ease, absolute: true, onComplete: () => { mark.style.opacity = ''; ghost.remove(); } });
}

function copySheetContent(event: Event) {
  if (!('newDocument' in event) || !(event.newDocument instanceof Document)) return;
  const next = event.newDocument.querySelector('[data-sheet-content]');
  const current = document.querySelector('[data-sheet-content]');
  if (next && current) current.replaceWith(next.cloneNode(true));
}

export function setupMotion() {
  document.addEventListener('astro:before-swap', copySheetContent);
  setTransition({
    leave: () => {
      const main = document.querySelector<HTMLElement>('#main');
      const heading = main?.querySelector<HTMLElement>('h1, h2');
      const midi = Number(main?.dataset.note);
      departing = heading && midi ? { midi, text: heading.textContent ?? '', rect: heading.getBoundingClientRect(), font: getComputedStyle(heading).font } : null;
      return gsap.to('#main', { y: motion.leave.y, autoAlpha: 0, duration: prefersReducedMotion() ? 0 : motion.leave.duration, ease: motion.leave.ease });
    },
    enter: () => gsap.fromTo('#main', { y: prefersReducedMotion() ? 0 : motion.enter.y, autoAlpha: prefersReducedMotion() ? 1 : 0 }, { y: 0, autoAlpha: 1, duration: prefersReducedMotion() ? 0 : motion.enter.duration, ease: motion.enter.ease, clearProps: 'transform,opacity,visibility' }),
  });
  startInstrument();
  document.addEventListener('astro:after-swap', settleMark);
  startFigures();
  onPage(() => {
    if (prefersReducedMotion()) return;
    const root = document.querySelector('[data-sheet-content]');
    if (!root) return;
    const arrow = [...root.querySelectorAll<SVGGeometryElement>('.sheet__pencil [data-draw], .sheet__tempo [data-draw]')];
    const drawing = [...root.querySelectorAll<SVGGeometryElement>('.annotation__drawing [data-draw], .annotation__cta [data-draw]')];
    const heading = root.querySelector<HTMLElement>('.annotation__copy > h1, .annotation__copy > h2');
    const body = root.querySelector<HTMLElement>('.annotation__copy > p');
    const trailing = [...root.querySelectorAll<HTMLElement>('.annotation__finish, .score__list, .score__colophon, .annotation__links')];
    const labels = [...root.querySelectorAll<SVGTextElement>('.annotation__drawing text, .sheet__labels text')];
    // The paragraph rises as one block: splitting it into lines puts aria-label on a <p>.
    const lines = [...(heading ? [heading] : []), ...(body ? [body] : []), ...trailing];
    const tl = gsap.timeline();
    for (const stroke of [...arrow, ...drawing]) tl.from(stroke, { drawSVG: '0%', duration: motion.pen.duration, ease: motion.pen.ease }, `>-${motion.pen.duration - motion.pen.stagger}`);
    tl.from(lines, { y: motion.text.y, autoAlpha: 0, stagger: motion.text.stagger, duration: motion.text.duration, ease: motion.text.ease }, 0.12);
    tl.from(labels, { autoAlpha: 0, stagger: motion.text.stagger, duration: motion.text.duration }, '>-.2');
  });
}

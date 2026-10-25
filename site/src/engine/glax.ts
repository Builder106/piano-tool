// Glaxnimate artwork on the engine's single clock: GSAP draws strokes and seeks SMIL timelines.
import { gsap } from 'gsap';
import { prefersReducedMotion } from './env';

/** Pattern A: draw strokes that carry pathLength="1". Under reduced motion they are drawn at once. */
export function drawOn(targets: gsap.TweenTarget, vars: gsap.TweenVars = {}) {
  const els = gsap.utils.toArray<SVGGeometryElement>(targets);
  if (prefersReducedMotion()) {
    gsap.set(els, { strokeDasharray: 1, strokeDashoffset: 0 });
    return null;
  }
  gsap.set(els, { strokeDasharray: 1, strokeDashoffset: 1 });
  return gsap.to(els, { strokeDashoffset: 0, duration: 1.2, ease: 'power2.inOut', ...vars });
}

/** Pattern B: a GSAP tween that owns a Glaxnimate SMIL timeline. Reduced motion shows the last frame. */
export function smilTween(svg: SVGSVGElement, vars: gsap.TweenVars = {}) {
  const ms = Number(svg.dataset.glaxMs);
  svg.pauseAnimations();
  if (prefersReducedMotion()) {
    svg.setCurrentTime(ms / 1000);
    return null;
  }
  const state = { t: 0 };
  svg.setCurrentTime(0);
  return gsap.to(state, {
    t: ms,
    duration: ms / 1000,
    ease: 'none',
    ...vars,
    onUpdate: () => svg.setCurrentTime(state.t / 1000),
  });
}

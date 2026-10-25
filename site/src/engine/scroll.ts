// Smooth scroll on ONE clock: ScrollSmoother runs on gsap.ticker, and ScrollTrigger, the
// onScroll feed and WebGL all read its smoothed position. Page content lives in
// #smooth-wrapper > #smooth-content; fixed UI stays outside the wrapper.
// Reduced motion → native scroll, no smoother.
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { ScrollSmoother } from 'gsap/ScrollSmoother';
import { prefersReducedMotion } from './env';

gsap.registerPlugin(ScrollTrigger, ScrollSmoother);

let smoother: ScrollSmoother | null = null;
let content: HTMLElement | null = null;
let native = false;
let anchors = false;
const listeners = new Set<(s: ScrollState) => void>();

export type ScrollState = { y: number; velocity: number; progress: number };
const state: ScrollState = { y: 0, velocity: 0, progress: 0 };

/** Create the smoother before any ScrollTrigger. Safe to call on every page: a smoother whose
 *  content left the DOM (a router replaced <body>) is killed and rebuilt. */
export function initScroll() {
  if (prefersReducedMotion()) {
    // Still publish native scroll position for WebGL sync.
    if (!native) addEventListener('scroll', nativeTick, { passive: true });
    native = true;
    return;
  }
  if (smoother && content?.isConnected) return;
  smoother?.kill();
  content = document.getElementById('smooth-content');
  smoother = ScrollSmoother.create({
    wrapper: '#smooth-wrapper',
    content: '#smooth-content',
    smooth: 1, // seconds to catch up with the native position; touch stays native (smoothTouch default)
    onUpdate: (self) => {
      const max = ScrollTrigger.maxScroll(window);
      state.y = self.scrollTop();
      state.velocity = self.getVelocity();
      state.progress = max > 0 ? self.progress : 0; // a page that cannot scroll reports 0
      listeners.forEach((fn) => fn(state));
    },
  });
  if (!anchors) document.addEventListener('click', onAnchorClick);
  anchors = true;
}

// Same-page anchors and the skip link: native jumps skip the smoother, so route them through it
// and move focus to the target (give non-interactive targets tabindex="-1", like #main).
function onAnchorClick(e: MouseEvent) {
  const a = (e.target as Element).closest<HTMLAnchorElement>('a[href^="#"]');
  const target = a && a.hash.length > 1 ? document.getElementById(decodeURIComponent(a.hash.slice(1))) : null;
  if (!smoother || !target) return;
  e.preventDefault();
  smoother.scrollTo(target, true, 'top top');
  history.pushState(null, '', a!.hash);
  target.focus({ preventScroll: true });
}

function nativeTick() {
  const max = document.documentElement.scrollHeight - innerHeight;
  state.velocity = scrollY - state.y;
  state.y = scrollY;
  state.progress = max > 0 ? scrollY / max : 0;
  listeners.forEach((fn) => fn(state));
}

export const onScroll = (fn: (s: ScrollState) => void) => {
  listeners.add(fn);
  return () => listeners.delete(fn);
};
export const scrollState = () => state;
export const stopScroll = () => smoother?.paused(true);
export const startScroll = () => smoother?.paused(false);
export function resetScroll() {
  if (smoother) smoother.scrollTo(0, false); // jumps, and works while paused
  else scrollTo(0, 0);
  state.y = 0;
  state.velocity = 0;
}
export function scrollToTarget(target: string | HTMLElement | number) {
  if (smoother) {
    const y = typeof target === 'number' ? target : smoother.offset(target, 'top top');
    gsap.to(smoother, { scrollTop: Math.min(ScrollTrigger.maxScroll(window), y), duration: 1.4, ease: 'power3.out' });
  } else if (typeof target === 'number') scrollTo({ top: target });
  else (typeof target === 'string' ? document.querySelector(target) : target)?.scrollIntoView();
}

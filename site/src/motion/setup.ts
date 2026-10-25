// Global motion. The verb is strike and ring: keys go down in 60 ms, everything else releases
// and rings in on long exponential tails. Page changes never cover the instrument: the old desk
// releases (drops and fades like a damper), the staff and keys move on, the new desk rings in.
import { gsap } from 'gsap';
import { setTransition } from '../engine';
import { startInstrument } from '../instrument';
import { startFigures } from '../instrument/figures';

export function setupMotion() {
  setTransition({
    leave: () => gsap.to('#main', { y: 14, autoAlpha: 0, duration: 0.28, ease: 'power2.in' }),
    // Short on purpose: the engine plays the page intro (the title ringing in) after this resolves.
    enter: () => gsap.fromTo('#main', { y: 10, autoAlpha: 0 }, {
      y: 0, autoAlpha: 1, duration: 0.32, ease: 'power3.out', clearProps: 'transform,opacity,visibility',
    }),
  });
  startInstrument();
  startFigures();
}

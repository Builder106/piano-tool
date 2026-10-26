export const motion = {
  leave: { y: 8, duration: 0.25, ease: 'power2.in' },
  enter: { y: 6, duration: 0.3, ease: 'power2.out' },
  settle: { duration: 0.6, ease: 'expo.out' },
  pen: { duration: 0.45, ease: 'power1.inOut', stagger: 0.065 },
  text: { y: 6, duration: 0.38, stagger: 0.07, ease: 'power2.out' },
} as const;

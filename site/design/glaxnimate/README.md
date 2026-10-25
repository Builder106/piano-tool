# Glaxnimate drawings

Source drawings for the showcase site, made with the Glaxnimate MCP server. The site inlines
them as Astro components and swaps the pen colours for CSS tokens. GSAP animates them.

| File | Used in |
|---|---|
| `noteheads.svg` | every staff: the six note states from `lib/ui/staff/note_glyph.dart` (`src/components/Notehead.astro`) |
| `mark.svg` | favicon and the active notehead mark |
| `yin-figure.svg` | D4, `/listening/`: a 2048-sample buffer and its YIN curve; `yin_figure_data.py` makes the path data |
| `staff-spaces.svg` | E4, `/staff/`: staff-space measurements from `staff_geometry.dart` |
| `hit-windows.svg` | G4, `/timing/`: the normal tolerance windows at 80 bpm; taps are plotted into `#taps` |
| `midi-message.svg` | A4, `/midi/`: a Note On message becoming a pitch event |
| `import-pipeline.svg` | B4, `/import/`: transcribed notes snapped to beats and written as a level |

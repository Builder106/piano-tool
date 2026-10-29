# Piano Tool brand

## The mark

Middle C, circled in pencil. Middle C is where every beginner starts, and the
loop is how a teacher marks a note in a pupil's copy. That is the app's whole
job: it marks every note you play. The site's home page draws the same loop
round middle C, so the mark is a small copy of the first page.

| File | Use |
|---|---|
| `mark.svg` | ink and blue, on light grounds |
| `mark-dark.svg` | paper and light blue, on dark grounds |
| `mark-mono.svg` | one colour, for stamps and embossing |
| `icon.svg` | app icon: the paper and light-blue mark on lacquer, full bleed |
| `icon-maskable.svg` | the same, inside the 80% safe zone for Android and web masks |

Keep clear space round the mark of at least the notehead's height. Below 16 px
the loop fills in; use the wordmark alone there.

Don't redraw the loop as a clean circle, recolour the note, or put the blue
loop on a busy photo.

## Colour

One accent. Everything else is the black and white of a piano and a page.

| Name | Light | Dark | Use |
|---|---|---|---|
| Lacquer | `#0A0A0B` | | page ground, app icon tile |
| Paper | `#ECEEF1` | | the sheet, light surfaces |
| Ink | `#141519` | `#ECEEF1` | type, notes, the mark |
| Graphite | `#4E535C` | | pencil notes, secondary text |
| Pencil Blue | `#2456C8` | `#6591E1` | the loop, the due note, links |

Every neutral sits on the blue's hue (OKLCH 262), so the greys are cool and
match the blue. No cream or warm off-white. Green, amber and red are
note states in the app and are never brand colours.

The app's full token set lives in `lib/ui/theme/tokens.dart`; the site's in
`site/src/styles/tokens.css`.

## Type

| Face | Use |
|---|---|
| Cormorant Garamond 500 | the wordmark "Piano Tool", titles |
| IBM Plex Sans | body, labels, numbers |
| Bravura | music glyphs |

The wordmark is the name set in Cormorant Garamond 500 with -0.01em tracking,
mark first. It is live text, not an outline.

## Rebuilding the files

```sh
python3 brand/mark.py
python3 brand/icons.py
```

`mark.py` writes the SVGs here, the site favicon and the site's copy of the
mark. `icons.py` rasterises the app icons for Android, iOS, macOS, Windows and
web, the site's touch icon and the app header's mark. It needs `rsvg-convert`
and Pillow.

`og.html` is the site's share card. Screenshot it at 1200 x 630 with headless
Chrome and save it as `site/public/og.jpg`.

The app's other art is rendered in Blender on a Mac with a GPU:
`design/blender/covers.py` writes the four book covers to `assets/art/`, and
`site/design/blender/keyboard.py` builds the keyboard, whose fallboard carries
the mark and name in nickel. Its rest render is copied to
`assets/art/keyboard.png` for the app.

## Stage colours

| Cover | Hex | Used for |
|---|---|---|
| Blue | `#2456C8` | stages 1, 4, 7 |
| Green | `#1F6A50` | stages 2, 5, 8 |
| Rust | `#B4501E` | stages 3, 6, 9 |
| Slate | `#4E535C` | imported pieces |

Covers are the only place colours other than Pencil Blue appear. Titles on
them are always large, so foil type keeps at least 3:1 on every cloth.

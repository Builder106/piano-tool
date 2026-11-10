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

A blue field, white pages, ink, and a teacher's two pencils.

| Name | Value | Use |
|---|---|---|
| Field | `#1F4FE0` | the ground the pages lie on; text on it is white |
| Page | `#FFFFFF` | pages, keys |
| Ink | `#111327` | type, engraving, outlines |
| Graphite | `#5B6075` | secondary text on a page |
| Pencil Blue | `#1F4FE0` | the loop, the next note, ticks, what was right |
| Pencil Red | `#F0402A` | corrections and the grade; filled buttons with white type at 18 px and up only |

Colour never carries a meaning alone: loop, tick, ring and line carry it too.
No gradients, glass, glows or cream and warm off-white.

The app's tokens are in `lib/brand/palette.dart`; the site's in
`site/src/styles/tokens.css`.

## Type

| Face | Use |
|---|---|
| Atkinson Hyperlegible Next | everything: wordmark, titles, body, labels, numbers; heavy upright weights for titles, italic only for pencil notes |
| Bravura | music glyphs |

The wordmark is the name set in Atkinson Hyperlegible Next 700 with -0.01em tracking,
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

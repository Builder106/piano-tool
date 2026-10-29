"""Builds the Piano Tool mark: middle C on its ledger line, circled in pencil.

Run `python3 brand/mark.py` from the repo root. It writes the brand SVGs and the
site favicon; `brand/icons.py` rasterises them for every platform.
"""

from math import hypot
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "brand"

PALETTE = {
    "lacquer": "#0A0A0B",
    "paper": "#ECEEF1",
    "ink": "#141519",
    "graphite": "#4E535C",
    "blue": "#2456C8",
    "blue_dark": "#6591E1",
}

# The app's notehead: 10.4 x 8, tilted 20.05 degrees (lib/ui/staff/note_glyph.dart).
HEAD = dict(cx=33, cy=38.5, rx=10.4, ry=8, tilt=-20.05)
LEDGER = (18, 48, 38.5, 2.6)  # x1, x2, y, width
STEM = (41, 7, 2.8, 30.5)  # x, y, width, height

# The pencil loop, drawn the way a teacher circles a note: from the top, round
# anticlockwise, and on past the start as the pencil lifts.
LOOP = [
    ((31, 26.5), (20, 26.3), (12.5, 31.5), (12.5, 39)),
    ((12.5, 39), (12.5, 48.5), (24, 54.5), (35, 54)),
    ((35, 54), (47, 53.5), (55, 46.5), (54.5, 37.5)),
    ((54.5, 37.5), (54, 28.5), (44, 23), (33, 22.8)),
    ((33, 22.8), (25, 22.6), (17.5, 22.4), (11, 25.5)),
]
LOOP_WIDTH = 2.5


def bezier(seg, t):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = seg
    u = 1 - t
    return (
        u**3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t**3 * x3,
        u**3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t**3 * y3,
    )


def sample(segments, steps=48):
    points = [bezier(segments[0], 0)]
    for seg in segments:
        points += [bezier(seg, i / steps) for i in range(1, steps + 1)]
    return points


def width_at(s):
    # Light at the start, full through the turn, thinning as the pencil lifts.
    start = min(1, 0.45 + s / 0.1 * 0.55)
    end = min(1, 0.3 + (1 - s) / 0.25 * 0.7)
    return LOOP_WIDTH * min(start, end)


def ribbon(points, s0, s1):
    """Outline of a tapered stroke over arc-length fraction s0..s1, as a filled path."""
    lengths = [0.0]
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        lengths.append(lengths[-1] + hypot(bx - ax, by - ay))
    total = lengths[-1]
    left, right = [], []
    for i, (x, y) in enumerate(points):
        s = lengths[i] / total
        if not s0 <= s <= s1:
            continue
        ax, ay = points[max(i - 1, 0)]
        bx, by = points[min(i + 1, len(points) - 1)]
        dx, dy = bx - ax, by - ay
        n = hypot(dx, dy)
        nx, ny = -dy / n, dx / n
        h = width_at(s) / 2
        left.append((x + nx * h, y + ny * h))
        right.append((x - nx * h, y - ny * h))
    outline = left + right[::-1]
    d = "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in outline) + "Z"
    return d


def loop_paths():
    points = sample(LOOP)
    # Two halves, so the overshoot that crosses the start never cancels its own fill.
    return [ribbon(points, 0, 0.55), ribbon(points, 0.5, 1)]


def end_caps():
    points = sample(LOOP)
    (x0, y0), (x1, y1) = points[0], points[-1]
    return [(x0, y0, width_at(0) / 2), (x1, y1, width_at(1) / 2)]


def mark_body(ink, blue):
    cx, cy, rx, ry, tilt = HEAD.values()
    x1, x2, ly, lw = LEDGER
    sx, sy, sw, sh = STEM
    parts = [
        f'<line x1="{x1}" y1="{ly}" x2="{x2}" y2="{ly}" stroke="{ink}" stroke-width="{lw}" stroke-linecap="round"/>',
        f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" transform="rotate({tilt} {cx} {cy})" fill="{ink}"/>',
        f'<rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" fill="{ink}"/>',
    ]
    parts += [f'<path d="{d}" fill="{blue}"/>' for d in loop_paths()]
    parts += [f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r:.2f}" fill="{blue}"/>' for x, y, r in end_caps()]
    return "".join(parts)


def svg(body, size=64, view="0 0 64 64", title="Piano Tool"):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="{view}" '
        f'role="img" aria-label="{title}"><title>{title}</title>{body}</svg>\n'
    )


def tile(background, ink, blue, scale=1.0):
    """Square app-icon artwork. Platforms round or mask the corners themselves."""
    offset = 32 * (1 - scale)
    group = f'<g transform="translate({offset:.3f} {offset:.3f}) scale({scale})">{mark_body(ink, blue)}</g>'
    return f'<rect width="64" height="64" fill="{background}"/>{group}'


def main():
    p = PALETTE
    files = {
        OUT / "mark.svg": svg(mark_body(p["ink"], p["blue"])),
        ROOT / "site/src/assets/brand/mark.svg": svg(mark_body(p["ink"], p["blue"])),
        OUT / "mark-dark.svg": svg(mark_body(p["paper"], p["blue_dark"])),
        OUT / "mark-mono.svg": svg(mark_body(p["ink"], p["ink"])),
        OUT / "icon.svg": svg(tile(p["lacquer"], p["paper"], p["blue_dark"], 0.8), size=1024),
        # Maskable icons keep everything inside the centre 80% circle.
        OUT / "icon-maskable.svg": svg(tile(p["lacquer"], p["paper"], p["blue_dark"], 0.66), size=1024),
        # The tab icon follows the browser's colour scheme.
        ROOT / "site/public/favicon.svg": svg(
            "<style>.s{stroke:%s}.f{fill:%s}.b{fill:%s}"
            "@media (prefers-color-scheme:dark){.s{stroke:%s}.f{fill:%s}.b{fill:%s}}</style>"
            % (p["ink"], p["ink"], p["blue"], p["paper"], p["paper"], p["blue_dark"])
            + mark_body("X", "Y")
            .replace('stroke="X"', 'class="s"')
            .replace('fill="X"', 'class="f"')
            .replace('fill="Y"', 'class="b"'),
            size=32,
        ),
    }
    for path, text in files.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        print(path.relative_to(ROOT))


if __name__ == "__main__":
    main()

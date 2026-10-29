"""Rasterises the brand SVGs into every platform's app icons.

Run `python3 brand/mark.py` first, then `python3 brand/icons.py` from the repo
root. Needs rsvg-convert and Pillow.
"""

import io
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ICON = ROOT / "brand/icon.svg"
MASKABLE = ROOT / "brand/icon-maskable.svg"
FAVICON = ROOT / "site/public/favicon.svg"


def render(svg, size):
    png = subprocess.run(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(svg)],
        check=True,
        capture_output=True,
    ).stdout
    return Image.open(io.BytesIO(png)).convert("RGBA")


def opaque(image):
    # The App Store rejects icons with an alpha channel.
    return image.convert("RGB")


def macos(size):
    # macOS draws no mask of its own: a rounded square on the standard 1024 grid.
    art = render(ICON, round(size * 824 / 1024))
    mask = Image.new("L", art.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *art.size), radius=round(art.width * 0.2237), fill=255)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - art.width) // 2
    canvas.paste(art, (offset, offset), mask)
    return canvas


def xcassets(folder, draw):
    contents = json.loads((folder / "Contents.json").read_text())
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        draw(round(points * scale)).save(folder / entry["filename"])


def main():
    res = ROOT / "android/app/src/main/res"
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        render(ICON, size).save(res / f"mipmap-{density}/ic_launcher.png")

    xcassets(ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset", lambda s: opaque(render(ICON, s)))
    xcassets(ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset", macos)

    web = ROOT / "web"
    for size in (192, 512):
        render(ICON, size).save(web / f"icons/Icon-{size}.png")
        render(MASKABLE, size).save(web / f"icons/Icon-maskable-{size}.png")
    render(FAVICON, 32).save(web / "favicon.png")

    sizes = [16, 24, 32, 48, 64, 256]
    render(ICON, 256).save(ROOT / "windows/runner/resources/app_icon.ico", sizes=[(s, s) for s in sizes])

    opaque(render(ICON, 180)).save(ROOT / "site/public/apple-touch-icon.png")

    # The app header draws the mark from a PNG; it has no SVG renderer.
    render(ROOT / "brand/mark-dark.svg", 144).save(ROOT / "assets/art/mark.png")


if __name__ == "__main__":
    main()

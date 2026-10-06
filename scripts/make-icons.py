"""Builds the logo and icon files used by the site from the two source images.

    python scripts/make-icons.py <wordmark.png> <mark.png>

The sources are the LSI Corp wordmark and the square LSI mark, both with a
transparent background. Outputs are written into app/assets and app/web.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent.parent
wordmark = Image.open(sys.argv[1]).convert("RGBA")
mark = Image.open(sys.argv[2]).convert("RGBA")


def trimmed(image):
    return image.crop(image.getbbox())


def fitted(image, width):
    height = round(image.height * width / image.width)
    return image.resize((width, height), Image.LANCZOS)


def tile(image, size, padding, radius):
    """The mark centred on a white rounded square, so it reads on any background."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill="white")
    inner = size - 2 * padding
    scale = min(inner / image.width, inner / image.height)
    art = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    canvas.alpha_composite(art, ((size - art.width) // 2, (size - art.height) // 2))
    return canvas


mark = trimmed(mark)
wordmark = trimmed(wordmark)

assets = root / "app" / "assets"
web = root / "app" / "web"
assets.mkdir(exist_ok=True)

fitted(mark, 256).save(assets / "logo-mark.png", optimize=True)
fitted(wordmark, 900).save(assets / "logo-full.png", optimize=True)

tile(mark, 64, 7, 12).save(web / "favicon.png", optimize=True)
tile(mark, 192, 22, 36).save(web / "icon-192.png", optimize=True)
tile(mark, 512, 60, 96).save(web / "icon-512.png", optimize=True)
# iOS applies its own corner mask, so this one is a full white square.
tile(mark, 180, 22, 0).save(web / "apple-touch-icon.png", optimize=True)
fitted(mark, 240).save(web / "logo-mark.png", optimize=True)

print("Logo and icon files written.")

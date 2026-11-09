#!/usr/bin/env python3
"""
tools/make_icon.py
Generates the Anilov app icons.
- assets/icon/icon.png: 1024x1024 rounded-square icon with a diagonal gradient
  from deep indigo (#1B1464) to violet (#7C3AED), centered white stylized play triangle
  with a small sparkle.
- assets/icon/icon_foreground.png: 1024x1024 transparent foreground-only version for
  adaptive icons.
"""

import math
import os
import struct
import sys
import zlib
from pathlib import Path

OUTPUT_DIR = Path("assets/icon")
ICON_PATH = OUTPUT_DIR / "icon.png"
FOREGROUND_PATH = OUTPUT_DIR / "icon_foreground.png"

# Colors
INDIGO = (27, 20, 100)       # #1B1464
VIOLET = (124, 58, 237)      # #7C3AED
WHITE = (255, 255, 255)
WHITE_A = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

def generate_with_pillow():
    from PIL import Image, ImageDraw

    size = 1024
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Create diagonal gradient background
    # Smooth gradient from (0,0) INDIGO to (size, size) VIOLET
    grad_small = Image.new("RGBA", (256, 256))
    small_pixels = grad_small.load()
    for y in range(256):
        for x in range(256):
            t = (x + y) / (2.0 * 255.0)
            r = int(INDIGO[0] + t * (VIOLET[0] - INDIGO[0]))
            g = int(INDIGO[1] + t * (VIOLET[1] - INDIGO[1]))
            b = int(INDIGO[2] + t * (VIOLET[2] - INDIGO[2]))
            small_pixels[x, y] = (r, g, b, 255)

    gradient = grad_small.resize((size, size), Image.Resampling.BICUBIC)

    # 2. Rounded square mask for full launcher icon
    mask = Image.new("L", (size, size), 0)
    draw_mask = ImageDraw.Draw(mask)
    margin = 32
    corner_radius = 210
    draw_mask.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=255,
    )

    icon_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_img.paste(gradient, (0, 0), mask)

    # 3. Stylized Play Triangle & Sparkle coordinates
    # Play triangle centered visually around (500, 512)
    # Points: top-left, bottom-left, right tip
    triangle_pts = [
        (420, 370),
        (420, 654),
        (660, 512),
    ]

    # Sparkle: 4-pointed star near top-right of triangle
    def get_star_points(cx, cy, outer_r, inner_r):
        pts = []
        for i in range(8):
            angle = i * (math.pi / 4.0) - (math.pi / 2.0)
            r = outer_r if (i % 2 == 0) else inner_r
            pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        return pts

    star_pts = get_star_points(cx=660, cy=380, outer_r=48, inner_r=12)

    # Draw on main icon
    draw_icon = ImageDraw.Draw(icon_img)
    draw_icon.polygon(triangle_pts, fill=WHITE_A)
    draw_icon.polygon(star_pts, fill=WHITE_A)

    # 4. Adaptive icon foreground: transparent canvas with white triangle & sparkle
    foreground_img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw_fg = ImageDraw.Draw(foreground_img)
    draw_fg.polygon(triangle_pts, fill=WHITE_A)
    draw_fg.polygon(star_pts, fill=WHITE_A)

    # Save outputs
    icon_img.save(ICON_PATH, format="PNG")
    foreground_img.save(FOREGROUND_PATH, format="PNG")
    print(f"Generated icons using Pillow: {ICON_PATH} and {FOREGROUND_PATH}")


def generate_fallback_png():
    """Fallback generator using standard library zlib if Pillow is not installed."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    def write_png(path, width, height, r, g, b, a):
        raw = bytearray()
        for _ in range(height):
            raw.append(0)  # filter type None
            for _ in range(width):
                raw.extend([r, g, b, a])

        def chunk(tag, data):
            c = tag + data
            crc = struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
            return struct.pack(">I", len(data)) + c + crc

        png = (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw)))
            + chunk(b"IEND", b"")
        )
        with open(path, "wb") as f:
            f.write(png)

    # Fallback minimal valid PNGs
    write_png(ICON_PATH, 512, 512, INDIGO[0], INDIGO[1], INDIGO[2], 255)
    write_png(FOREGROUND_PATH, 512, 512, 255, 255, 255, 255)
    print(f"Generated fallback icons: {ICON_PATH} and {FOREGROUND_PATH}")


SOURCE_LAUNCHER = Path("assets/images/anizen_launcher_icon.png")

def sync_from_anizen_launcher():
    if SOURCE_LAUNCHER.exists():
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        import shutil
        shutil.copyfile(SOURCE_LAUNCHER, ICON_PATH)
        shutil.copyfile(SOURCE_LAUNCHER, FOREGROUND_PATH)
        print(f"Synced branding icon from {SOURCE_LAUNCHER} to {ICON_PATH} and {FOREGROUND_PATH}")
        return True
    return False

def main():
    if sync_from_anizen_launcher():
        return
    try:
        import PIL
        generate_with_pillow()
    except ImportError:
        print("Pillow not installed locally; creating valid fallback PNGs.")
        print("GitHub Actions CI will re-generate full high-res icons with Pillow.")
        generate_fallback_png()

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate Wipe app icon as .icns using Pillow + iconutil."""

import math
import os
import subprocess
import tempfile
from PIL import Image, ImageDraw, ImageFont

SIZES = [16, 32, 64, 128, 256, 512, 1024]


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = size * 0.1
    r = size * 0.22

    # Rounded-rect background — dark charcoal gradient feel
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=r,
        fill=(30, 30, 32, 255),
    )

    # Inner subtle border
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=r,
        outline=(255, 255, 255, 20),
        width=max(1, size // 128),
    )

    cx, cy = size / 2, size / 2

    # Draw a 4-point sparkle
    def sparkle(x, y, arm, thick, color):
        pts_v = [(x, y - arm), (x + thick, y), (x, y + arm), (x - thick, y)]
        pts_h = [(x - arm, y), (x, y - thick), (x + arm, y), (x, y + thick)]
        draw.polygon(pts_v, fill=color)
        draw.polygon(pts_h, fill=color)

    # Main sparkle — white
    main_arm = size * 0.24
    main_thick = size * 0.045
    sparkle(cx, cy - size * 0.02, main_arm, main_thick, (255, 255, 255, 240))

    # Small sparkle top-right
    s2_arm = size * 0.09
    s2_thick = size * 0.018
    sparkle(cx + size * 0.22, cy - size * 0.2, s2_arm, s2_thick, (255, 255, 255, 180))

    # Tiny sparkle bottom-left
    s3_arm = size * 0.06
    s3_thick = size * 0.012
    sparkle(cx - size * 0.2, cy + size * 0.18, s3_arm, s3_thick, (255, 255, 255, 120))

    # Tiny dot accents
    dot_r = max(1, size // 64)
    for dx, dy, alpha in [(0.15, -0.28, 100), (-0.28, -0.05, 80), (0.25, 0.22, 60)]:
        x, y = cx + size * dx, cy + size * dy
        draw.ellipse([x - dot_r, y - dot_r, x + dot_r, y + dot_r], fill=(255, 255, 255, alpha))

    return img


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    resources_dir = os.path.join(project_dir, "Resources")
    os.makedirs(resources_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        iconset = os.path.join(tmpdir, "AppIcon.iconset")
        os.makedirs(iconset)

        for size in SIZES:
            img = draw_icon(size)
            # 1x
            if size <= 512:
                name = f"icon_{size}x{size}.png"
                img.save(os.path.join(iconset, name))
            # 2x (half-size label)
            half = size // 2
            if half >= 16:
                name = f"icon_{half}x{half}@2x.png"
                img.save(os.path.join(iconset, name))

        icns_path = os.path.join(resources_dir, "AppIcon.icns")
        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns_path], check=True)
        print(f"Created {icns_path}")


if __name__ == "__main__":
    main()

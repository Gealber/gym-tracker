"""Generate the Gym launcher icon: adaptive vector drawable + legacy PNGs.

Geometry is on the 108 x 108 adaptive-icon canvas, centered at (54, 54);
the dumbbell is rotated -30 degrees (rising) and stays inside the 66 unit
safe circle.

Run from the repo root (needs Pillow):
    python3 tool/gen_icon.py android/app/src/main/res /tmp/icon_preview.png
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = "#2A1840"
FOREGROUND = "#FFD60A"
ROTATION = -30.0
CENTER = 54.0

# (left, top, right, bottom, corner radius) on the 108 canvas, unrotated.
SHAPES = [
    (38.0, 51.0, 70.0, 57.0, 2.0),  # handle
    (31.0, 40.0, 39.0, 68.0, 3.0),  # inner plates
    (69.0, 40.0, 77.0, 68.0, 3.0),
    (26.0, 45.0, 31.0, 63.0, 2.0),  # outer plates
    (77.0, 45.0, 82.0, 63.0, 2.0),
]

LEGACY_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def rounded_rect_path(left, top, right, bottom, radius):
    """SVG/VectorDrawable path data for a rounded rectangle."""
    return (
        f"M{left + radius},{top} H{right - radius} "
        f"A{radius},{radius} 0 0 1 {right},{top + radius} V{bottom - radius} "
        f"A{radius},{radius} 0 0 1 {right - radius},{bottom} H{left + radius} "
        f"A{radius},{radius} 0 0 1 {left},{bottom - radius} V{top + radius} "
        f"A{radius},{radius} 0 0 1 {left + radius},{top} Z"
    )


def foreground_xml():
    paths = "\n".join(
        f'        <path android:fillColor="{FOREGROUND}"\n'
        f'            android:pathData="{rounded_rect_path(*shape)}" />'
        for shape in SHAPES
    )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Generated: yellow dumbbell, rising, for the Gym launcher icon. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="108"\n'
        '    android:viewportHeight="108">\n'
        f'    <group android:rotation="{ROTATION:g}"\n'
        f'        android:pivotX="{CENTER:g}"\n'
        f'        android:pivotY="{CENTER:g}">\n'
        f"{paths}\n"
        "    </group>\n"
        "</vector>\n"
    )


ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""

COLORS_XML = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{BACKGROUND}</color>
</resources>
"""


def render_master(size):
    """Legacy icon: rounded purple square, the central 72 units of the
    adaptive canvas scaled to fill it."""
    scale = size / 72.0
    offset = -18.0 * scale
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    for left, top, right, bottom, radius in SHAPES:
        draw.rounded_rectangle(
            (
                left * scale + offset,
                top * scale + offset,
                right * scale + offset,
                bottom * scale + offset,
            ),
            radius=radius * scale,
            fill=FOREGROUND,
        )
    # PIL rotates counter-clockwise for positive angles; Android's rotation is
    # clockwise, so the sign flips.
    layer = layer.rotate(-ROTATION, resample=Image.BICUBIC, center=(size / 2, size / 2))
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(icon).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=size * 0.22, fill=BACKGROUND
    )
    icon.alpha_composite(layer)
    return icon


def write_resources(res_dir):
    (res_dir / "drawable").mkdir(exist_ok=True)
    (res_dir / "drawable" / "ic_launcher_foreground.xml").write_text(foreground_xml())
    (res_dir / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (res_dir / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(ADAPTIVE_XML)
    (res_dir / "values" / "colors.xml").write_text(COLORS_XML)
    master = render_master(1024)
    for density, pixels in LEGACY_SIZES.items():
        master.resize((pixels, pixels), Image.LANCZOS).save(
            res_dir / f"mipmap-{density}" / "ic_launcher.png", optimize=True
        )
    return master


def main():
    res_dir = Path(sys.argv[1])
    preview_path = Path(sys.argv[2])
    master = write_resources(res_dir)
    master.resize((256, 256), Image.LANCZOS).save(preview_path)


if __name__ == "__main__":
    main()

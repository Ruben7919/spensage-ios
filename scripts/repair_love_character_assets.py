#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CHAR_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2" / "characters"

CHARACTER_BASES = {
    "tikki": {
        "base_filename": "tikki_happy_v2.png",
        "glow": (255, 213, 197),
        "heart": (245, 123, 136),
        "blush": (255, 174, 188),
    },
    "mei": {
        "base_filename": "mei_happy_v2.png",
        "glow": (255, 228, 196),
        "heart": (239, 130, 148),
        "blush": (255, 191, 205),
    },
    "manchas": {
        "base_filename": "manchas_happy_v2.png",
        "glow": (255, 216, 191),
        "heart": (236, 115, 136),
        "blush": (255, 178, 193),
    },
}


def add_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(radius // 2, 1)))
    canvas.alpha_composite(overlay)


def draw_heart(draw: ImageDraw.ImageDraw, center: tuple[int, int], size: int, fill: tuple[int, int, int, int]) -> None:
    x, y = center
    radius = size // 3
    top = y - size // 6
    draw.ellipse((x - radius - radius, top - radius, x - radius, top + radius), fill=fill)
    draw.ellipse((x, top - radius, x + radius + radius, top + radius), fill=fill)
    draw.polygon(
        [
            (x - size // 2, y),
            (x, y + size // 2),
            (x + size // 2, y),
            (x, y + size),
        ],
        fill=fill,
    )


def add_blush(draw: ImageDraw.ImageDraw, center: tuple[int, int], size: tuple[int, int], fill: tuple[int, int, int]) -> None:
    x, y = center
    w, h = size
    draw.ellipse((x - w // 2, y - h // 2, x + w // 2, y + h // 2), fill=fill + (56,))


def create_love_variant(character_id: str, base_filename: str, glow: tuple[int, int, int], heart: tuple[int, int, int], blush: tuple[int, int, int]) -> Image.Image:
    sprite = Image.open(CHAR_ROOT / base_filename).convert("RGBA")
    bbox = sprite.getbbox()
    if bbox is None:
        raise ValueError(f"Sprite {base_filename} has no visible content")

    x0, y0, x1, y1 = bbox
    width = x1 - x0
    height = y1 - y0
    center_x = x0 + width // 2
    face_y = y0 + int(height * 0.30)

    canvas = sprite.copy()
    add_glow(canvas, (center_x, y0 + int(height * 0.18)), max(int(width * 0.16), 52), glow, 72)

    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    blush_y = face_y + int(height * 0.07)
    blush_dx = int(width * 0.12)
    add_blush(draw, (center_x - blush_dx, blush_y), (int(width * 0.10), int(height * 0.05)), blush)
    add_blush(draw, (center_x + blush_dx, blush_y), (int(width * 0.10), int(height * 0.05)), blush)

    heart_specs = [
        ((center_x + int(width * 0.15), y0 + int(height * 0.10)), int(width * 0.10)),
        ((center_x + int(width * 0.27), y0 + int(height * 0.03)), int(width * 0.08)),
        ((center_x - int(width * 0.05), y0 + int(height * 0.04)), int(width * 0.06)),
    ]

    for heart_center, size in heart_specs:
        add_glow(canvas, heart_center, max(int(size * 1.3), 24), glow, 62)
        draw_heart(draw, heart_center, max(size, 28), heart + (244,))

    # Small highlight spark to keep the variant feeling premium rather than flat.
    spark_x = center_x + int(width * 0.05)
    spark_y = y0 + int(height * 0.16)
    draw.line((spark_x - 10, spark_y, spark_x + 10, spark_y), fill=(255, 241, 214, 200), width=3)
    draw.line((spark_x, spark_y - 10, spark_x, spark_y + 10), fill=(255, 241, 214, 200), width=3)

    canvas.alpha_composite(overlay)

    # The inherited Mei love asset shipped with an opaque background.
    # Keeping the base sprite alpha guarantees transparent edges again.
    alpha = sprite.getchannel("A")
    canvas.putalpha(alpha)
    return canvas


def main() -> None:
    for character_id, spec in CHARACTER_BASES.items():
        result = create_love_variant(character_id, **spec)
        output_path = CHAR_ROOT / f"{character_id}_love_v2.png"
        result.save(output_path)
        print(f"updated {output_path}")


if __name__ == "__main__":
    main()

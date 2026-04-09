#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
CHAR_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2" / "characters"

SEASONS = ("halloween", "holiday", "new_year")
EXPRESSIONS = (
    "neutral",
    "happy",
    "thinking",
    "warning",
    "proud",
    "shocked",
    "sad",
    "angry",
    "excited",
    "sleepy",
    "confused",
    "love",
)

CHARACTER_ACCENTS = {
    "tikki": (230, 72, 63),
    "mei": (68, 130, 215),
    "manchas": (78, 176, 92),
}

ANCHORS = {
    "tikki": {"hat": (580, 156), "brim": (510, 242), "collar": (520, 706), "sparkle": [(214, 186), (824, 214), (768, 820)]},
    "mei": {"hat": (560, 126), "brim": (520, 210), "collar": (562, 680), "sparkle": [(208, 208), (824, 176), (788, 786)]},
    "manchas": {"hat": (556, 158), "brim": (516, 246), "collar": (532, 676), "sparkle": [(210, 220), (836, 208), (804, 782)]},
}


def add_shadow(canvas: Image.Image, overlay: Image.Image, blur_radius: int = 14, offset: tuple[int, int] = (10, 12), alpha: int = 96) -> None:
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    tinted = Image.new("RGBA", overlay.size, (24, 18, 18, 0))
    alpha_mask = overlay.getchannel("A").point(lambda value: min(alpha, value))
    tinted.putalpha(alpha_mask)
    shadow.alpha_composite(tinted, offset)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    canvas.alpha_composite(shadow)


def draw_star(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, fill: tuple[int, int, int]) -> None:
    x, y = center
    draw.line((x - radius, y, x + radius, y), fill=fill + (220,), width=4)
    draw.line((x, y - radius, x, y + radius), fill=fill + (220,), width=4)
    draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(255, 255, 255, 230))


def draw_witch_hat(canvas: Image.Image, character: str, accent: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    hat_x, hat_y = ANCHORS[character]["hat"]
    brim_x, brim_y = ANCHORS[character]["brim"]

    draw.polygon(
        [
            (hat_x - 88, hat_y + 122),
            (hat_x - 12, hat_y - 62),
            (hat_x + 116, hat_y + 96),
        ],
        fill=(44, 32, 60, 255),
        outline=(20, 12, 22, 255),
    )
    draw.ellipse(
        (brim_x - 150, brim_y - 34, brim_x + 150, brim_y + 34),
        fill=(56, 42, 78, 255),
        outline=(18, 12, 20, 255),
        width=5,
    )
    draw.rectangle((hat_x - 42, hat_y + 66, hat_x + 74, hat_y + 98), fill=accent + (255,))
    draw.rounded_rectangle((hat_x + 10, hat_y + 58, hat_x + 54, hat_y + 106), radius=10, outline=(255, 224, 146, 255), width=5)
    add_shadow(canvas, overlay, blur_radius=16, offset=(6, 10), alpha=90)
    canvas.alpha_composite(overlay)

    effects = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sparkle = ImageDraw.Draw(effects)
    for point in ANCHORS[character]["sparkle"]:
        draw_star(sparkle, point, 16, (255, 204, 114))
    canvas.alpha_composite(effects.filter(ImageFilter.GaussianBlur(radius=1)))


def draw_santa_hat(canvas: Image.Image, character: str, accent: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    hat_x, hat_y = ANCHORS[character]["hat"]
    brim_x, brim_y = ANCHORS[character]["brim"]

    draw.polygon(
        [
            (hat_x - 112, hat_y + 84),
            (hat_x - 10, hat_y - 82),
            (hat_x + 132, hat_y + 54),
        ],
        fill=(214, 74, 78, 255),
        outline=(120, 34, 36, 255),
    )
    draw.rounded_rectangle(
        (brim_x - 156, brim_y - 34, brim_x + 156, brim_y + 34),
        radius=28,
        fill=(247, 248, 245, 255),
        outline=(214, 216, 214, 255),
        width=4,
    )
    draw.ellipse((hat_x + 104, hat_y + 22, hat_x + 180, hat_y + 98), fill=(247, 248, 245, 255), outline=(214, 216, 214, 255), width=4)
    draw.rectangle((hat_x - 34, hat_y + 42, hat_x + 70, hat_y + 70), fill=accent + (255,))
    add_shadow(canvas, overlay, blur_radius=14, offset=(6, 9), alpha=84)
    canvas.alpha_composite(overlay)

    flakes = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    flake_draw = ImageDraw.Draw(flakes)
    for point in ANCHORS[character]["sparkle"]:
        draw_star(flake_draw, point, 14, (255, 255, 255))
    canvas.alpha_composite(flakes.filter(ImageFilter.GaussianBlur(radius=1)))


def draw_party_hat(canvas: Image.Image, character: str, accent: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    hat_x, hat_y = ANCHORS[character]["hat"]
    brim_x, brim_y = ANCHORS[character]["brim"]

    draw.polygon(
        [
            (hat_x - 72, hat_y + 118),
            (hat_x + 2, hat_y - 70),
            (hat_x + 114, hat_y + 94),
        ],
        fill=accent + (255,),
        outline=(92, 58, 20, 255),
    )
    for offset in (-42, -8, 26, 60):
        draw.line((hat_x + offset, hat_y + 94, hat_x + offset + 52, hat_y - 24), fill=(255, 230, 170, 220), width=8)
    draw.ellipse((hat_x - 18, hat_y - 96, hat_x + 34, hat_y - 44), fill=(255, 226, 146, 255), outline=(255, 248, 225, 255), width=4)
    draw.rounded_rectangle(
        (brim_x - 126, brim_y - 18, brim_x + 126, brim_y + 18),
        radius=18,
        fill=(255, 244, 215, 255),
        outline=(230, 200, 128, 255),
        width=3,
    )
    add_shadow(canvas, overlay, blur_radius=14, offset=(6, 9), alpha=84)
    canvas.alpha_composite(overlay)

    confetti = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    confetti_draw = ImageDraw.Draw(confetti)
    colors = [(255, 200, 88), (97, 172, 220), (112, 201, 160)]
    for idx, point in enumerate(ANCHORS[character]["sparkle"]):
        draw_star(confetti_draw, point, 14, colors[idx % len(colors)])
        x, y = point
        confetti_draw.ellipse((x + 22, y - 18, x + 34, y - 6), fill=colors[(idx + 1) % len(colors)] + (220,))
        confetti_draw.rounded_rectangle((x - 28, y + 18, x - 10, y + 28), radius=4, fill=colors[(idx + 2) % len(colors)] + (220,))
    canvas.alpha_composite(confetti.filter(ImageFilter.GaussianBlur(radius=1)))


def draw_seasonal_collar(canvas: Image.Image, character: str, season: str, accent: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = ANCHORS[character]["collar"]
    if season == "halloween":
        gem = (255, 145, 76, 255)
        trim = (118, 204, 148, 255)
    elif season == "holiday":
        gem = (196, 54, 64, 255)
        trim = (92, 176, 142, 255)
    else:
        gem = (255, 208, 112, 255)
        trim = (52, 118, 204, 255)

    draw.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=gem, outline=(255, 248, 228, 255), width=4)
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(255, 255, 255, 230))
    draw.rounded_rectangle((cx - 48, cy - 8, cx - 18, cy + 8), radius=8, fill=trim, outline=(255, 245, 222, 220), width=2)
    draw.rounded_rectangle((cx + 18, cy - 8, cx + 48, cy + 8), radius=8, fill=trim, outline=(255, 245, 222, 220), width=2)
    canvas.alpha_composite(overlay)


def apply_season(base: Image.Image, character: str, season: str) -> Image.Image:
    image = base.copy().convert("RGBA")
    accent = CHARACTER_ACCENTS[character]
    if season == "halloween":
        draw_witch_hat(image, character, accent)
    elif season == "holiday":
        draw_santa_hat(image, character, accent)
    else:
        draw_party_hat(image, character, accent)
    draw_seasonal_collar(image, character, season, accent)
    return image


def output_name(character: str, expression: str, season: str) -> str:
    suffix = {
        "halloween": "halloween",
        "holiday": "holiday",
        "new_year": "new_year",
    }[season]
    return f"{character}_{expression}_{suffix}_v2.png"


def main() -> None:
    generated = 0
    for character in ("tikki", "mei", "manchas"):
        for expression in EXPRESSIONS:
            base_path = CHAR_ROOT / f"{character}_{expression}_v2.png"
            base = Image.open(base_path).convert("RGBA")
            for season in SEASONS:
                out_path = CHAR_ROOT / output_name(character, expression, season)
                apply_season(base, character, season).save(out_path)
                generated += 1
                print(f"updated {out_path}")
    print(f"generated {generated} seasonal sprites")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRAND_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2"
CHAR_ROOT = BRAND_ROOT / "characters"
GUIDE_ROOT = BRAND_ROOT / "guides"
LOGO_ROOT = BRAND_ROOT / "logo"
APPICON_ROOT = ROOT / "SpendSage" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"

ICON_SIZE = 1024
SPLASH_SIZE = 1024


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / max(size - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3)) + (255,)
        draw.line((0, y, size, y), fill=color)
    return image


def add_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=radius // 2))
    canvas.alpha_composite(overlay)


def add_shadow(canvas: Image.Image, box: tuple[int, int, int, int], alpha: int = 60) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.ellipse(box, fill=(20, 35, 38, alpha))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=16))
    canvas.alpha_composite(overlay)


def paste_sprite(canvas: Image.Image, filename: str, box: tuple[int, int, int, int]) -> None:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    target_w = box[2] - box[0]
    target_h = box[3] - box[1]
    sprite.thumbnail((target_w, target_h), Image.LANCZOS)
    x = box[0] + (target_w - sprite.width) // 2
    y = box[1] + (target_h - sprite.height)
    canvas.alpha_composite(sprite, (x, y))


def tint_sprite(filename: str, fill: tuple[int, int, int], alpha_scale: float = 1.0) -> Image.Image:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    r, g, b, a = sprite.split()
    alpha = a.point(lambda value: int(max(0, min(255, value * alpha_scale))))
    tinted = Image.new("RGBA", sprite.size, fill + (0,))
    tinted.putalpha(alpha)
    return tinted


def draw_coin(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int) -> None:
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(255, 209, 88, 255), outline=(212, 144, 28, 255), width=10)
    draw.ellipse((x - radius + 26, y - radius + 26, x + radius - 26, y + radius - 26), outline=(255, 236, 181, 255), width=8)
    draw.ellipse((x - 18, y - 18, x + 18, y + 18), fill=(255, 236, 181, 255), outline=(212, 144, 28, 255), width=6)


def draw_yarn_ball(draw: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, fill: tuple[int, int, int]) -> None:
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill + (255,), outline=(255, 255, 255, 110), width=4)
    for offset, angle in ((0.7, 0), (0.55, 28), (0.5, -26), (0.35, 64)):
        inset = int(radius * (1 - offset))
        draw.ellipse((x - radius + inset, y - radius + int(radius * 0.42), x + radius - inset, y + radius - int(radius * 0.42)), outline=(255, 255, 255, 95), width=3)
    draw.arc((x - radius - 24, y - 8, x + radius + 42, y + radius + 48), start=12, end=94, fill=fill + (255,), width=6)


def create_app_icon() -> Image.Image:
    canvas = vertical_gradient(ICON_SIZE, (17, 89, 92), (126, 211, 199))
    add_glow(canvas, (290, 232), 250, (178, 236, 229), 165)
    add_glow(canvas, (752, 742), 260, (255, 224, 162), 125)
    draw = ImageDraw.Draw(canvas)

    add_shadow(canvas, (288, 700, 836, 848), alpha=88)
    draw_coin(draw, (768, 738), 118)
    add_glow(canvas, (768, 738), 168, (255, 219, 138), 110)

    paste_sprite(canvas, "tikki_proud_v2.png", (132, 164, 826, 900))
    add_glow(canvas, (480, 368), 210, (255, 235, 196), 78)
    return canvas


def create_app_icon_dark() -> Image.Image:
    canvas = vertical_gradient(ICON_SIZE, (14, 28, 35), (31, 64, 77))
    add_glow(canvas, (286, 218), 240, (82, 166, 171), 110)
    add_glow(canvas, (760, 744), 210, (240, 176, 92), 88)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((118, 116, 906, 908), radius=244, outline=(236, 246, 245, 34), width=5)
    add_shadow(canvas, (284, 700, 846, 850), alpha=118)
    draw_coin(draw, (766, 740), 118)
    add_glow(canvas, (766, 740), 154, (255, 214, 125), 92)

    paste_sprite(canvas, "tikki_proud_v2.png", (128, 156, 824, 906))
    add_glow(canvas, (488, 362), 196, (255, 232, 197), 52)
    return canvas


def create_app_icon_tinted() -> Image.Image:
    canvas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (36, 63, 72, 255))
    add_glow(canvas, (512, 270), 280, (84, 156, 162), 108)
    add_glow(canvas, (736, 760), 190, (255, 205, 122), 70)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((112, 112, 912, 912), radius=240, outline=(255, 255, 255, 36), width=5)
    draw.ellipse((618, 586, 876, 844), fill=(244, 233, 214, 255))
    draw.ellipse((646, 614, 848, 816), outline=(36, 63, 72, 255), width=18)
    draw.line((748, 666, 748, 764), fill=(36, 63, 72, 255), width=18)
    draw.line((704, 716, 792, 716), fill=(36, 63, 72, 255), width=18)

    silhouette = tint_sprite("tikki_proud_v2.png", (244, 233, 214))
    silhouette.thumbnail((670, 740), Image.LANCZOS)
    dest_x = 136 + (670 - silhouette.width) // 2
    dest_y = 160 + (740 - silhouette.height)
    canvas.alpha_composite(silhouette, (dest_x, dest_y))

    # Simple whisker/eye accents to keep the tinted icon legible at small sizes.
    eye_y = 448
    draw.ellipse((442, eye_y, 474, eye_y + 28), fill=(36, 63, 72, 255))
    draw.ellipse((530, eye_y, 562, eye_y + 28), fill=(36, 63, 72, 255))
    draw.line((488, 500, 504, 514), fill=(36, 63, 72, 255), width=10)
    draw.line((474, 530, 390, 518), fill=(36, 63, 72, 255), width=8)
    draw.line((474, 552, 392, 560), fill=(36, 63, 72, 255), width=8)
    draw.line((528, 530, 610, 518), fill=(36, 63, 72, 255), width=8)
    draw.line((528, 552, 610, 560), fill=(36, 63, 72, 255), width=8)
    return canvas


def create_splash_guide() -> Image.Image:
    canvas = vertical_gradient(SPLASH_SIZE, (233, 245, 244), (255, 244, 235))
    add_glow(canvas, (232, 226), 220, (173, 236, 227), 145)
    add_glow(canvas, (820, 190), 220, (255, 225, 165), 118)
    add_glow(canvas, (516, 772), 240, (189, 227, 243), 90)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((82, 120, 942, 874), radius=80, fill=(249, 252, 251, 228), outline=(210, 229, 224, 255), width=4)
    draw.rounded_rectangle((122, 164, 902, 834), radius=68, outline=(232, 240, 238, 255), width=2)

    draw_yarn_ball(draw, (256, 724), 60, (99, 179, 191))
    draw_yarn_ball(draw, (512, 776), 58, (255, 198, 96))
    draw_yarn_ball(draw, (756, 720), 60, (121, 209, 191))

    add_shadow(canvas, (144, 632, 368, 736))
    add_shadow(canvas, (402, 684, 622, 786))
    add_shadow(canvas, (644, 632, 880, 738))

    paste_sprite(canvas, "tikki_proud_v2.png", (108, 250, 380, 696))
    paste_sprite(canvas, "mei_neutral_v2.png", (358, 200, 674, 744))
    paste_sprite(canvas, "manchas_proud_v2.png", (620, 244, 908, 710))

    for point in [(196, 180), (284, 244), (820, 202), (736, 282), (520, 140), (868, 628)]:
        x, y = point
        draw.line((x - 10, y, x + 10, y), fill=(255, 205, 107, 190), width=4)
        draw.line((x, y - 10, x, y + 10), fill=(255, 205, 107, 190), width=4)

    return canvas


def create_loading_guide() -> Image.Image:
    canvas = vertical_gradient(SPLASH_SIZE, (236, 245, 245), (250, 239, 228))
    add_glow(canvas, (246, 214), 210, (176, 235, 227), 140)
    add_glow(canvas, (820, 224), 228, (255, 222, 161), 112)
    add_glow(canvas, (520, 786), 250, (170, 219, 232), 96)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((86, 108, 938, 896), radius=94, fill=(250, 252, 252, 236), outline=(209, 228, 224, 255), width=4)
    draw.rounded_rectangle((132, 154, 892, 848), radius=72, outline=(230, 239, 237, 255), width=2)

    for center, radius, color in (
        ((260, 744), 64, (104, 182, 193)),
        ((514, 786), 62, (255, 196, 96)),
        ((760, 742), 64, (121, 208, 192)),
    ):
        draw_yarn_ball(draw, center, radius, color)

    add_shadow(canvas, (128, 648, 378, 760))
    add_shadow(canvas, (376, 688, 654, 802))
    add_shadow(canvas, (640, 642, 902, 758))

    paste_sprite(canvas, "tikki_excited_v2.png", (102, 242, 382, 724))
    paste_sprite(canvas, "mei_happy_v2.png", (352, 178, 676, 774))
    paste_sprite(canvas, "manchas_excited_v2.png", (620, 236, 914, 730))

    for point in [(188, 190), (292, 252), (828, 198), (740, 272), (514, 152), (866, 622), (438, 860)]:
        x, y = point
        draw.line((x - 11, y, x + 11, y), fill=(255, 208, 112, 190), width=4)
        draw.line((x, y - 11, x, y + 11), fill=(255, 208, 112, 190), width=4)

    return canvas


def write_universal_appicon_set(any_icon: Image.Image, dark_icon: Image.Image, tinted_icon: Image.Image) -> None:
    APPICON_ROOT.mkdir(parents=True, exist_ok=True)

    for stale in APPICON_ROOT.glob("*.png"):
        stale.unlink()

    outputs = {
        "icon-any-1024.png": any_icon,
        "icon-dark-1024.png": dark_icon,
        "icon-tinted-1024.png": tinted_icon,
    }
    for filename, image in outputs.items():
        path = APPICON_ROOT / filename
        image.save(path)
        print(f"updated {path}")

    contents = {
        "images": [
            {
                "filename": "icon-any-1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
            {
                "filename": "icon-dark-1024.png",
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark",
                    }
                ],
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
            {
                "filename": "icon-tinted-1024.png",
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "tinted",
                    }
                ],
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            },
        ],
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    (APPICON_ROOT / "Contents.json").write_text(f"{json.dumps(contents, indent=2)}\n")


def main() -> None:
    GUIDE_ROOT.mkdir(parents=True, exist_ok=True)
    LOGO_ROOT.mkdir(parents=True, exist_ok=True)

    splash = create_splash_guide()
    splash_path = GUIDE_ROOT / "guide_25_splash_team_v2.png"
    splash.save(splash_path)
    print(f"generated {splash_path}")

    loading = create_loading_guide()
    loading_path = GUIDE_ROOT / "guide_26_loading_yarn_team_v2.png"
    loading.save(loading_path)
    print(f"generated {loading_path}")

    icon = create_app_icon()
    icon_dark = create_app_icon_dark()
    icon_tinted = create_app_icon_tinted()

    logo_outputs = {
        "app_icon_v2.png": icon,
        "app_icon_dark_v2.png": icon_dark,
        "app_icon_tinted_v2.png": icon_tinted,
    }
    for filename, image in logo_outputs.items():
        path = LOGO_ROOT / filename
        image.save(path)
        print(f"generated {path}")

    write_universal_appicon_set(icon, icon_dark, icon_tinted)


if __name__ == "__main__":
    main()

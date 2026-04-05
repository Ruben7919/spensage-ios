#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


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


def cropped_sprite(filename: str) -> Image.Image:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    bbox = sprite.getbbox()
    if bbox is None:
        return sprite
    return sprite.crop(bbox)


def relative_crop(
    sprite: Image.Image,
    left: float = 0.0,
    top: float = 0.0,
    right: float = 1.0,
    bottom: float = 1.0,
) -> Image.Image:
    width, height = sprite.size
    crop_box = (
        int(width * left),
        int(height * top),
        int(width * right),
        int(height * bottom),
    )
    return sprite.crop(crop_box)


def paste_peeking_sprite(
    canvas: Image.Image,
    filename: str,
    box: tuple[int, int, int, int],
    *,
    crop: tuple[float, float, float, float],
    mirror: bool = False,
    tint: tuple[int, int, int] | None = None,
    alpha_scale: float = 1.0,
) -> None:
    sprite = cropped_sprite(filename)
    sprite = relative_crop(sprite, *crop)
    if mirror:
        sprite = ImageOps.mirror(sprite)
    if tint is not None:
        _, _, _, alpha = sprite.split()
        alpha = alpha.point(lambda value: int(max(0, min(255, value * alpha_scale))))
        tinted = Image.new("RGBA", sprite.size, tint + (0,))
        tinted.putalpha(alpha)
        sprite = tinted
    elif alpha_scale != 1.0:
        red, green, blue, alpha = sprite.split()
        alpha = alpha.point(lambda value: int(max(0, min(255, value * alpha_scale))))
        sprite = Image.merge("RGBA", (red, green, blue, alpha))

    target_w = box[2] - box[0]
    target_h = box[3] - box[1]
    sprite.thumbnail((target_w, target_h), Image.LANCZOS)
    x = box[0] + (target_w - sprite.width) // 2
    y = box[1] + (target_h - sprite.height) // 2
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
    canvas = vertical_gradient(ICON_SIZE, (29, 117, 118), (194, 240, 232))
    add_glow(canvas, (236, 232), 230, (177, 238, 231), 154)
    add_glow(canvas, (780, 236), 228, (255, 227, 179), 128)
    add_glow(canvas, (276, 784), 244, (171, 212, 246), 118)
    add_glow(canvas, (676, 624), 236, (255, 219, 138), 108)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((86, 86, 938, 938), radius=258, fill=(249, 252, 251, 46), outline=(255, 255, 255, 34), width=4)
    draw.rounded_rectangle((118, 118, 906, 906), radius=238, outline=(240, 248, 247, 28), width=3)

    add_shadow(canvas, (400, 434, 790, 818), alpha=102)
    draw_coin(draw, (596, 586), 144)
    add_glow(canvas, (596, 586), 186, (255, 218, 135), 118)

    paste_peeking_sprite(
        canvas,
        "tikki_excited_v2.png",
        (-92, 24, 382, 440),
        crop=(0.08, 0.0, 0.72, 0.67),
    )
    paste_peeking_sprite(
        canvas,
        "mei_excited_v2.png",
        (636, 12, 1112, 436),
        crop=(0.18, 0.0, 0.95, 0.67),
    )
    paste_peeking_sprite(
        canvas,
        "manchas_excited_v2.png",
        (-80, 566, 404, 1044),
        crop=(0.08, 0.0, 0.76, 0.69),
    )

    draw.rounded_rectangle((420, 430, 776, 742), radius=156, outline=(255, 255, 255, 34), width=3)
    draw_yarn_ball(draw, (720, 742), 52, (96, 179, 191))
    add_glow(canvas, (720, 742), 84, (173, 236, 227), 96)
    return canvas


def create_app_icon_dark() -> Image.Image:
    canvas = vertical_gradient(ICON_SIZE, (13, 32, 39), (42, 79, 89))
    add_glow(canvas, (238, 236), 218, (77, 160, 167), 102)
    add_glow(canvas, (786, 228), 212, (227, 181, 102), 86)
    add_glow(canvas, (274, 790), 220, (88, 138, 166), 88)
    add_glow(canvas, (618, 594), 210, (241, 188, 104), 86)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((90, 90, 934, 934), radius=256, fill=(245, 250, 248, 18), outline=(236, 246, 245, 34), width=4)
    draw.rounded_rectangle((120, 120, 904, 904), radius=238, outline=(236, 246, 245, 22), width=3)

    add_shadow(canvas, (404, 438, 790, 818), alpha=116)
    draw_coin(draw, (598, 588), 144)
    add_glow(canvas, (598, 588), 174, (255, 214, 125), 92)

    paste_peeking_sprite(
        canvas,
        "tikki_excited_v2.png",
        (-92, 28, 384, 444),
        crop=(0.08, 0.0, 0.72, 0.67),
    )
    paste_peeking_sprite(
        canvas,
        "mei_excited_v2.png",
        (636, 16, 1110, 438),
        crop=(0.18, 0.0, 0.95, 0.67),
    )
    paste_peeking_sprite(
        canvas,
        "manchas_excited_v2.png",
        (-82, 568, 404, 1046),
        crop=(0.08, 0.0, 0.76, 0.69),
    )

    draw.rounded_rectangle((420, 432, 778, 744), radius=156, outline=(255, 255, 255, 26), width=3)
    draw_yarn_ball(draw, (724, 744), 52, (95, 164, 177))
    add_glow(canvas, (724, 744), 80, (95, 164, 177), 74)
    return canvas


def create_app_icon_tinted() -> Image.Image:
    canvas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (37, 66, 74, 255))
    add_glow(canvas, (512, 300), 282, (84, 156, 162), 96)
    add_glow(canvas, (612, 604), 218, (255, 205, 122), 62)
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle((112, 112, 912, 912), radius=240, outline=(255, 255, 255, 36), width=5)
    draw.rounded_rectangle((144, 144, 880, 880), radius=220, outline=(255, 255, 255, 20), width=3)
    draw.ellipse((424, 412, 776, 764), fill=(244, 233, 214, 255))
    draw.ellipse((470, 458, 730, 718), outline=(37, 66, 74, 255), width=18)
    draw.line((600, 516, 600, 660), fill=(37, 66, 74, 255), width=18)
    draw.line((534, 588, 666, 588), fill=(37, 66, 74, 255), width=18)

    paste_peeking_sprite(
        canvas,
        "tikki_excited_v2.png",
        (-98, 34, 380, 430),
        crop=(0.08, 0.0, 0.72, 0.67),
        tint=(244, 233, 214),
    )
    paste_peeking_sprite(
        canvas,
        "mei_excited_v2.png",
        (634, 22, 1108, 426),
        crop=(0.18, 0.0, 0.95, 0.67),
        tint=(244, 233, 214),
    )
    paste_peeking_sprite(
        canvas,
        "manchas_excited_v2.png",
        (-84, 570, 400, 1038),
        crop=(0.08, 0.0, 0.76, 0.69),
        tint=(244, 233, 214),
    )

    draw_yarn_ball(draw, (738, 744), 44, (244, 233, 214))
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

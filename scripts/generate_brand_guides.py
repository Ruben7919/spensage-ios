#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BRAND_ROOT = ROOT / "SpendSage" / "Resources" / "Brand" / "v2"
CHAR_ROOT = BRAND_ROOT / "characters"
GUIDE_ROOT = BRAND_ROOT / "guides"

SIZE = (1536, 1024)

PALETTE = {
    "canvas_top": (234, 245, 244),
    "canvas_bottom": (249, 239, 225),
    "teal": (27, 113, 113),
    "mint": (127, 205, 194),
    "glow": (170, 235, 226),
    "ink": (22, 42, 47),
    "muted": (87, 110, 114),
    "surface": (248, 251, 251),
    "line": (192, 219, 216),
    "gold": (255, 206, 90),
    "warm": (255, 234, 196),
    "danger": (229, 120, 106),
}


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def gradient_background(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    base = Image.new("RGBA", size)
    draw = ImageDraw.Draw(base)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(lerp(top[i], bottom[i], t) for i in range(3)) + (255,)
        draw.line((0, y, width, y), fill=color)
    return base


def add_radial_glow(canvas: Image.Image, center: tuple[int, int], radius: int, color: tuple[int, int, int], alpha: int) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color + (alpha,))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=radius // 2))
    canvas.alpha_composite(overlay)


def rounded_panel(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    outline: tuple[int, int, int, int],
    radius: int = 36,
    shadow_alpha: int = 30,
) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    x0, y0, x1, y1 = box
    shadow_draw.rounded_rectangle((x0 + 8, y0 + 18, x1 + 8, y1 + 18), radius=radius, fill=(13, 34, 36, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=18))
    canvas.alpha_composite(shadow)
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=2)
    canvas.alpha_composite(overlay)


def draw_chip(draw: ImageDraw.ImageDraw, xy: tuple[int, int], size: tuple[int, int], fill: tuple[int, int, int], outline: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    x, y = xy
    w, h = size
    draw.rounded_rectangle((x, y, x + w, y + h), radius=h // 2, fill=fill + (255,), outline=outline + (255,), width=2)
    draw.ellipse((x + 14, y + 11, x + 36, y + 33), fill=accent + (255,))
    draw.rounded_rectangle((x + 48, y + 13, x + w - 18, y + 21), radius=4, fill=(255, 255, 255, 220))
    draw.rounded_rectangle((x + 48, y + 25, x + w - 42, y + 33), radius=4, fill=(222, 236, 236, 255))


def draw_metric_card(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], accent: tuple[int, int, int], warm: bool = False) -> None:
    x0, y0, x1, y1 = box
    fill = (255, 250, 242, 246) if warm else (247, 251, 251, 246)
    outline = (214, 227, 224, 255)
    draw.rounded_rectangle(box, radius=28, fill=fill, outline=outline, width=2)
    draw.ellipse((x0 + 20, y0 + 18, x0 + 62, y0 + 60), fill=accent + (255,))
    draw.rounded_rectangle((x0 + 78, y0 + 22, x1 - 22, y0 + 34), radius=4, fill=(240, 245, 245, 255))
    draw.rounded_rectangle((x0 + 78, y0 + 42, x1 - 74, y0 + 54), radius=4, fill=(219, 234, 232, 255))
    draw.rounded_rectangle((x0 + 24, y1 - 64, x1 - 24, y1 - 22), radius=18, fill=(237, 246, 244, 255))


def add_sparkles(canvas: Image.Image, points: Iterable[tuple[int, int]], color: tuple[int, int, int]) -> None:
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for x, y in points:
        draw.line((x - 10, y, x + 10, y), fill=color + (180,), width=3)
        draw.line((x, y - 10, x, y + 10), fill=color + (180,), width=3)
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(255, 255, 255, 220))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=1))
    canvas.alpha_composite(overlay)


def paste_character(
    canvas: Image.Image,
    filename: str,
    box: tuple[int, int, int, int],
    shadow_alpha: int = 70,
) -> None:
    sprite = Image.open(CHAR_ROOT / filename).convert("RGBA")
    x0, y0, x1, y1 = box
    target_w = x1 - x0
    target_h = y1 - y0
    sprite.thumbnail((target_w, target_h), Image.LANCZOS)

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    center_x = x0 + target_w // 2
    shadow_draw.ellipse((center_x - 160, y1 - 48, center_x + 160, y1 + 18), fill=(30, 42, 45, shadow_alpha))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=20))
    canvas.alpha_composite(shadow)

    dest_x = x0 + (target_w - sprite.width) // 2
    dest_y = y0 + (target_h - sprite.height)
    canvas.alpha_composite(sprite, (dest_x, dest_y))


def profile_scene() -> Image.Image:
    canvas = gradient_background(SIZE, PALETTE["canvas_top"], (255, 243, 228))
    add_radial_glow(canvas, (1130, 380), 280, PALETTE["glow"], 135)
    add_radial_glow(canvas, (310, 330), 220, (198, 231, 228), 120)

    rounded_panel(canvas, (120, 150, 830, 870), (250, 253, 252, 242), (212, 230, 226, 255), radius=44)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((190, 220, 760, 460), radius=38, fill=(237, 246, 244, 255), outline=(205, 224, 220, 255), width=2)
    draw.ellipse((236, 266, 360, 390), fill=PALETTE["mint"] + (255,))
    draw.rounded_rectangle((390, 280, 680, 302), radius=8, fill=(230, 238, 238, 255))
    draw.rounded_rectangle((390, 326, 610, 346), radius=8, fill=(214, 227, 227, 255))
    draw.rounded_rectangle((390, 364, 560, 382), radius=8, fill=(214, 227, 227, 255))

    draw_metric_card(draw, (190, 510, 455, 700), PALETTE["teal"])
    draw_metric_card(draw, (495, 510, 760, 700), PALETTE["gold"], warm=True)
    draw_chip(draw, (190, 744), (248, 50), (247, 251, 251), PALETTE["line"], PALETTE["teal"])
    draw_chip(draw, (454, 744), (220, 50), (255, 248, 239), PALETTE["line"], PALETTE["gold"])

    draw.rounded_rectangle((890, 168, 1378, 860), radius=58, fill=(255, 251, 245, 115))
    add_radial_glow(canvas, (1170, 690), 220, (255, 215, 126), 115)
    paste_character(canvas, "mei_proud_v2.png", (878, 180, 1410, 900))
    add_sparkles(canvas, [(1080, 180), (1320, 220), (940, 720), (1280, 760)], PALETTE["gold"])
    return canvas


def help_scene() -> Image.Image:
    canvas = gradient_background(SIZE, (236, 246, 245), (255, 245, 236))
    add_radial_glow(canvas, (280, 320), 260, (162, 227, 219), 120)
    add_radial_glow(canvas, (1180, 300), 260, (255, 219, 143), 130)
    draw = ImageDraw.Draw(canvas)

    for index, top in enumerate((170, 342, 514)):
        offset = index * 26
        rounded_panel(
            canvas,
            (130 + offset, top, 760 + offset, top + 136),
            (250, 253, 252, 246),
            (211, 229, 225, 255),
            radius=36,
        )
        draw.ellipse((174 + offset, top + 34, 226 + offset, top + 86), fill=PALETTE["mint"] + (255,))
        draw.rounded_rectangle((254 + offset, top + 42, 626 + offset, top + 58), radius=4, fill=(223, 235, 235, 255))
        draw.rounded_rectangle((254 + offset, top + 72, 526 + offset, top + 88), radius=4, fill=(239, 244, 244, 255))
        draw.rounded_rectangle((642 + offset, top + 44, 706 + offset, top + 86), radius=18, fill=(237, 246, 244, 255))

    rounded_panel(canvas, (180, 704, 640, 826), (255, 248, 240, 246), (222, 228, 218, 255), radius=34)
    draw.ellipse((216, 742, 252, 778), fill=PALETTE["gold"] + (255,))
    draw.rounded_rectangle((278, 744, 584, 760), radius=4, fill=(228, 233, 233, 255))
    draw.rounded_rectangle((278, 774, 468, 790), radius=4, fill=(212, 227, 227, 255))
    draw.rounded_rectangle((530, 734, 602, 796), radius=24, fill=(237, 246, 244, 255))

    draw.rounded_rectangle((850, 180, 1382, 860), radius=58, fill=(255, 251, 247, 115))
    paste_character(canvas, "mei_neutral_v2.png", (886, 190, 1400, 900))
    bubble = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    bubble_draw = ImageDraw.Draw(bubble)
    bubble_draw.rounded_rectangle((1000, 168, 1278, 300), radius=34, fill=(251, 253, 252, 240), outline=(210, 228, 224, 255), width=2)
    bubble_draw.polygon([(1044, 298), (1080, 332), (1106, 292)], fill=(251, 253, 252, 240), outline=(210, 228, 224, 255))
    bubble_draw.ellipse((1060, 216, 1092, 248), fill=PALETTE["teal"] + (255,))
    bubble_draw.ellipse((1116, 216, 1148, 248), fill=PALETTE["mint"] + (255,))
    bubble_draw.ellipse((1172, 216, 1204, 248), fill=PALETTE["gold"] + (255,))
    bubble = bubble.filter(ImageFilter.GaussianBlur(radius=0.3))
    canvas.alpha_composite(bubble)
    add_sparkles(canvas, [(1204, 180), (1320, 300), (932, 660), (1202, 738)], PALETTE["gold"])
    return canvas


def rules_scene() -> Image.Image:
    canvas = gradient_background(SIZE, (233, 245, 245), (247, 241, 232))
    add_radial_glow(canvas, (360, 280), 280, (155, 228, 223), 130)
    add_radial_glow(canvas, (1100, 360), 230, (255, 220, 156), 120)
    draw = ImageDraw.Draw(canvas)

    rounded_panel(canvas, (120, 160, 860, 860), (246, 251, 251, 238), (205, 225, 222, 255), radius=48)
    draw.rounded_rectangle((188, 226, 792, 784), radius=42, fill=(229, 241, 239, 255), outline=(196, 219, 216, 255), width=2)

    chip_specs = [
        (228, 274, 214, 48, PALETTE["teal"]),
        (474, 274, 250, 48, PALETTE["gold"]),
        (228, 354, 282, 48, PALETTE["mint"]),
        (542, 354, 198, 48, PALETTE["teal"]),
        (228, 434, 234, 48, PALETTE["gold"]),
        (492, 434, 248, 48, PALETTE["mint"]),
    ]
    for x, y, w, h, accent in chip_specs:
        draw_chip(draw, (x, y), (w, h), (248, 251, 251), PALETTE["line"], accent)

    draw.line((334, 514, 334, 626), fill=(115, 188, 179, 255), width=6)
    draw.line((626, 514, 626, 626), fill=(115, 188, 179, 255), width=6)
    draw.line((334, 626, 626, 626), fill=(115, 188, 179, 255), width=6)
    for center in [(334, 514), (626, 514), (334, 626), (626, 626)]:
        x, y = center
        draw.ellipse((x - 16, y - 16, x + 16, y + 16), fill=PALETTE["gold"] + (255,))

    draw_metric_card(draw, (214, 658, 460, 784), PALETTE["teal"])
    draw_metric_card(draw, (500, 658, 746, 784), PALETTE["mint"])

    draw.rounded_rectangle((890, 176, 1388, 858), radius=58, fill=(255, 250, 244, 118))
    paste_character(canvas, "mei_thinking_v2.png", (900, 190, 1404, 902))
    add_sparkles(canvas, [(1022, 180), (1226, 222), (1360, 654), (952, 740)], PALETTE["gold"])
    return canvas


def advanced_scene() -> Image.Image:
    canvas = gradient_background(SIZE, (232, 243, 244), (240, 235, 229))
    add_radial_glow(canvas, (1170, 320), 260, (163, 214, 210), 120)
    add_radial_glow(canvas, (300, 330), 220, (255, 214, 142), 105)
    draw = ImageDraw.Draw(canvas)

    rounded_panel(canvas, (118, 152, 842, 872), (244, 250, 250, 238), (203, 221, 219, 255), radius=50)
    module_boxes = [
        (188, 230, 470, 470),
        (504, 230, 786, 470),
        (188, 516, 470, 756),
        (504, 516, 786, 756),
    ]
    accents = [PALETTE["teal"], PALETTE["gold"], PALETTE["mint"], PALETTE["danger"]]
    for box, accent in zip(module_boxes, accents):
        draw_metric_card(draw, box, accent, warm=accent == PALETTE["gold"])
        x0, y0, x1, _ = box
        draw.rounded_rectangle((x0 + 22, y0 + 92, x1 - 22, y0 + 132), radius=18, fill=(238, 246, 245, 255))
        draw.rounded_rectangle((x0 + 22, y0 + 146, x1 - 94, y0 + 162), radius=4, fill=(215, 229, 228, 255))

    draw.rounded_rectangle((894, 172, 1398, 860), radius=58, fill=(248, 250, 246, 114))
    paste_character(canvas, "manchas_thinking_v2.png", (904, 190, 1412, 904))

    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    overlay_draw.rounded_rectangle((1028, 156, 1288, 298), radius=34, fill=(252, 252, 248, 232), outline=(208, 220, 217, 255), width=2)
    overlay_draw.rounded_rectangle((1062, 196, 1248, 214), radius=5, fill=(226, 233, 233, 255))
    overlay_draw.rounded_rectangle((1062, 232, 1188, 248), radius=5, fill=(213, 226, 226, 255))
    overlay_draw.rounded_rectangle((1062, 266, 1218, 282), radius=5, fill=(213, 226, 226, 255))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=0.3))
    canvas.alpha_composite(overlay)

    add_sparkles(canvas, [(1048, 182), (1326, 236), (940, 704), (1308, 758)], PALETTE["gold"])
    return canvas


def main() -> None:
    GUIDE_ROOT.mkdir(parents=True, exist_ok=True)
    outputs = {
        "guide_21_profile_identity_ludo_v2.png": profile_scene(),
        "guide_22_help_center_ludo_v2.png": help_scene(),
        "guide_23_rules_automation_ludo_v2.png": rules_scene(),
        "guide_24_advanced_tools_manchas_v2.png": advanced_scene(),
    }

    for name, image in outputs.items():
        image.save(GUIDE_ROOT / name)
        print(f"generated {GUIDE_ROOT / name}")


if __name__ == "__main__":
    main()
